extends Node
class_name FlyComponent


@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0


func handle_movement(axis: float, delta: float) -> void:
		
	body.velocity.y = move_toward(body.velocity.y, axis * speed, acceleration)
