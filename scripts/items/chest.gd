extends StaticBody2D

@onready var anim = $AnimatedSprite2D
@onready var prompt = $Label
@onready var sfx = $AudioStreamPlayer2D

# Načítame scénu mince, ktorú "vyhodíme" z truhly
var coin_scene = preload("res://scenes/items/coin.tscn")

var is_opened = false
var player_in_range = false

func _ready():
	# Skryjeme nápis na začiatku
	if prompt:
		prompt.hide()
	
	# Pripojíme signály, ak už nie sú pripojené v editore
	var area = $InteractionArea
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if not is_opened and prompt:
			prompt.show()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt:
			prompt.hide()

# Túto funkciu zavolá hráč cez InteractionArea
func interact():
	if not is_opened:
		open_chest()

func open_chest():
	is_opened = true
	if prompt:
		prompt.hide()
	
	if sfx:
		sfx.play()
	
	if anim:
		anim.play("open") # Skontroluj, či sa animácia v AnimatedSprite2D volá "open"
	
	# Vyhodíme mincu
	spawn_coin()

func spawn_coin():
	var coin = coin_scene.instantiate()
	# Pridáme mincu do levelu (k rodičovi truhly), aby "vypadla" von
	get_parent().add_child(coin)
	
	# Nastavíme jej pozíciu kúsok pred truhlu (napr. 20 pixelov nižšie)
	coin.global_position = global_position + Vector2(30, 0)
	print("Truhla otvorená a minca spawnutá!")
