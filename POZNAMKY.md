# Návod: útok zabíja žaby (krok po kroku)

Cieľ: hráč útokom (Q) zabije žabu; po zabití sa pripočíta do „kill" questu
(`GameManager.notify_enemy_killed()` už existuje a `level_2.gd` pridáva quest
`enemy_kill`).

Princíp: hráč dostane **útočný hitbox** (Area2D). Aby sa hitbox aj jeho kolízia
**preklápali podľa toho, kam hráč pozerá**, dáme ho pod **Pivot node** (Node2D)
a ten len preklopíme (`scale.x = -1`). Všetko pod pivotom sa preklopí s ním.

---

## A) Útočný hitbox na hráčovi (Pivot node)

V `scenes/player/player.tscn`:

1. Na uzol **Player** pridaj `Node2D` → premenuj na **AttackPivot**, pozícia `(0, 0)`.
2. Pod `AttackPivot` pridaj `Area2D` → premenuj na **Hitbox**.
3. Pod `Hitbox` pridaj `CollisionShape2D`:
   - Shape: `RectangleShape2D`, veľkosť napr. `24 x 24`.
   - Position: posuň **doprava pred hráča**, napr. `x = 20, y = 0`
     (to je dosah meča, keď hráč pozerá doprava).
4. Klikni na **Hitbox** a v Inšpektore nastav:
   - **Monitoring = On**, **Monitorable = Off**
   - **Collision → Layer**: vypni úplne (žiadna vrstva).
   - **Collision → Mask**: zapni iba vrstvu, na ktorej sú nepriatelia
     (žaba je na **vrstve 2** → zaškrtni políčko 2).

> Tip: položku otestuj tak, že v editore vidíš modrý obdĺžnik pred hráčom.

---

## B) Preklápanie pivotu podľa smeru (player.gd)

Pridaj odkazy hore k ostatným `@onready`:
```gdscript
@onready var attack_pivot = $AttackPivot
@onready var attack_hitbox = $AttackPivot/Hitbox
```

V `_update_visuals()` tam, kde sa nastavuje `anim.flip_h`, preklop aj pivot:
```gdscript
func _update_visuals():
	if velocity.x != 0:
		var facing_left = velocity.x < 0
		anim.flip_h = facing_left
		attack_pivot.scale.x = -1 if facing_left else 1
	...
```
Keď pozeráš doľava, `scale.x = -1` preklopí hitbox (x=20 sa stane x=-20) –
kolízia ide automaticky s ním.

---

## C) Útok spôsobí zásah (player.gd)

Uprav `attack()` tak, aby po rozbehnutí švihu skontroloval, čo je v hitboxe:
```gdscript
func attack():
	is_attacking = true
	if velocity.x != 0:
		anim.play("run_attack")
		_play_sword_swipe(1)
	else:
		anim.play("attack")
		_play_sword_swipe(2)

	# počkaj, kým je meč v strede švihu, a zasiahni
	await get_tree().create_timer(0.15).timeout
	_deal_damage()

	await anim.animation_finished
	is_attacking = false

func _deal_damage():
	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("die"):
			body.die()
```

---

## D) Žabe pridaj smrť (frog.gd)

Pridaj príznak a do `_ready()` zaradenie do skupiny `enemy`:
```gdscript
var is_dead := false

func _ready():
	add_to_group("enemy")
	start_position = global_position
	_update_flip()
	if anim:
		anim.play("frog_move")
```

Na začiatok `_physics_process()` daj poistku (mŕtva žaba nech nič nerobí):
```gdscript
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	...
```

Pridaj funkciu `die()`:
```gdscript
func die():
	if is_dead:
		return
	is_dead = true
	GameManager.notify_enemy_killed()
	# (voliteľne: tu spusti animáciu smrti a await pred zmiznutím)
	queue_free()
```

---

## E) Daj žaby do levelu 2

1. Otvor `scenes/levels/level_2.tscn`.
2. Pretiahni `scenes/enemies/frog.tscn` do scény (alebo Instantiate Child Scene).
3. Polož aspoň **3 žaby** na zem (quest je `enemy_kill`, target 3).
4. Každej podľa potreby nastav `patrol_distance` v Inšpektore.

---

## F) Kontrola prepojenia (collision vrstvy / skupiny)

- Žaba: `collision_layer = 2` (už má), v `_ready()` `add_to_group("enemy")`.
- Hráčov Hitbox: Layer = žiadna, Mask = 2 (vidí žaby).
- Hráč je v skupine `player`, žaba v skupine `enemy`.

Hotovo: Q → hitbox pred hráčom → ak je v ňom žaba, zavolá sa `die()` →
`notify_enemy_killed()` posunie kill quest. Po 3 zabitiach sa splní cieľ levelu.

> Pozn.: žaba zabije hráča dotykom (jej telo). Hitbox má dosah pred hráčom,
> takže útoč skôr, než sa k tebe žaba dostane.
