extends Node2D


enum SlammerState {
	IDLE,
	SLAMMING,
	RETURNING,
}

@export var attack_speed := 1.2 # 1 attack takes 1.2 seconds.
@export var enable_damage := true
@export var local_slam_direction := Vector2.DOWN
@export var slam_loop = false
@export var blocked_velocity_threshold := 1.0

@onready var body: RigidBody2D = $Body
@onready var hit_box: HitBox = $Body/HitBox
@onready var body_collision_shape: CollisionShape2D = $Body/CollisionShape2D

var _state := SlammerState.IDLE
var _start_position := Vector2.ZERO
var _slam_direction := Vector2.DOWN
var _resolved_slam_distance := 0.0
var _slam_speed := 0.0
var _return_speed := 0.0


func _ready() -> void:
	_start_position = body.position
	_slam_direction = local_slam_direction.normalized()
	if _slam_direction.is_zero_approx():
		_slam_direction = Vector2.DOWN

	_resolved_slam_distance = _get_body_height()
	_slam_speed = _resolved_slam_distance / max(attack_speed / 3.0, 0.001)
	_return_speed = _slam_speed * 0.5

	body.gravity_scale = 0.0
	body.lock_rotation = true
	body.contact_monitor = true
	body.max_contacts_reported = max(body.max_contacts_reported, 4)
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)
	if slam_loop :
		slam()


func slam() -> void:
	_set_hit_box_active(enable_damage)

	_state = SlammerState.SLAMMING
	body.linear_velocity = _to_global_velocity(_slam_direction * _slam_speed)


func finish_slam() -> void:
	on_slam_finish()


func on_hit() -> void:
	_state = SlammerState.RETURNING
	body.linear_velocity = _to_global_velocity(-_slam_direction * _return_speed)
	_set_hit_box_active(false)


func on_slam_finish() -> void:
	_state = SlammerState.IDLE
	body.position = _start_position
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)

	if slam_loop:
		slam()


func _physics_process(_delta: float) -> void:
	match _state:
		SlammerState.SLAMMING:
			if _is_slam_blocked():
				on_hit()
			elif _get_extension() >= _resolved_slam_distance:
				body.position = _start_position + _slam_direction * _resolved_slam_distance
				on_hit()

		SlammerState.RETURNING:
			if _get_extension() <= 0.0:
				on_slam_finish()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		slam()


func _get_extension() -> float:
	return (body.position - _start_position).dot(_slam_direction)


func _to_global_velocity(local_velocity: Vector2) -> Vector2:
	return global_transform.basis_xform(local_velocity)


func _set_hit_box_active(active: bool) -> void:
	hit_box.visible = active
	hit_box.monitoring = active


func _is_slam_blocked() -> bool:
	if body.get_contact_count() > 0:
		return true

	var local_velocity := global_transform.basis_xform_inv(body.linear_velocity)
	return local_velocity.dot(_slam_direction) < blocked_velocity_threshold


func _get_body_height() -> float:
	if body_collision_shape and body_collision_shape.shape:
		var rect_shape := body_collision_shape.shape as RectangleShape2D
		if rect_shape:
			return abs(rect_shape.size.dot(_slam_direction.abs()))

		var capsule_shape := body_collision_shape.shape as CapsuleShape2D
		if capsule_shape:
			return capsule_shape.height

	return 30.0
