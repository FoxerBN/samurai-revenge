extends CharacterBody2D

@export var speed: float = 60.0
@export var patrol_distance: float = 100.0
@export var gravity: float = 980.0
@export var max_hp: int = 100               # plné zdravie žaby (1 hit hráča = 50)

const KNOCKBACK_FORCE := 240.0              # ako silno ju zásah odhodí dozadu
const KNOCKBACK_FRICTION := 600.0           # ako rýchlo odhod doznie
const HIT_STUN := 0.25                       # ako dlho je po zásahu omráčená (bez patrolu)

var hp: int                                  # aktuálne zdravie
var hit_stun_time: float = 0.0               # zostávajúci čas omráčenia po zásahu
var start_position: Vector2
var direction: int = 1
var is_dead := false

const HIT_DAMAGE := 20                        # koľko HP ubere hráčovi jeden dotyk so žabou

@onready var anim = $AnimatedSprite2D
@onready var hit_sfx = $HitSfx

func _ready():
	add_to_group("enemy")
	hp = max_hp
	start_position = global_position

	_update_flip()
	if anim:
		anim.play("frog_move")

func _physics_process(delta: float) -> void:
	# death check
	if is_dead:
		return

	# Gravitácia
	if not is_on_floor():
		velocity.y += gravity * delta

	# Počas omráčenia po zásahu: žiadne patrolovanie, len doznievajúci odhod.
	if hit_stun_time > 0.0:
		hit_stun_time -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_FRICTION * delta)
		move_and_slide()
		return

	# Po skončení omráčenia sa vráti k pohybu.
	if anim and anim.animation != "frog_move":
		anim.play("frog_move")

	# Patrolovanie
	var current_dist = global_position.x - start_position.x

	if abs(current_dist) > patrol_distance:
		direction = -1 if current_dist > 0 else 1
		_update_flip()

	velocity.x = direction * speed

	# Detekcia kolízie s hráčom
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("player"):
				# Nezabíja hneď: ubere HP, odhodí a omráči (rovnako ako útok
				# hráča na žabu cez take_damage). Smrť až keď hráčovi dôjde HP.
				if collider.has_method("take_damage"):
					collider.take_damage(HIT_DAMAGE, global_position)
				elif collider.has_method("die"):
					collider.die()

func _update_flip():
	if anim:
		anim.flip_h = direction > 0 # Upraviť podľa toho, ktorým smerom je sprite v základe

func take_damage(amount: int, source_position: Vector2) -> void:
	""" Uberie zdravie, odhodí žabu od útočníka a prehrá animáciu zásahu.
	Pri 0 zdraví zomrie. """
	if is_dead:
		return
	hp -= amount

	# Odhod smerom preč od hráča (ak stoja presne na sebe, odhoď proti patrolu).
	var knock_dir := signf(global_position.x - source_position.x)
	if knock_dir == 0.0:
		knock_dir = -direction
	velocity.x = knock_dir * KNOCKBACK_FORCE
	hit_stun_time = HIT_STUN

	if anim:
		anim.play("hit")
	if hit_sfx:
		hit_sfx.play()

	if hp <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	GameManager.notify_enemy_killed()
	# Počká na dohratie animácie zásahu (a zvuku), až potom žaba zmizne.
	if anim and anim.is_playing():
		await anim.animation_finished
	queue_free()
