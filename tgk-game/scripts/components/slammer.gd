extends Node2D

const HIT_SOUND_PATH = "res://assets/sounds/slammer/hit.mp3"
const START_SOUND_PATH = "res://assets/sounds/slammer/start_click.mp3"
const FRONT_PROBE_SKIN := 1.0
const FRONT_PROBE_BACKSTEP := 0.5


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
@export var initial_delay := 0.0

@onready var body: RigidBody2D = $Body
@onready var hit_box: HitBox = $Body/HitBox
@onready var body_collision_shape: CollisionShape2D = $Body/CollisionShape2D
@onready var trigger_areas: Array[Area2D] = _find_trigger_areas()

var local_slam_direction := Vector2.DOWN
var _state := SlammerState.IDLE
var _start_position := Vector2.ZERO
var _slam_direction := Vector2.DOWN
var _resolved_slam_distance := 0.0
var _slam_speed := 0.0
var _return_speed := 0.0
var _cooldown_timer: Timer = null
var _is_loop_armed := false
var _has_pending_loop_slam := false
var can_slam := true

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
	_disconnect_hit_box_auto_damage()
	_set_hit_box_active(false)
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_slam_cooldown_timeout)
	add_child(_cooldown_timer)

	if not trigger_areas.is_empty():
		for trigger_area in trigger_areas:
			trigger_area.body_entered.connect(_on_trigger_body_entered)
			trigger_area.area_entered.connect(_on_trigger_area_entered)
			body.add_collision_exception_with(trigger_area)
		call_deferred("_check_initial_trigger_overlap")
	
	if slam_loop and trigger_areas.is_empty():
		_schedule_initial_loop_slam()


func slam() -> void:
	if _state != SlammerState.IDLE:
		return
	if not can_slam:
		return

	can_slam = false
	_is_loop_armed = true
	_set_hit_box_active(false)

	if _cooldown_timer != null:
		_cooldown_timer.start(maxf(attack_speed, 0.001))

	_state = SlammerState.SLAMMING
	body.linear_velocity = Vector2.ZERO
	
	Globals.audio.play_sound_at(
		self,
		START_SOUND_PATH,
		body.global_position
	)


func finish_slam() -> void:
	on_slam_finish()


func on_hit() -> void:
	_damage_using_hitbox()
	_start_return()


func on_slam_finish() -> void:
	_state = SlammerState.IDLE
	body.position = _start_position
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)

	if slam_loop:
		_schedule_next_loop_slam()


func _physics_process(delta: float) -> void:
	match _state:
		SlammerState.SLAMMING:
			var motion: Vector2 = _get_slam_motion(delta)
			if _is_world_blocking_slam(motion):
				print(self, " world blocked")
				on_hit()
				return

			_move_body_along_slam(motion)
			if _push_overlapping_character_bodies(motion):
				on_hit()
			elif _get_extension() >= _resolved_slam_distance:
				body.position = _start_position + _slam_direction * _resolved_slam_distance
				_start_return()

		SlammerState.RETURNING:
			_move_body_along_return(delta)
			if _get_extension() <= 0.0:
				on_slam_finish()

	_process_pending_loop_slam()


func _process(_delta: float) -> void:
	pass


func _on_trigger_body_entered(_body: Node2D) -> void:
	if _is_ignored_trigger_body(_body):
		return

	_try_start_from_trigger()


func _on_trigger_area_entered(_area: Area2D) -> void:
	if _is_ignored_trigger_area(_area):
		return

	_try_start_from_trigger()


func _try_start_from_trigger() -> void:
	if _state != SlammerState.IDLE:
		return

	if slam_loop and _is_loop_armed:
		return
	if not can_slam:
		return
	
	slam()


func _check_initial_trigger_overlap() -> void:
	await get_tree().physics_frame

	if trigger_areas.is_empty():
		return

	for trigger_area in trigger_areas:
		if (
			_has_valid_trigger_body_overlap(trigger_area)
			or _has_non_trigger_area_overlap(trigger_area)
		):
			_try_start_from_trigger()
			return


func _get_extension() -> float:
	return (body.position - _start_position).dot(_slam_direction)


func _get_slam_motion(delta: float) -> Vector2:
	var remaining_distance: float = maxf(_resolved_slam_distance - _get_extension(), 0.0)
	var local_motion: Vector2 = _slam_direction * minf(_slam_speed * delta, remaining_distance)
	return _to_global_velocity(local_motion)


func _move_body_along_slam(motion: Vector2) -> void:
	body.global_position += motion


func _is_world_blocking_slam(motion: Vector2) -> bool:
	if motion.is_zero_approx():
		return false

	return _is_front_blocked(motion)


func _is_front_blocked(motion: Vector2) -> bool:
	var motion_direction := motion.normalized()
	if motion_direction.is_zero_approx():
		return false

	var space_state := body.get_world_2d().direct_space_state
	var exclude: Array[RID] = [body.get_rid()]

	for local_offset in _get_front_probe_offsets():
		var start: Vector2 = body.to_global(local_offset) - motion_direction * FRONT_PROBE_BACKSTEP
		var end: Vector2 = start + motion + motion_direction * FRONT_PROBE_SKIN
		var query := PhysicsRayQueryParameters2D.create(
			start,
			end,
			body.collision_mask,
			exclude
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.hit_from_inside = true

		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			continue

		var collider := hit.get("collider") as Node
		if _is_front_blocking_collider(collider):
			return true

	return false


func _get_front_probe_offsets() -> Array[Vector2]:
	var shape_position := body_collision_shape.position
	var slam_direction := _slam_direction.normalized()
	var side_direction := Vector2(-slam_direction.y, slam_direction.x)
	var half_depth := 15.0
	var half_width := 4.0

	if body_collision_shape.shape is RectangleShape2D:
		var rect_shape := body_collision_shape.shape as RectangleShape2D
		half_depth = abs(rect_shape.size.dot(slam_direction.abs())) * 0.5
		half_width = abs(rect_shape.size.dot(side_direction.abs())) * 0.5
	elif body_collision_shape.shape is CapsuleShape2D:
		var capsule_shape := body_collision_shape.shape as CapsuleShape2D
		half_depth = capsule_shape.height * 0.5
		half_width = capsule_shape.radius

	var front_center := shape_position + slam_direction * half_depth
	var side_probe_offset: float = maxf(half_width - FRONT_PROBE_SKIN, 0.0)

	return [
		front_center,
		front_center + side_direction * side_probe_offset,
		front_center - side_direction * side_probe_offset,
	]


func _is_front_blocking_collider(collider: Node) -> bool:
	if collider == null:
		return false
	if collider is CharacterBody2D:
		return false

	return true


func _start_return() -> void:
	_state = SlammerState.RETURNING
	body.linear_velocity = Vector2.ZERO
	_set_hit_box_active(false)
	
	Globals.audio.play_sound_at(
		self,
		HIT_SOUND_PATH,
		body.global_position
	)


func _move_body_along_return(delta: float) -> void:
	var extension: float = maxf(
		_get_extension() - _return_speed * delta,
		0.0
	)
	body.position = _start_position + _slam_direction * extension


func _to_global_velocity(local_velocity: Vector2) -> Vector2:
	return global_transform.basis_xform(local_velocity)


func _set_hit_box_active(active: bool) -> void:
	hit_box.visible = active
	hit_box.monitoring = active


func _get_body_height() -> float:
	if body_collision_shape and body_collision_shape.shape:
		var rect_shape := body_collision_shape.shape as RectangleShape2D
		if rect_shape:
			return abs(rect_shape.size.dot(_slam_direction.abs()))

		var capsule_shape := body_collision_shape.shape as CapsuleShape2D
		if capsule_shape:
			return capsule_shape.height

	return 30.0


func _get_body_half_depth() -> float:
	return _get_body_height() * 0.5


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
	if not trigger_areas.is_empty() and not _is_loop_armed:
		return

	_has_pending_loop_slam = true


func _schedule_initial_loop_slam() -> void:
	_has_pending_loop_slam = true

	if initial_delay <= 0.0:
		return

	can_slam = false
	if _cooldown_timer != null:
		_cooldown_timer.start(initial_delay)


func _process_pending_loop_slam() -> void:
	if not _has_pending_loop_slam:
		return
	if _state != SlammerState.IDLE:
		return
	if not can_slam:
		return

	_has_pending_loop_slam = false
	slam()


func _on_slam_cooldown_timeout() -> void:
	can_slam = true


func _find_trigger_areas() -> Array[Area2D]:
	var result: Array[Area2D] = []
	_collect_trigger_areas(self, result)
	return result


func _collect_trigger_areas(node: Node, result: Array[Area2D]) -> void:
	for child in node.get_children():
		if child == hit_box:
			continue
		if child is Area2D and _is_trigger_area(child):
			result.append(child)

		_collect_trigger_areas(child, result)


func _is_trigger_area(area: Area2D) -> bool:
	return area.name.to_lower().contains("trigger")


func _has_valid_trigger_body_overlap(trigger_area: Area2D) -> bool:
	for overlapping_body in trigger_area.get_overlapping_bodies():
		if not _is_ignored_trigger_body(overlapping_body):
			return true

	return false


func _has_non_trigger_area_overlap(trigger_area: Area2D) -> bool:
	for area in trigger_area.get_overlapping_areas():
		if not _is_ignored_trigger_area(area):
			return true

	return false


func _is_ignored_trigger_body(overlapping_body: Node2D) -> bool:
	return _belongs_to_slammer(overlapping_body)


func _is_ignored_trigger_area(area: Area2D) -> bool:
	if area in trigger_areas:
		return true
	if _is_trigger_area(area):
		return true

	return _belongs_to_slammer(area)


func _belongs_to_slammer(node: Node) -> bool:
	if node == null:
		return false

	var current_node := node

	while current_node != null:
		if current_node != self and current_node.get_script() == get_script():
			return true

		current_node = current_node.get_parent()

	return false


func _disconnect_hit_box_auto_damage() -> void:
	var auto_damage_callable := Callable(hit_box, "_on_area_entered")
	if hit_box.area_entered.is_connected(auto_damage_callable):
		hit_box.area_entered.disconnect(auto_damage_callable)


func _push_overlapping_character_bodies(motion: Vector2) -> bool:
	if motion.is_zero_approx():
		return false

	for character_body in _get_overlapping_character_bodies():
		if not _is_node_in_front_of_slammer(character_body):
			continue

		var previous_position: Vector2 = character_body.global_position
		character_body.add_collision_exception_with(body)
		var collision := character_body.move_and_collide(motion)
		character_body.remove_collision_exception_with(body)
		var actual_motion: Vector2 = character_body.global_position - previous_position

		if collision != null or actual_motion.distance_squared_to(motion) > 0.01:
			_damage_character_body(character_body)
			return true

	return false


func _get_overlapping_character_bodies() -> Array[CharacterBody2D]:
	var result: Array[CharacterBody2D] = []

	for colliding_body in body.get_colliding_bodies():
		if colliding_body is CharacterBody2D and colliding_body not in result:
			result.append(colliding_body)

	return result


func _is_node_in_front_of_slammer(node: Node2D) -> bool:
	var local_position := body.to_local(node.global_position)
	var front_center := body_collision_shape.position + _slam_direction.normalized() * _get_body_half_depth()
	var distance_from_front := (local_position - front_center).dot(_slam_direction.normalized())
	return distance_from_front >= -FRONT_PROBE_SKIN


func _damage_using_hitbox() -> void:
	if not enable_damage:
		return

	_set_hit_box_active(true)
	print("Starting damaging")

	print(hit_box.get_overlapping_areas())

	for area in hit_box.get_overlapping_areas():
		if area is HurtBox:
			_damage_hurt_box(area as HurtBox)

	print(_get_overlapping_character_bodies())

	for character_body in _get_overlapping_character_bodies():
		_damage_character_body(character_body)

	_set_hit_box_active(false)


func _damage_character_body(character_body: CharacterBody2D) -> void:
	for child in character_body.get_children():
		var hurt_box := _find_hurt_box(child)
		if hurt_box != null:
			_damage_hurt_box(hurt_box)


func _find_hurt_box(node: Node) -> HurtBox:
	if node is HurtBox:
		return node

	for child in node.get_children():
		var hurt_box := _find_hurt_box(child)
		if hurt_box != null:
			return hurt_box

	return null


func _damage_hurt_box(hurt_box: HurtBox) -> void:
	hurt_box.take_damage(hit_box.damage)
