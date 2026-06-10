extends Node2D

const HIT_SOUND_PATH = "res://assets/sounds/slammer/hit.mp3"
const START_SOUND_PATH = "res://assets/sounds/slammer/start_click.mp3"


enum SlammerState {
	IDLE,
	SLAMMING,
	RETURNING,
}

@export var attack_speed = 1.0
@export var enable_damage := true
@export var slam_loop = true
@export_range(0.0, 1.0, 0.01) var downward_part := 0.2:
	set(value):
		downward_part = clampf(value, 0.0, 1.0)
		_clamp_timing_parts()
		_recalculate_motion()
@export_range(0.0, 1.0, 0.01) var upward_part := 0.5:
	set(value):
		upward_part = clampf(value, 0.0, 1.0)
		_clamp_timing_parts()
		_recalculate_motion()
		
@onready var body: RigidBody2D = $Body
@onready var hit_box: HitBox = $Body/HitBox
@onready var body_collision_shape: CollisionShape2D = $Body/CollisionShape2D

var local_slam_direction := Vector2.DOWN
var blocked_velocity_threshold := 1.0
var _state := SlammerState.IDLE
var _start_position := Vector2.ZERO
var _slam_direction := Vector2.DOWN
var _resolved_slam_distance := 0.0
var _slam_speed := 0.0
var _return_speed := 0.0
var _slam_started_at := 0.0
var _loop_timer: Timer = null


func _ready() -> void:
	_start_position = body.position
	_slam_direction = local_slam_direction.normalized()
	if _slam_direction.is_zero_approx():
		_slam_direction = Vector2.DOWN

	_resolved_slam_distance = _get_body_height()
	_clamp_timing_parts()
	_recalculate_motion()

	body.gravity_scale = 0.0
	body.lock_rotation = true
	body.contact_monitor = true
	body.max_contacts_reported = max(body.max_contacts_reported, 4)
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)
	_loop_timer = Timer.new()
	_loop_timer.one_shot = true
	_loop_timer.timeout.connect(slam)
	add_child(_loop_timer)
	if slam_loop :
		slam()


func slam() -> void:
	if _loop_timer != null:
		_loop_timer.stop()

	_slam_started_at = Time.get_ticks_msec() / 1000.0
	_set_hit_box_active(enable_damage)

	_state = SlammerState.SLAMMING
	body.linear_velocity = _to_global_velocity(_slam_direction * _slam_speed)
	
	Globals.audio.play_sound_at(
		self,
		START_SOUND_PATH,
		body.global_position
	)


func finish_slam() -> void:
	on_slam_finish()


func on_hit() -> void:
	_state = SlammerState.RETURNING
	body.linear_velocity = _to_global_velocity(-_slam_direction * _return_speed)
	_set_hit_box_active(false)
	Globals.audio.play_sound_at(
		self,
		HIT_SOUND_PATH,
		body.global_position
	)


func on_slam_finish() -> void:
	_state = SlammerState.IDLE
	body.position = _start_position
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)

	if slam_loop:
		_schedule_next_loop_slam()


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
	pass


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


func _recalculate_motion() -> void:
	if _resolved_slam_distance <= 0.0:
		return

	var downward_time: float = attack_speed * downward_part
	var upward_time: float = attack_speed * upward_part

	_slam_speed = _resolved_slam_distance / maxf(downward_time, 0.001)
	_return_speed = _resolved_slam_distance / maxf(upward_time, 0.001)


func _clamp_timing_parts() -> void:
	var total: float = downward_part + upward_part
	if total <= 1.0:
		return

	upward_part = maxf(1.0 - downward_part, 0.0)


func _schedule_next_loop_slam() -> void:
	var elapsed_since_slam_started: float = Time.get_ticks_msec() / 1000.0 - _slam_started_at
	var delay: float = maxf(attack_speed - elapsed_since_slam_started, 0.0)

	if delay <= 0.0:
		slam()
		return

	_loop_timer.start(delay)
