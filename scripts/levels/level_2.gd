extends Node2D

func _ready() -> void:
	GameManager.add_quest("enemy_kill", 8, "Defeat the frogs")
	$Portal.close()
