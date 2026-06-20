extends Area2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_player = $AudioStreamPlayer2D
@onready var collision = $CollisionShape2D

func _ready():
	# Uistíme sa, že minca sa točí (predpokladáme animáciu "default")
	if anim_sprite:
		anim_sprite.play("coin")

func _on_body_entered(body: Node2D) -> void:
	# Kontrola, či je to hráč (používame skupinu "player")
	if body.is_in_group("player"):
		collect()

func collect():
	# 1. Pripočítanie bodov cez náš globálny GameManager
	GameManager.coins += 1
	
	# 2. Vypnutie kolízie, aby minca nebola zobratá viackrát
	collision.set_deferred("disabled", true)
	
	# 3. Spustenie zvukového efektu
	if audio_player:
		audio_player.play()
	
	# 4. Spustenie animácie vyletenia a zmiznutia, ktorú si pripravil
	if anim_player:
		anim_player.play("pickup")
		# Počkáme, kým animácia dohrá, a až potom odstránime objekt
		await anim_player.animation_finished
	else:
		# Ak by náhodou AnimationPlayer chýbal, aspoň mincu schováme
		anim_sprite.visible = false
		await audio_player.finished
	
	queue_free()
