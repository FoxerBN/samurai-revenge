extends CanvasLayer

# --- ODKAZY A NASTAVENIA ---
@onready var container = $Control/VBoxContainer
var font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# --- ZÁKLADNÉ FUNKCIE ---

func _ready():
	GameManager.quest_updated.connect(_on_quest_updated)
	
	# Vyčistenie placeholderov a načítanie existujúcich questov
	for child in container.get_children():
		child.queue_free()
	
	for i in range(GameManager.active_quests.size()):
		_on_quest_updated(i)

# --- AKTUALIZÁCIA UI ---

func _on_quest_updated(index: int):
	""" Aktualizuje konkrétny riadok questu podľa indexu. """
	var quest = GameManager.active_quests[index]
	
	while container.get_child_count() <= index:
		_create_quest_row()
	
	var panel = container.get_child(index)
	var label = panel.get_node("HBox/Label")
	var checkbox = panel.get_node("HBox/CheckBox")

	# Zobrazíme sprístupnené, nedokončené questy. Čakajúce questy sú sivé,
	# ale progres sa im stále počíta až po aktivácii v GameManageri.
	panel.visible = quest.available and not quest.completed

	label.text = "%s: %d/%d" % [quest.description, quest.current, quest.target]
	checkbox.button_pressed = quest.completed
	
	# Farebná indikácia stavu
	var status_color = Color.GREEN if quest.completed else (Color.WHITE if quest.active else Color.GRAY)
	label.add_theme_color_override("font_color", status_color)

# --- DYNAMICKÉ VYTVÁRANIE PRVKOV ---

func _create_quest_row():
	""" Vytvorí nový grafický riadok pre quest (Panel + Label + Checkbox). """
	var panel = PanelContainer.new()
	_apply_panel_style(panel)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.name = "Label"
	_apply_label_style(label)
	
	var checkbox = CheckBox.new()
	checkbox.name = "CheckBox"
	checkbox.disabled = true
	
	hbox.add_child(label)
	hbox.add_child(checkbox)
	panel.add_child(hbox)
	container.add_child(panel)

func _apply_panel_style(panel: PanelContainer):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.22)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)

func _apply_label_style(label: Label):
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
