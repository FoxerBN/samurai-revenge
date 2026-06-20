extends CanvasLayer

## Pixel-art intro / story dialog.
## Shows pages of text (controls, story bits) one by one.
## The game is paused while it is visible (get_tree().paused = true).
## Advance with the button (mouse) or SPACE / Enter.
## After the last page it emits `finished` and frees itself.

signal finished

## Default content. Kept in the script so it cannot be lost when the scene is
## saved in the editor. Per-level it can be overridden via `pages`.
## Controls keys are padded into a column (PressStart2P is monospace).
const DEFAULT_PAGES: PackedStringArray = [
	"[center]CONTROLS[/center]

← →       Move
SPACE     Jump
Q         Attack
E         Action",
	"[center]You are Tove.

You wake in a land
you do not know.[/center]",
	"[center]No memories.
No answers.

Only the path ahead.[/center]",
]

## Optional per-level override (Inspector). If empty, DEFAULT_PAGES is used.
## Supports BBCode (e.g. [center]).
@export var pages: PackedStringArray = []

@onready var _frame: Control = $Center/Box/Frame
@onready var _text: RichTextLabel = $Center/Box/Frame/Inner/Margin/Text
@onready var _button: Button = $Center/Box/NextButton

var _active_pages: PackedStringArray = []
var _index: int = 0

func _ready() -> void:
	# The dialog must keep running while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_active_pages = pages if not pages.is_empty() else DEFAULT_PAGES
	_button.pressed.connect(_advance)
	get_tree().paused = true
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

# --- PAGE LOGIC ---

func _show_page(i: int) -> void:
	if _active_pages.is_empty():
		_close()
		return
	_text.text = _active_pages[i]
	# Last page starts the game, the others just go on.
	_button.text = "START" if i >= _active_pages.size() - 1 else "NEXT  ▶"
	# Short fade-in for a smooth transition between pages.
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
