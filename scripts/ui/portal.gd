extends Area2D

## Znovupoužiteľný portál.
##
## Výstupný portál (napr. level 1):
##   start_open = false, opens_on_objective = true, next_level = "...level_2.tscn"
##   -> je skrytý, otvorí sa po splnení cieľa levelu (GameManager.objective_completed),
##      pridá quest "dôjdi do portálu" a po vstupe hráča prenesie do next_level.
##
## Vstupný portál (napr. level 2, kadiaľ hráč prišiel):
##   start_open = true, next_level = ""
##   -> je hneď viditeľný, nič neteleportuje; level si ho podľa potreby schová
##      (napr. animáciou hide_portal).

signal opened

@export_file("*.tscn") var next_level: String = ""
@export var start_open: bool = false            # viditeľný hneď (vstupný portál)
@export var opens_on_objective: bool = true     # otvorí sa po splnení cieľa levelu
@export var portal_quest_text: String = "Reach the portal"

var is_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if start_open:
		is_open = true
		visible = true
	else:
		visible = false
		if opens_on_objective:
			GameManager.objective_completed.connect(open)

func open() -> void:
	""" Otvorí (zviditeľní) portál a pridá quest na jeho dosiahnutie. """
	if is_open:
		return
	is_open = true
	visible = true
	if portal_quest_text != "":
		GameManager.add_quest("reach_portal", 1, portal_quest_text)
	opened.emit()

func close(duration: float = 2.0) -> void:
	""" Plynulo zatvorí portál: zmenší ho do stratena (rovnako ako animácia
	hide_portal v leveli 2). Použiteľné na vstupný portál, ktorým hráč prišiel
	a ktorý sa má za ním zavrieť. Kým je zatvorený, neteleportuje. """
	is_open = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.00001, 0.00001), duration)
	await tween.finished
	visible = false

func _on_body_entered(body: Node2D) -> void:
	if is_open and next_level != "" and body.is_in_group("player"):
		GameManager.reset_game()
		get_tree().change_scene_to_file(next_level)
