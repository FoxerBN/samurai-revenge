extends CharacterBody2D

# --- KONŠTANTY ---
const SPEED = 130.0
const SPRINT_SPEED = 185.0                   # rýchlosť pri držaní Shiftu
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DEAD_SPRITE_POSITION = Vector2(0, 8)
const DEAD_COLLISION_POSITION = Vector2(6, 17)
const DEAD_COLLISION_SIZE = Vector2(42, 10)

# Kamera
const MAP_CENTER = Vector2(576, 324)        # stred mapy (náhľad pred štartom)
const OVERVIEW_ZOOM = Vector2(0.7, 0.7)
const GAMEPLAY_ZOOM = Vector2(1.3, 1.3)
const SWORD_SWIPE_GAP = 0.25                 # rozostup dvoch švihov pri útoku na mieste

# --- PREMENNÉ ---
var is_attacking = false
var game_started = false
var is_dead = false
var is_sprinting = false                     # drží Shift a pohybuje sa

# Dvojskok (z lektvaru): kým beží časovač, vo vzduchu môžeš skočiť ešte raz.
var double_jump_time_left = 0.0              # koľko sekúnd je dvojskok ešte aktívny
var double_jump_used = false                 # už si dvojskok v tomto výskoku použil?

# --- ODKAZY NA UZLY ---
@onready var anim = $AnimatedSprite
@onready var aura = $AnimatedSprite2D            # vizuálna aura počas dvojskoku
@onready var camera = $Camera2D
@onready var body_collision = $CollisionShape2D
# Dva prehrávače, aby sa pri dvojseku zvuky neprerušovali (striedame ich).
@onready var sword_sfx = [$SwordSfx, $SwordSfx2]

# --- ZÁKLADNÉ FUNKCIE ---

func _ready():
	add_to_group("player")
	_setup_initial_camera()
	aura.play("aura")            # aura sa stále prehráva, len ju skrývame/zobrazujeme

	# Správanie na šikmých plochách (svahoch):
	floor_snap_length = 32.0           # drží postavu pri zemi pri schádzaní (nehrá sa "fall")
	floor_constant_speed = true        # rovnaká rýchlosť hore aj dole (žiadne zasekávanie)
	floor_stop_on_slope = true         # na svahu nestojíme a nekĺžeme sa dole
	floor_max_angle = deg_to_rad(55)   # aj strmší svah berie ako podlahu, nie ako stenu
	floor_block_on_wall = false        # nezasekne sa o hranu svahu/dlaždice pri stúpaní

func _physics_process(delta: float) -> void:
	if not game_started: return
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Odpočítavanie platnosti dvojskoku (lektvar trvá len pár sekúnd).
	if double_jump_time_left > 0.0:
		double_jump_time_left = max(0.0, double_jump_time_left - delta)

	# Aura je viditeľná presne počas platnosti dvojskoku.
	aura.visible = double_jump_time_left > 0.0
	if aura.visible:
		aura.flip_h = anim.flip_h            # aura sa otáča spolu s postavou

	if is_dead:
		move_and_slide()
		return
		
	_handle_input()
	move_and_slide()
	_update_visuals()

# --- LOGIKA VSTUPU A POHYBU ---

func _handle_input():
	# Po dopade na zem sa dvojskok znova nabije.
	if is_on_floor():
		double_jump_used = false

	# Skok: zo zeme normálne, vo vzduchu jeden dvojskok (ak je lektvar aktívny).
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif double_jump_time_left > 0.0 and not double_jump_used:
			velocity.y = JUMP_VELOCITY
			double_jump_used = true
		
	# Horizontálny pohyb (so sprintom na Shift)
	var direction = Input.get_axis("ui_left", "ui_right")
	is_sprinting = Input.is_action_pressed("sprint") and direction != 0
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED
	if direction:
		velocity.x = direction * current_speed
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
			anim.play("sprint" if is_sprinting else "run")
		else:
			anim.play("idle")

func attack():
	is_attacking = true
	# Útok na mieste = dva švihy (2 zvuky), útok počas behu = jeden švih (1 zvuk).
	if velocity.x != 0:
		anim.play("run_attack")
		_play_sword_swipe(1)
	else:
		anim.play("attack")
		_play_sword_swipe(2)
	await anim.animation_finished
	is_attacking = false

func _play_sword_swipe(times: int) -> void:
	""" Prehrá zvuk švihu mečom `times`-krát za sebou (len počas seknutia).
	Striedanie dvoch prehrávačov zaručí, že druhý švih neprehluší prvý. """
	for i in times:
		sword_sfx[i % sword_sfx.size()].play()
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

# --- POWER-UPY ---

func grant_double_jump(duration: float = 5.0) -> void:
	""" Zapne (alebo obnoví) dvojskok na `duration` sekúnd.
	Volá sa z lektvaru pri zobratí. """
	double_jump_time_left = duration

# --- MANAŽMENT HRY A KAMERY ---

func start_game():
	""" Spustí hru. Volá sa zo StoryDialog.finished.
	Kamera plynulo prejde zo stredu mapy na hráča a priblíži sa. """
	game_started = true
	if not camera: return

	# Cieľ presunu = miesto, kde kamera reálne dosadne pri sledovaní hráča
	# (orezané hernými limitmi). Tým, že tweenujeme priamo naň, na konci
	# nenastane žiadny myk doprava od orezania.
	var rest = _compute_follow_rest()

	var tween = create_tween().set_parallel(true)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", rest, 1.2)
	tween.tween_property(camera, "zoom", GAMEPLAY_ZOOM, 1.2)
	tween.set_parallel(false)
	tween.tween_callback(_attach_camera_to_player)

func _compute_follow_rest() -> Vector2:
	""" Dočasne prepne kameru do herného režimu, zistí orezaný stred pohľadu
	a vráti kameru späť na náhľad stredu mapy. """
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.zoom = GAMEPLAY_ZOOM
	_apply_gameplay_limits()
	camera.reset_smoothing()
	var rest = camera.get_screen_center_position()
	# Späť na náhľad: stred mapy, oddialené, bez limitov.
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.global_position = MAP_CENTER
	camera.zoom = OVERVIEW_ZOOM
	_clear_limits()
	camera.reset_smoothing()
	return rest

func _attach_camera_to_player():
	""" Po presune: kamera začne sledovať hráča (s limitmi a vyhladením). """
	if not camera: return
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.position_smoothing_enabled = true
	_apply_gameplay_limits()

func _setup_initial_camera():
	""" Pred štartom: kamera ukazuje stred mapy (oddialený náhľad).
	Smoothing je vypnutý, aby sa stred zobrazil okamžite aj počas pauzy. """
	if not camera: return
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.global_position = MAP_CENTER
	camera.zoom = OVERVIEW_ZOOM
	_clear_limits()

func _apply_gameplay_limits():
	camera.limit_left = 0
	camera.limit_top = -10000000
	camera.limit_right = 1152
	camera.limit_bottom = 700

func _clear_limits():
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
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
