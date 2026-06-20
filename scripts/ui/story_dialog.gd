extends CanvasLayer

## Pixel-art dialógové okno.
## Zobrazuje postupne stránky textu (ovládanie, útržky príbehu).
## Počas zobrazenia je hra pozastavená (get_tree().paused = true).
## Medzerníkom / Enterom sa prepína na ďalšiu stránku.
## Po poslednej stránke vyšle signál `finished` a sám sa odstráni.

signal finished

## Jednotlivé stránky textu. Nastavuje sa per-level v scéne (Inšpektor),
## takže každý level môže mať vlastné intro. Podporuje BBCode (napr. [center]).
@export var pages: PackedStringArray = []

@onready var _frame: Control = $Center/Frame
@onready var _text: RichTextLabel = $Center/Frame/Inner/Margin/VBox/Text
@onready var _hint: Label = $Center/Frame/Inner/Margin/VBox/Hint

var _index: int = 0

func _ready() -> void:
	# Dialóg musí bežať, aj keď je zvyšok hry pozastavený.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_blink_hint()
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

# --- LOGIKA STRÁNOK ---

func _show_page(i: int) -> void:
	if pages.is_empty():
		_close()
		return
	_text.text = pages[i]
	# Posledná stránka spustí hru, ostatné len posunú ďalej.
	_hint.text = "▸ ZAČÍT  [MEZERNÍK]" if i >= pages.size() - 1 else "▸ DÁL  [MEZERNÍK]"
	# Krátky fade-in pre plynulý prechod medzi stránkami.
	_frame.modulate.a = 0.0
	create_tween().tween_property(_frame, "modulate:a", 1.0, 0.25)

func _advance() -> void:
	_index += 1
	if _index >= pages.size():
		_close()
	else:
		_show_page(_index)

func _close() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()

# --- EFEKTY ---

func _blink_hint() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_hint, "modulate:a", 0.25, 0.5)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.5)
