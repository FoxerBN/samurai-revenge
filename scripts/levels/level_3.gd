extends Node2D

const LEVEL_MUSIC := preload("res://assets/music/14 - Tales of Firelight Town.mp3")

## Level 3: po odkliknutí úvodného story textu (StoryDialog.finished)
## sa hráčovi ukáže nápoveda s úlohou.

func _ready() -> void:
	MusicManager.play_music(LEVEL_MUSIC, "res://assets/music/14 - Tales of Firelight Town.mp3")
	# Žaby sú aktívne hneď. Včela a odmena už blokujú portál, ale zobrazia sa
	# až po prvom rozhovore s Jawym.
	$StoryDialog.finished.connect(_on_story_finished)
	$Portal.close()
	GameManager.add_quest("enemy_kill", 2, "Defeat the frogs", "frog")
	GameManager.add_quest("enemy_kill", 1, "Defeat the dangerous bee", "bee", false)
	GameManager.add_quest("coins", 1, "Take the reward", "", false)

func _on_story_finished() -> void:
	$Hint.show_hint("Help random guy")
	
