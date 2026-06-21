extends CanvasLayer

## Znovupoužiteľný chat box pre rozhovory s postavami (NPC).
## Ukáže text po stranách, preklikáva sa medzerou / Enterom (ui_accept).
## Počas neho je hra pozastavená; po poslednej strane sa zavrie a uvoľní.
##
## Použitie:
##   var box = preload("res://scenes/ui/chat_box.tscn").instantiate()
##   get_tree().current_scene.add_child(box)
##   box.show_pages(["Strana 1", "Strana 2"])
## alebo v Inšpektore vyplň `pages` a box sa ukáže sám pri vložení do scény.

signal closed

## Voliteľný text priamo zo scény. Ak je prázdny, čaká na show_pages().
@export var pages: PackedStringArray = []

@onready var _label: Label = $Box/Margin/Text

var _active_pages: PackedStringArray = []
var _index: int = 0

func _ready() -> void:
	# Musí bežať aj keď je zvyšok hry pozastavený.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if not pages.is_empty():
		show_pages(pages)

func show_pages(p: PackedStringArray) -> void:
	""" Spustí rozhovor s danými stranami textu. """
	_active_pages = p
	_index = 0
	if _active_pages.is_empty():
		_close()
		return
	visible = true
	get_tree().paused = true
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

func _show_page(i: int) -> void:
	_label.text = _active_pages[i]

func _advance() -> void:
	_index += 1
	if _index >= _active_pages.size():
		_close()
	else:
		_show_page(_index)

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
