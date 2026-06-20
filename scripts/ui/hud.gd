extends CanvasLayer

@onready var label = $Control/PanelContainer/HBoxContainer/Label

func _ready():
	# Pripojíme sa na signál z GameManageru
	GameManager.coins_changed.connect(_on_coins_changed)
	# Nastavíme počiatočnú hodnotu
	update_ui(GameManager.coins)

func _on_coins_changed(new_amount: int):
	update_ui(new_amount)

func update_ui(amount: int):
	if label:
		label.text = str(amount)
