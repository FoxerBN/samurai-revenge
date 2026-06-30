extends StaticBody2D

@export_file("*.tscn") var next_scene := "res://scenes/levels/level_1.tscn"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.global_position = get_viewport_rect().size / 2.0
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame = 0
	animated_sprite.play("logo")


func _on_animation_finished() -> void:
	get_tree().change_scene_to_file(next_scene)
