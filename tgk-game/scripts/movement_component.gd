class_name MovementComponent
extends Node

@export var body: CharacterBody2D
@export var model: Node2D
@export var speed := 50.0
@export var acceleration := 10.0
@export var jump_speed := -160.0
@export var up_gravity := 500
@export var down_gravity := 1000
var is_pushed: bool = false
var external_velocity: float = 0.0
var direction: int = 1

func move_horizontal(delta: float, axis: float) -> void:
	if is_pushed:
		if axis == 0 or sign(axis) != sign(external_velocity):
			# Player stands still or moves against push — clanker controls movement
			body.velocity.x = external_velocity
		else:
			# Player moves in same direction as push — boost speed
			body.velocity.x = external_velocity*2 + speed*axis
	else:
		if axis == 0:
			body.velocity.x = move_toward(body.velocity.x, 0, acceleration)
		else:
			body.velocity.x = move_toward(body.velocity.x, axis * speed, acceleration)

	if sign(axis) > 0:
		model.scale.x = 1
		direction = 1
	elif sign(axis) < 0:
		model.scale.x = -1
		direction = -1

func apply_gravity(delta: float) -> void:
	if body.is_on_floor():
		return

	if body.velocity.y > 0:
		body.velocity.y += down_gravity * delta
	else:
		body.velocity.y += up_gravity * delta

func jump() -> void:
	body.velocity.y = jump_speed

func move_and_slide() -> void:
	body.move_and_slide()
