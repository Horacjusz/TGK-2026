class_name MovementComponent
extends Node

@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0
var direction: int = 1


func handle_movement(axis: float, delta: float) -> void:
		
	body.velocity.x = move_toward(body.velocity.x, axis * speed, acceleration)

	if axis != 0:
		model.scale.x = sign(axis)
		direction = sign(axis)
