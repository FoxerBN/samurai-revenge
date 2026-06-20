extends CharacterBody2D

@export var speed: float = 60.0
@export var patrol_distance: float = 100.0
@export var gravity: float = 980.0

var start_position: Vector2
var direction: int = 1

@onready var anim = $AnimatedSprite2D

func _ready():
	start_position = global_position
	_update_flip()
	if anim:
		anim.play("frog_move")

func _physics_process(delta: float) -> void:
	# Gravitácia
	if not is_on_floor():
		velocity.y += gravity * delta
	
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
				if collider.has_method("die"):
					collider.die()

func _update_flip():
	if anim:
		anim.flip_h = direction > 0 # Upraviť podľa toho, ktorým smerom je sprite v základe
