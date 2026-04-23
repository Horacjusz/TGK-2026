class_name MovementComponent
extends Node

@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0
@export var deceleration := 2.0
@export var use_deceleration: bool = false
var direction: int = 1


func handle_movement(axis: float, delta: float) -> void:
	if axis == 0 and use_deceleration:
		body.velocity.x = move_toward(body.velocity.x, 0, deceleration)
	else:
		body.velocity.x = move_toward(body.velocity.x, axis * speed, acceleration)

	if axis != 0:
		model.scale.x = sign(axis)
		direction = sign(axis)
