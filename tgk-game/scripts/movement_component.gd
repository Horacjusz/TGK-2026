class_name MovementComponent
extends Node

@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0
var is_pushed: bool = false
var external_velocity: float = 0.0
var direction: int = 1


func handle_movement(axis: float, delta: float) -> void:
	# TODO: Check if this is really needed and how it behaves
	if is_pushed and (axis == 0 or sign(axis) != sign(external_velocity)):
		body.velocity.x = external_velocity
		
	body.velocity.x = move_toward(body.velocity.x, axis * speed, acceleration)

	if axis != 0:
		model.scale.x = sign(axis)
		direction = sign(axis)
