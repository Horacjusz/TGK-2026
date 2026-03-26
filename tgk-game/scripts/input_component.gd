class_name InputComponent
extends Node


var move_axis: float = 0.0
var jump_pressed: bool = false


func update() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
