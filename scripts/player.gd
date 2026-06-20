extends CharacterBody2D

# --- KONŠTANTY ---
const SPEED = 130.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DEAD_SPRITE_POSITION = Vector2(0, 8)
const DEAD_COLLISION_POSITION = Vector2(6, 17)
const DEAD_COLLISION_SIZE = Vector2(42, 10)

# --- PREMENNÉ ---
var is_attacking = false
var game_started = false
var is_dead = false

# --- ODKAZY NA UZLY ---
@onready var anim = $AnimatedSprite
@onready var camera = $Camera2D
@onready var body_collision = $CollisionShape2D

# --- ZÁKLADNÉ FUNKCIE ---

func _ready():
	add_to_group("player")
	_setup_initial_camera()

func _physics_process(delta: float) -> void:
	if not game_started: return
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if is_dead:
		move_and_slide()
		return
		
	_handle_input()
	move_and_slide()
	_update_visuals()

# --- LOGIKA VSTUPU A POHYBU ---

func _handle_input():
	# Skok
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Horizontálny pohyb
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Útok
	if Input.is_action_just_pressed("ui_q") and not is_attacking:
		attack()
	
	# Interakcia (E)
	if Input.is_action_just_pressed("interact"):
		_handle_interaction()

# --- VIZUÁL A ANIMÁCIE ---

func _update_visuals():
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
		
	if not is_attacking:
		if not is_on_floor():
			anim.play("jump" if velocity.y < 0 else "fall")
		elif velocity.x != 0:
			anim.play("run")
		else:
			anim.play("idle")

func attack():
	is_attacking = true
	anim.play("run_attack" if velocity.x != 0 else "attack")
	await anim.animation_finished
	is_attacking = false

# --- INTERAKČNÝ SYSTÉM ---

func _handle_interaction():
	""" Hľadá interaktívne objekty v InteractionArea. """
	var interaction_area = find_child("InteractionArea", true, false)
	if interaction_area and interaction_area is Area2D:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("interact"):
				area.interact()
				return
			elif area.get_parent().has_method("interact"):
				area.get_parent().interact()
				return

# --- MANAŽMENT HRY A KAMERY ---

func start_game():
	""" Spustí hru a aktivuje kameru. Volá sa zo StoryDialog.finished. """
	game_started = true

	if camera:
		camera.top_level = false
		camera.position = Vector2.ZERO
		
		# Plynulý zoom pri štarte
		create_tween().tween_property(camera, "zoom", Vector2(1.3, 1.3), 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		camera.limit_left = 0
		camera.limit_right = 1152
		camera.limit_bottom = 700

func _setup_initial_camera():
	if camera:
		camera.top_level = true
		camera.position = Vector2(576, 324)
		camera.zoom = Vector2(0.7, 0.7)
		camera.limit_left = -10000000
		camera.limit_bottom = 10000000

func die():
	if is_dead: return
	is_dead = true
	
	# Po smrti hrac nema blokovat nepriatelov, ale stale musi kolidovat so zemou.
	collision_layer = 0
	collision_mask = 1
	var dead_shape = RectangleShape2D.new()
	dead_shape.size = DEAD_COLLISION_SIZE
	body_collision.shape = dead_shape
	body_collision.position = DEAD_COLLISION_POSITION
	
	velocity.x = 0
	anim.position = DEAD_SPRITE_POSITION
	anim.play("dead")
	
	await get_tree().create_timer(4.0).timeout
	
	GameManager.reset_game()
	get_tree().reload_current_scene()
