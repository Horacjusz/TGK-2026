class_name GravityComponent
extends Node


@export var body: CharacterBody2D
@export var up_gravity: float = 500.0
@export var down_gravity: float = 1000.0

var is_falling: bool = false


func handle_gravity(delta: float) -> void:
	is_falling = body.velocity.y > 0 and not body.is_on_floor()
	
	if body.is_on_floor():
		return
	
	if is_falling:
		body.velocity.y += down_gravity * delta
	else:
		body.velocity.y += up_gravity * delta
	
	
