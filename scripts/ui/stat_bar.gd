extends Control

@onready var stamina_bar = $VBoxContainer/StaminaBar
@onready var hp_bar = $VBoxContainer/HPBar

func _ready() -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	player.hp_changed.connect(set_hp)
	player.stamina_changed.connect(set_stamina)
	set_hp(player.hp, player.MAX_HP)
	set_stamina(player.stamina, player.MAX_STAMINA)

func set_stamina(value: float, max_value: float) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = value

func set_hp(value: float, max_value: float) -> void:
	hp_bar.max_value = max_value
	hp_bar.value = value
