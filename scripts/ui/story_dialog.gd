extends CanvasLayer

## Pixel-art dialógové okno.
## Zobrazuje postupne stránky textu (ovládanie, útržky príbehu).
## Počas zobrazenia je hra pozastavená (get_tree().paused = true).
## Medzerníkom / Enterom sa prepína na ďalšiu stránku.
## Po poslednej stránke vyšle signál `finished` a sám sa odstráni.

signal finished

## Predvolený obsah (čeština). Drží sa priamo v skripte, aby sa nestratil pri
## ukladaní scény v editore. Pre konkrétny level sa dá prepísať cez `pages`.
const DEFAULT_PAGES: PackedStringArray = [
	"[center]OVLÁDÁNÍ

←  →     Pohyb
MEZERNÍK    Skok
Q       Útok
E       Akce[/center]",
	"[center]Jsi Tove.

Probouzíš se v zemi,
kterou neznáš.[/center]",
	"[center]Žádné vzpomínky.
Žádné odpovědi.

Jen cesta vpřed.[/center]",
]

## Voliteľné prepísanie stránok per-level (Inšpektor). Ak je prázdne,
## použije sa DEFAULT_PAGES. Podporuje BBCode (napr. [center]).
@export var pages: PackedStringArray = []

@onready var _frame: Control = $Center/Frame
@onready var _text: RichTextLabel = $Center/Frame/Inner/Margin/VBox/Text
@onready var _hint: Label = $Center/Frame/Inner/Margin/VBox/Hint

var _active_pages: PackedStringArray = []
var _index: int = 0

func _ready() -> void:
	# Dialóg musí bežať, aj keď je zvyšok hry pozastavený.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_active_pages = pages if not pages.is_empty() else DEFAULT_PAGES
	get_tree().paused = true
	_blink_hint()
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

# --- LOGIKA STRÁNOK ---

func _show_page(i: int) -> void:
	if _active_pages.is_empty():
		_close()
		return
	_text.text = _active_pages[i]
	# Posledná stránka spustí hru, ostatné len posunú ďalej.
	_hint.text = "▶ ZAČÍT  [MEZERNÍK]" if i >= _active_pages.size() - 1 else "▶ DÁL  [MEZERNÍK]"
	# Krátky fade-in pre plynulý prechod medzi stránkami.
	_frame.modulate.a = 0.0
	create_tween().tween_property(_frame, "modulate:a", 1.0, 0.25)

func _advance() -> void:
	_index += 1
	if _index >= _active_pages.size():
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
