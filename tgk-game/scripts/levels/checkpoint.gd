extends Node2D
class_name Checkpoint


@export var id: String
@export var direction: float = 1.0


func _ready() -> void:
	add_to_group("checkpoints")
