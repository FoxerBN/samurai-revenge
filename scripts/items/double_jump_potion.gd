extends Area2D

# Ako dlho po zobratí má hráč k dispozícii dvojskok (v sekundách).
const DOUBLE_JUMP_DURATION = 7.0

@onready var anim_sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_player = $AudioStreamPlayer2D
@onready var collision = $CollisionShape2D

func _ready() -> void:
	if anim_sprite:
		anim_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	# Reagujeme len na hráča (skupina "player").
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	# 1. Udelíme hráčovi dvojskok na pár sekúnd.
	if player.has_method("grant_double_jump"):
		player.grant_double_jump(DOUBLE_JUMP_DURATION)

	# 2. Vypneme kolíziu, aby sa lektvar nezobral viackrát.
	collision.set_deferred("disabled", true)

	# 3. Zvuk zobratia.
	if audio_player:
		audio_player.play()

	# 4. Animácia vyletenia a zmiznutia, potom odstránenie objektu.
	if anim_player:
		anim_player.play("pickup")
		await anim_player.animation_finished
	else:
		anim_sprite.visible = false
		await audio_player.finished

	queue_free()
