extends Node2D

## Level 3: po odkliknutí úvodného story textu (StoryDialog.finished)
## sa hráčovi ukáže nápoveda s úlohou.

func _ready() -> void:
	$StoryDialog.finished.connect(_on_story_finished)
	$Portal.close()

func _on_story_finished() -> void:
	$Hint.show_hint("Help random guy")
	
