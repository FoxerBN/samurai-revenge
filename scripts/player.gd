extends CharacterBody2D

# --- KONŠTANTY ---
const SPEED = 130.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DEAD_SPRITE_POSITION = Vector2(0, 8)
const DEAD_COLLISION_POSITION = Vector2(6, 17)
const DEAD_COLLISION_SIZE = Vector2(42, 10)

# Kamera
const MAP_CENTER = Vector2(576, 324)        # stred mapy (náhľad pred štartom)
const OVERVIEW_ZOOM = Vector2(0.7, 0.7)
const GAMEPLAY_ZOOM = Vector2(1.3, 1.3)
const CAMERA_INTRO_TIME = 1.2               # dĺžka presunu kamery stred -> hráč
const SWORD_SWIPE_GAP = 0.13                # rozostup dvoch švihov pri útoku

# --- PREMENNÉ ---
var is_attacking = false
var game_started = false
var is_dead = false
var _was_running = false                    # na prehratie zvuku behu len raz

# --- ODKAZY NA UZLY ---
@onready var anim = $AnimatedSprite
@onready var camera = $Camera2D
@onready var body_collision = $CollisionShape2D
@onready var sword_sfx = $SwordSfx

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
			_was_running = false
			anim.play("jump" if velocity.y < 0 else "fall")
		elif velocity.x != 0:
			# Zvuk behu prehráme len raz – pri začatí behu.
			if not _was_running:
				sword_sfx.play()
				_was_running = true
			anim.play("run")
		else:
			_was_running = false
			anim.play("idle")

func attack():
	is_attacking = true
	_play_sword_swipe(2)   # pri machnutí mečom dva švihy za sebou
	anim.play("run_attack" if velocity.x != 0 else "attack")
	await anim.animation_finished
	is_attacking = false

func _play_sword_swipe(times: int) -> void:
	""" Prehrá zvuk švihu mečom `times`-krát rýchlo za sebou. """
	for i in times:
		sword_sfx.play()
		if i < times - 1:
			await get_tree().create_timer(SWORD_SWIPE_GAP).timeout

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
	""" Spustí hru. Volá sa zo StoryDialog.finished. """
	game_started = true
	if not camera: return

	# Plynulý presun kamery zo stredu mapy na hráča + priblíženie.
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(camera, "global_position", global_position, CAMERA_INTRO_TIME)
	tween.tween_property(camera, "zoom", GAMEPLAY_ZOOM, CAMERA_INTRO_TIME)
	tween.set_parallel(false)
	tween.tween_callback(_attach_camera_to_player)

func _setup_initial_camera():
	""" Pred štartom: kamera ukazuje stred mapy (náhľad). """
	if not camera: return
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.global_position = MAP_CENTER
	camera.zoom = OVERVIEW_ZOOM
	# Bez limitov, nech sa dá ukázať stred mapy aj pri oddialení.
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000

func _attach_camera_to_player():
	""" Po presune kamera začne sledovať hráča a zapnú sa herné limity. """
	if not camera: return
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.position_smoothing_enabled = true
	camera.limit_left = 0
	camera.limit_top = -10000000
	camera.limit_right = 1152
	camera.limit_bottom = 700

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
