extends CanvasLayer

## HUD počítadlo. Podľa typu hlavného questu zobrazí buď ikonu mince (zber mincí),
## alebo ikonu nepriateľa (zabíjanie) a počet.

@onready var label = $Control/PanelContainer/HBoxContainer/Label
@onready var coin_icon = $Control/PanelContainer/HBoxContainer/IconContainer/CoinIcon
@onready var enemy_icon = $Control/PanelContainer/HBoxContainer/IconContainer/EnemyIcon

func _ready():
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.quest_updated.connect(_on_quest_updated)
	_refresh()

func _on_coins_changed(_amount: int):
	_refresh()

func _on_quest_updated(_index: int):
	_refresh()

func _refresh():
	var quest = _primary_quest()
	if quest == null:
		label.text = "0"
		coin_icon.visible = true
		enemy_icon.visible = false
		return

	label.text = str(quest.current)
	var is_kill = quest.type == "enemy_kill"
	coin_icon.visible = not is_kill
	enemy_icon.visible = is_kill

func _primary_quest():
	""" Vráti práve aktívny hlavný quest levelu (mince/zabíjanie), inak null. """
	for q in GameManager.active_quests:
		if (q.type == "coins" or q.type == "enemy_kill") and q.active and not q.completed:
			return q
	return null
