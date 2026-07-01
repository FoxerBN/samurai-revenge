extends Node2D

const LEVEL_MUSIC := preload("res://assets/music/14 - Tales of Firelight Town.mp3")

func _ready() -> void:
	MusicManager.play_music(LEVEL_MUSIC, "res://assets/music/14 - Tales of Firelight Town.mp3")
	GameManager.add_quest("enemy_kill", 8, "Defeat the frogs")
	$Portal.close()
