extends CharacterBody2D

@export var speed: float = 35.0
@export var chase_speed: float = 75.0
@export var patrol_distance: float = 90.0
@export var territory_range: float = 160.0
@export var gravity: float = 0.0
@export var max_hp: int = 100

const HIT_DAMAGE := 20
const KNOCKBACK_FORCE := 180.0
const KNOCKBACK_FRICTION := 500.0
const HIT_STUN := 0.25
const ATTACK_COOLDOWN := 0.8
const START_RETURN_DISTANCE := 4.0

var hp: int
var start_position: Vector2
var direction: int = 1
var hit_stun_time: float = 0.0
var attack_cooldown_left: float = 0.0
var is_dead := false
var is_returning_to_start := false

@onready var anim = $AnimatedSprite2D
@onready var alert_label = $Label

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	start_position = global_position
	alert_label.visible = false
	anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	anim.play("fly")
	_update_flip()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.y += gravity * delta
	attack_cooldown_left = max(0.0, attack_cooldown_left - delta)

	if hit_stun_time > 0.0:
		hit_stun_time -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_FRICTION * delta)
		velocity.y = move_toward(velocity.y, 0.0, KNOCKBACK_FRICTION * delta)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var player_in_territory := player != null and player.global_position.distance_to(start_position) <= territory_range

	if player_in_territory:
		_chase_player(player)
	else:
		if alert_label.visible or global_position.distance_to(start_position) > patrol_distance:
			is_returning_to_start = true
		_return_or_patrol()

	_update_animation()
	_update_flip()
	move_and_slide()
	_check_player_collision()

func _chase_player(player: Node2D) -> void:
	alert_label.visible = true
	is_returning_to_start = false
	var chase_direction := global_position.direction_to(player.global_position)
	velocity = chase_direction * chase_speed

func _return_or_patrol() -> void:
	alert_label.visible = false

	if is_returning_to_start and global_position.distance_to(start_position) > START_RETURN_DISTANCE:
		var return_direction := global_position.direction_to(start_position)
		velocity = return_direction * speed
		return

	if is_returning_to_start:
		global_position = start_position
		is_returning_to_start = false

	velocity.y = 0.0

	var current_dist := global_position.x - start_position.x
	if abs(current_dist) > patrol_distance:
		direction = -1 if current_dist > 0.0 else 1

	velocity.x = direction * speed

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if not collider.is_in_group("player"):
			continue

		if attack_cooldown_left <= 0.0:
			attack_cooldown_left = ATTACK_COOLDOWN
			if anim:
				anim.play("attack")
			if collider.has_method("take_damage"):
				collider.take_damage(HIT_DAMAGE, global_position)
			elif collider.has_method("die"):
				collider.die()
		return

func _update_animation() -> void:
	if not anim:
		return
	if anim.animation == "attack":
		return
	if anim.animation == "hit" and hit_stun_time > 0.0:
		return
	anim.play("fly")

func _update_flip() -> void:
	if not anim or velocity.x == 0.0:
		return
	anim.flip_h = velocity.x > 0.0

func take_damage(amount: int, source_position: Vector2) -> void:
	if is_dead:
		return

	hp -= amount

	var knock_dir := global_position.direction_to(source_position) * -1.0
	if knock_dir == Vector2.ZERO:
		knock_dir = Vector2(-direction, 0.0)

	velocity = knock_dir.normalized() * KNOCKBACK_FORCE
	hit_stun_time = HIT_STUN

	if anim:
		anim.play("hit")

	if hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameManager.notify_enemy_killed("bee")
	queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dead:
		return
	if anim.animation == "attack":
		anim.play("fly")
