class_name JumpComponent
extends Node


@export var body: CharacterBody2D
@export var jump_speed: float = -160.0

@onready var jump_buffer_timer: Timer = %JumpBufferTimer
@onready var coyote_timer: Timer = %CoyoteTimer

var is_going_up: bool = false
var is_jumping: bool = false
var last_frame_on_floor: bool = false


func _has_just_landed() -> bool:
	return body.is_on_floor() and not last_frame_on_floor and is_jumping


func _has_just_stepped_off_ledge() -> bool:
	return not body.is_on_floor() and last_frame_on_floor and not is_jumping


func _can_jump() -> bool:
	return body.is_on_floor() or not coyote_timer.is_stopped()


func handle_jump(wants_to_jump: bool, jump_released: bool) -> void:
	if _has_just_landed():
		is_jumping = false

	if wants_to_jump and _can_jump():
		_jump()
		
	_handle_coyote_time()
	_handle_jump_buffer(wants_to_jump)
	_handle_jump_released(jump_released)
		
	is_going_up = body.velocity.y < 0 and not body.is_on_floor()
	last_frame_on_floor = body.is_on_floor()


func _handle_coyote_time() -> void:
	if _has_just_stepped_off_ledge():
		coyote_timer.start()
		
	if not coyote_timer.is_stopped() and not is_jumping:
		body.velocity.y = 0


func _handle_jump_buffer(wants_to_jump) -> void:
	if wants_to_jump and not body.is_on_floor():
		jump_buffer_timer.start()
		
	if body.is_on_floor() and not jump_buffer_timer.is_stopped():
		_jump()


func _handle_jump_released(jump_released: bool) -> void:
	if jump_released and is_jumping:
		body.velocity.y /= 2


func _jump() -> void:
	body.velocity.y = jump_speed
	is_jumping = true
	jump_buffer_timer.stop()
	coyote_timer.stop()
