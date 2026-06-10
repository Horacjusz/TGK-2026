extends Node2D

const HIT_SOUND_PATH = "res://assets/sounds/slammer/hit.mp3"
const START_SOUND_PATH = "res://assets/sounds/slammer/start_click.mp3"
const FRONT_PROBE_SKIN := 1.0
const FRONT_PROBE_BACKSTEP := 0.5
const SLAMMER_BODY_GROUP := "slammer_bodies"
const RIDER_TOP_TOLERANCE := 2.0


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
@onready var head_hit_box: HitBox = $Body/HitBoxes/Head
@onready var tail_hit_box: HitBox = $Body/HitBoxes/Tail
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
	body.add_to_group(SLAMMER_BODY_GROUP)
	_ignore_existing_light_clankers()
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
	_disconnect_hit_box_auto_damage(head_hit_box)
	_disconnect_hit_box_auto_damage(tail_hit_box)
	_set_hit_boxes_active(false)
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
	_set_hit_boxes_active(false)

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
	_damage_using_hitbox(head_hit_box)
	_start_return()


func on_slam_finish() -> void:
	_state = SlammerState.IDLE
	body.position = _start_position
	body.linear_velocity = Vector2.ZERO
	_set_hit_boxes_active(false)

	if slam_loop:
		_schedule_next_loop_slam()


func _physics_process(delta: float) -> void:
	match _state:
		SlammerState.SLAMMING:
			var motion: Vector2 = _get_slam_motion(delta)
			if _is_world_blocking_slam(motion):
				on_hit()
				return

			_move_body_along_slam(motion)
			_carry_horizontal_riders(motion)
			if _push_overlapping_character_bodies(motion):
				on_hit()
			elif _get_extension() >= _resolved_slam_distance:
				body.position = _start_position + _slam_direction * _resolved_slam_distance
				_start_return()

		SlammerState.RETURNING:
			_move_body_along_return(delta)
			_damage_using_hitbox(tail_hit_box, false, false)
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
	if _is_light_clanker(collider):
		return false
	if collider is CharacterBody2D:
		return false

	return true


func _start_return() -> void:
	_state = SlammerState.RETURNING
	body.linear_velocity = Vector2.ZERO
	_set_hit_boxes_active(false)
	_set_hit_box_active(tail_hit_box, true)
	
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
	var previous_global_position := body.global_position
	body.position = _start_position + _slam_direction * extension
	_carry_horizontal_riders(body.global_position - previous_global_position)


func _to_global_velocity(local_velocity: Vector2) -> Vector2:
	return global_transform.basis_xform(local_velocity)


func _set_hit_boxes_active(active: bool) -> void:
	_set_hit_box_active(head_hit_box, active)
	_set_hit_box_active(tail_hit_box, active)


func _set_hit_box_active(source_hit_box: HitBox, active: bool) -> void:
	source_hit_box.visible = active
	source_hit_box.monitoring = active


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
		if child == head_hit_box or child == tail_hit_box:
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
	if _is_light_clanker(overlapping_body):
		return true

	return _belongs_to_slammer(overlapping_body)


func _is_ignored_trigger_area(area: Area2D) -> bool:
	if area in trigger_areas:
		return true
	if _is_trigger_area(area):
		return true
	if _is_light_clanker(area):
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


func _disconnect_hit_box_auto_damage(source_hit_box: HitBox) -> void:
	var auto_damage_callable := Callable(source_hit_box, "_on_area_entered")
	if source_hit_box.area_entered.is_connected(auto_damage_callable):
		source_hit_box.area_entered.disconnect(auto_damage_callable)


func _push_overlapping_character_bodies(motion: Vector2) -> bool:
	if motion.is_zero_approx():
		return false

	for character_body in _get_overlapping_character_bodies():
		if _is_light_clanker(character_body):
			continue
		if _is_character_standing_on_horizontal_slammer(character_body):
			continue

		if not _is_node_in_front_of_slammer(character_body):
			continue

		var previous_position: Vector2 = character_body.global_position
		character_body.add_collision_exception_with(body)
		var collision := character_body.move_and_collide(motion)
		character_body.remove_collision_exception_with(body)
		var actual_motion: Vector2 = character_body.global_position - previous_position

		if collision != null or actual_motion.distance_squared_to(motion) > 0.01:
			_damage_character_body(character_body, head_hit_box)
			return true

	return false


func _get_overlapping_character_bodies() -> Array[CharacterBody2D]:
	var result: Array[CharacterBody2D] = []

	for colliding_body in body.get_colliding_bodies():
		if _is_light_clanker(colliding_body):
			continue
		if colliding_body is CharacterBody2D and colliding_body not in result:
			result.append(colliding_body)

	return result


func _is_node_in_front_of_slammer(node: Node2D) -> bool:
	var local_position := body.to_local(node.global_position)
	var front_center := body_collision_shape.position + _slam_direction.normalized() * _get_body_half_depth()
	var distance_from_front := (local_position - front_center).dot(_slam_direction.normalized())
	return distance_from_front >= -FRONT_PROBE_SKIN


func _carry_horizontal_riders(motion: Vector2) -> void:
	if motion.is_zero_approx() or not _is_horizontal_motion(motion):
		return

	for character_body in _get_overlapping_character_bodies():
		if not _is_character_standing_on_horizontal_slammer(character_body):
			continue

		character_body.add_collision_exception_with(body)
		character_body.move_and_collide(motion)
		character_body.remove_collision_exception_with(body)


func _is_horizontal_motion(motion: Vector2) -> bool:
	return absf(motion.x) > absf(motion.y)


func _is_character_standing_on_horizontal_slammer(character_body: CharacterBody2D) -> bool:
	if not _is_horizontal_motion(_to_global_velocity(_slam_direction)):
		return false
	if not character_body.is_on_floor():
		return false

	var slammer_top_y := _get_slammer_global_top_y()
	var character_bottom_y := _get_character_global_bottom_y(character_body)
	return character_bottom_y <= slammer_top_y + RIDER_TOP_TOLERANCE


func _get_slammer_global_top_y() -> float:
	if not body_collision_shape or not body_collision_shape.shape:
		return body.global_position.y

	var rect_shape := body_collision_shape.shape as RectangleShape2D
	if rect_shape:
		return body_collision_shape.global_position.y - rect_shape.size.y * 0.5 * absf(body_collision_shape.global_scale.y)

	var capsule_shape := body_collision_shape.shape as CapsuleShape2D
	if capsule_shape:
		return body_collision_shape.global_position.y - capsule_shape.height * 0.5 * absf(body_collision_shape.global_scale.y)

	return body.global_position.y


func _get_character_global_bottom_y(character_body: CharacterBody2D) -> float:
	var collision_shape := _find_collision_shape(character_body)
	if collision_shape == null or collision_shape.shape == null:
		return character_body.global_position.y

	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape:
		return collision_shape.global_position.y + rect_shape.size.y * 0.5 * absf(collision_shape.global_scale.y)

	var capsule_shape := collision_shape.shape as CapsuleShape2D
	if capsule_shape:
		return collision_shape.global_position.y + capsule_shape.height * 0.5 * absf(collision_shape.global_scale.y)

	var circle_shape := collision_shape.shape as CircleShape2D
	if circle_shape:
		return collision_shape.global_position.y + circle_shape.radius * absf(collision_shape.global_scale.y)

	return character_body.global_position.y


func _find_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		return node

	for child in node.get_children():
		var collision_shape := _find_collision_shape(child)
		if collision_shape != null:
			return collision_shape

	return null


func _damage_using_hitbox(
	source_hit_box: HitBox,
	include_colliding_bodies := true,
	manage_hit_box_active := true
) -> void:
	if not enable_damage:
		return

	if manage_hit_box_active:
		_set_hit_box_active(source_hit_box, true)

	for hurt_box in _get_hurt_boxes_inside_hitbox(source_hit_box):
		_damage_hurt_box(hurt_box, source_hit_box)
			
	if include_colliding_bodies:
		for character_body in _get_overlapping_character_bodies():
			_damage_character_body(character_body, source_hit_box)

	if manage_hit_box_active:
		_set_hit_box_active(source_hit_box, false)


func _get_hurt_boxes_inside_hitbox(source_hit_box: HitBox) -> Array[HurtBox]:
	var result: Array[HurtBox] = []
	var space_state := source_hit_box.get_world_2d().direct_space_state

	for collision_shape in _get_hitbox_collision_shapes(source_hit_box):
		if collision_shape.disabled or collision_shape.shape == null:
			continue

		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = collision_shape.shape
		query.transform = collision_shape.global_transform
		query.collision_mask = source_hit_box.collision_mask
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.exclude = [source_hit_box.get_rid()]

		for hit in space_state.intersect_shape(query):
			var area := hit.get("collider") as Area2D
			if area == null or _is_light_clanker(area):
				continue
			if area is HurtBox and area not in result:
				result.append(area)

	return result


func _get_hitbox_collision_shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []

	for child in node.get_children():
		if child is CollisionShape2D:
			result.append(child)
		else:
			result.append_array(_get_hitbox_collision_shapes(child))

	return result


func _damage_character_body(character_body: CharacterBody2D, source_hit_box: HitBox) -> void:
	if _is_light_clanker(character_body):
		return

	for child in character_body.get_children():
		var hurt_box := _find_hurt_box(child)
		if hurt_box != null:
			_damage_hurt_box(hurt_box, source_hit_box)


func _find_hurt_box(node: Node) -> HurtBox:
	if node is HurtBox:
		return node

	for child in node.get_children():
		var hurt_box := _find_hurt_box(child)
		if hurt_box != null:
			return hurt_box

	return null


func _damage_hurt_box(hurt_box: HurtBox, source_hit_box: HitBox) -> void:
	if _is_light_clanker(hurt_box):
		return

	hurt_box.take_damage(source_hit_box.damage)


func _is_light_clanker(node: Node) -> bool:
	var current_node := node

	while current_node != null:
		if current_node is LightClanker:
			return true

		current_node = current_node.get_parent()

	return false


func _ignore_existing_light_clankers() -> void:
	for node in get_tree().get_nodes_in_group(LightClanker.IGNORE_SLAMMER_BODY_GROUP):
		if node is PhysicsBody2D:
			body.add_collision_exception_with(node)
			node.add_collision_exception_with(body)
