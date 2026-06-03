class_name LevelTransition
extends Area2D


@export_file("*.tscn") var next_level_path: String
@export var target_checkpoint_id: int = 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if next_level_path:
			GlobalSignalBus.level_transition_requested.emit(
				next_level_path,
				target_checkpoint_id
			)
		else:
			push_warning("Door triggered, but next_level_path is empty!")
