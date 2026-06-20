extends CanvasLayer

@onready var _root: Control = $Control
@onready var _vbox = $Control/CenterContainer/PanelContainer/VBoxContainer
@onready var _story_label: Label = $Control/CenterContainer/PanelContainer/VBoxContainer/StoryLabel

func _ready():
	add_to_group("controls_hud")
	visible = false

func show_controls(duration: float = 7.0):
	for child in _vbox.get_children():
		child.visible = child != _story_label
	visible = true
	_root.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.4)
	tween.tween_interval(duration)
	tween.tween_property(_root, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_show_story)

func _show_story():
	for child in _vbox.get_children():
		child.visible = child == _story_label
	_root.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.5)
	tween.tween_interval(10.0)
	tween.tween_property(_root, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): visible = false)
