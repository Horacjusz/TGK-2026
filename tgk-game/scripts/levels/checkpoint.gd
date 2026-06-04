extends Area2D
class_name Checkpoint


signal checkpoint_entered(checkpoint: Checkpoint)

@export var id: int
@export var direction: float = 1.0


func _ready() -> void:
	add_to_group("checkpoints")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.is_dead:
			return
		checkpoint_entered.emit(self)
