extends Node2D

func _ready() -> void:
	GameManager.add_quest("coins", 5, "Collect coins")
