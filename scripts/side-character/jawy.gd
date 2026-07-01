extends CharacterBody2D

## Vedľajšia postava (NPC), s ktorou sa dá pokecať.
## Keď je hráč v dosahu (InteractionArea), ukáže sa nápis "E Talk".
## Po stlačení E (hráč to volá cez svoju InteractionArea -> interact())
## sa otvorí chat box s textom tejto postavy.

const CHAT_BOX := preload("res://scenes/ui/chat_box.tscn")
const COIN := preload("res://scenes/items/coin.tscn")

## Text rozhovoru — každý prvok poľa je jedna strana. Vyplň v Inšpektore.
@export var dialogue: PackedStringArray

@onready var prompt: Label = $Label
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Questy sprístupníme až po prvom rozhovore; mincu (odmenu) dáme len raz.
var quests_given := false
var coin_dropped := false

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
	# Keď sa dokončí ktorýkoľvek quest, dozvieme sa to a vieme zareagovať.
	GameManager.quest_completed.connect(_on_quest_completed)

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
	# Po prvom rozhovore sa sprístupní úloha s včelou a následná odmena.
	if not quests_given:
		quests_given = true
		GameManager.set_quest_available("enemy_kill", true, "bee")
		GameManager.set_quest_available("coins", true)

	if not anim:
		return
	# Dohrá celé idle-end (ruka dole) a až potom sa vráti do normálneho idle.
	anim.play("idle-end")
	await anim.animation_finished
	anim.play("idle")

## Reaguje na dokončenie questu s včelou. Potom Jawy vyhodí odmenu vedľa seba.
func _on_quest_completed(quest) -> void:
	if coin_dropped:
		return
	if quest.type == "enemy_kill" and quest.enemy_type == "bee":
		coin_dropped = true
		_spawn_reward_coin()

func _spawn_reward_coin() -> void:
	var coin := COIN.instantiate()
	get_parent().add_child(coin)
	# Kúsok vedľa strangera, aby "vypadla" von.
	coin.global_position = global_position + Vector2(30, 0)
