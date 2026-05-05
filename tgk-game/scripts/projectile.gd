class_name Projectile
extends Area2D


func initialize(
	initial_position: Vector2,
	initial_rotation := 0.0, 
	_data := {}
):
	global_position = initial_position
	global_rotation = initial_rotation
