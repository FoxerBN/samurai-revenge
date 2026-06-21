extends CharacterBody2D

## Vedľajšia postava (NPC), s ktorou sa dá pokecať.
## Keď je hráč v dosahu (InteractionArea), ukáže sa nápis "E Talk".
## Po stlačení E (hráč to volá cez svoju InteractionArea -> interact())
## sa otvorí chat box s textom tejto postavy.

const CHAT_BOX := preload("res://scenes/ui/chat_box.tscn")

## Text rozhovoru — každý prvok poľa je jedna strana. Vyplň v Inšpektore.
@export var dialogue: PackedStringArray

@onready var prompt: Label = $Label
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("npc")
	if prompt:
		prompt.hide()
	if anim:
		anim.play("idle")
	# Dosah na zobrazenie "E Talk": detegujeme telo hráča.
	var area: Area2D = $InteractionArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if prompt:
		prompt.show()
	if anim:
		anim.play("idle-start")

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if prompt:
		prompt.hide()
	if anim:
		anim.play("idle")

## Zavolá hráč pri stlačení E, keď je v dosahu.
func interact() -> void:
	var box := CHAT_BOX.instantiate()
	get_tree().current_scene.add_child(box)
	# Keď dohovorí (zavrie sa box), dá ruku dole -> prehrá "idle-end".
	box.closed.connect(_on_chat_closed)
	box.show_pages(dialogue)

func _on_chat_closed() -> void:
	if not anim:
		return
	# Dohrá celé idle-end (ruka dole) a až potom sa vráti do normálneho idle.
	anim.play("idle-end")
	await anim.animation_finished
	anim.play("idle")
