extends Node2D

## Level 3: po odkliknutí úvodného story textu (StoryDialog.finished)
## sa hráčovi ukáže nápoveda s úlohou.

func _ready() -> void:
	# Questy v tomto leveli pridáva NPC (jawy) po dokončení rozhovoru.
	$StoryDialog.finished.connect(_on_story_finished)
	$Portal.close()
	GameManager.add_quest("enemy_kill", 2, "Defeat the frogs")

func _on_story_finished() -> void:
	$Hint.show_hint("Help random guy")
	
