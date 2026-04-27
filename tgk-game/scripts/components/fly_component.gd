extends Node
class_name FlyComponent


@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0
@export var deceleration := 2.0
@export var use_deceleration: bool = false

func handle_movement(axis: float, delta: float) -> void:
	if axis == 0 and use_deceleration:
		body.velocity.y = move_toward(body.velocity.y, 0, deceleration)
	else:
		body.velocity.y = move_toward(body.velocity.y, axis * speed, acceleration)
