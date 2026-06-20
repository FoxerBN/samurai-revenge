extends CanvasLayer

## Znovupoužiteľná nápoveda.
## Biely pixel text s čiernym outline + šípka vpravo, jemne pulzuje a po
## `visible_time` sekundách zmizne.
## Spustí sa automaticky pri splnení cieľa levelu (GameManager.objective_completed),
## alebo manuálne zavolaním show_hint("text").
## Použitie: vlož scénu do levelu a v Inšpektore nastav `message`.

@export var message: String = "Portal opened"
@export var auto_on_objective: bool = true
@export var visible_time: float = 3.0

@onready var _label: Label = $Label

var _pulse: Tween

func _ready() -> void:
	_label.modulate.a = 0.0
	if auto_on_objective:
		GameManager.objective_completed.connect(func(): show_hint(message))

func show_hint(text: String) -> void:
	_label.text = text + "  ▶"

	# Objavenie
	var appear := create_tween()
	appear.tween_property(_label, "modulate:a", 1.0, 0.3)
	await appear.finished

	# Jemný pulz počas zobrazenia
	if _pulse:
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_label, "modulate:a", 0.55, 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

	await get_tree().create_timer(visible_time).timeout

	# Zmiznutie
	if _pulse:
		_pulse.kill()
	create_tween().tween_property(_label, "modulate:a", 0.0, 0.4)
