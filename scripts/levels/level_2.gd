extends Node2D

func _ready() -> void:
	# Level 2 je "kill" typ – poraz 3 žaby (namiesto zbierania mincí).
	GameManager.add_quest("enemy_kill", 3, "Defeat the frogs")
	# Portál, ktorým hráč prišiel, sa po štarte zmrští a zmizne.
	$Portal/AnimationPlayer.play("hide_portal")
