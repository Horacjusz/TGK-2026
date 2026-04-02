class_name Clanker
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
}

## Collision distances for detecting player position relative to clanker.
## Adjust these values when changing clanker model/sprite size.

# Max horizontal distance where player is considered "on" or "beside" clanker
const CARRY_RANGE_X: float = 9.0
# Max vertical distance where player is considered "on top" of clanker
const CARRY_RANGE_Y: float = 11.0
# Max vertical distance where player is considered "beside" clanker
const SIDE_PUSH_RANGE_Y: float = 3.0
# Distance at which collision with player is restored (player moved away)
const COLLISION_RESTORE_RANGE_X: float = 12.0
const COLLISION_RESTORE_RANGE_Y: float = 15.0

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var input_component: InputComponent = $InputComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var jump_buffer_timer: Timer = %JumpBufferTimer
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var input_playback: InputPlayback = %InputPlayback
@export var death_effect: PackedScene

var input_recorder: InputRecorder = InputRecorder.new()
var current_state: State = State.IDLE
var active_input: InputSource = null
var starting_position: Vector2
var record_input: bool = true
var owner_player: Player = null
var previous_position: Vector2 = Vector2.ZERO

# ====================== Initialization ======================

## Sets starting position and reference to the owning player.
func init(pos: Vector2, player: Player) -> void:
	starting_position = pos
	owner_player = player

## Initializes clanker state and connects playback signal.
func _ready() -> void:
	await _reset_to_start(true)
	active_input = input_component
	input_playback.playback_finished.connect(_on_playback_finished)

## Resets clanker to its starting position and clears velocity.
func _reset_to_start(on_ready: bool = false) -> void:
	set_physics_process(false)
	set_collision_layer_value(3, false)
	if not on_ready:
		animated_sprite.play("despawn")
		await animated_sprite.animation_finished
	global_position = starting_position
	previous_position = starting_position
	velocity = Vector2.ZERO
	current_state = State.IDLE
	animated_sprite.play("spawn")
	await animated_sprite.animation_finished
	set_collision_layer_value(3, true)
	set_physics_process(true)

# ====================== Main Loop ======================

## Main physics loop — reads input, updates state, moves clanker, pushes player.
func _physics_process(delta: float) -> void:
	previous_position = global_position
	handle_input()
	update_state()
	handle_state(delta)
	_push_player(delta)

## Reads input from active source and starts jump buffer if needed.
func handle_input() -> void:
	active_input.update()
	if record_input:
		input_recorder.record(active_input)
	if active_input.jump_pressed:
		jump_buffer_timer.start()

## Determines current state based on input and physics conditions.
func update_state() -> void:
	var move_axis = active_input.move_axis
	var wants_jump = jump_buffer_timer.time_left > 0
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	match current_state:
		State.IDLE:
			if wants_jump and can_jump:
				current_state = State.JUMP
				animated_sprite.play("jump")
			elif abs(move_axis) > 0:
				current_state = State.RUN
				animated_sprite.play("run")
			elif not is_on_floor():
				coyote_timer.start()
				current_state = State.FALL
				animated_sprite.play("fall")
		State.RUN:
			if wants_jump and can_jump:
				current_state = State.JUMP
				animated_sprite.play("jump")
			elif abs(move_axis) == 0:
				current_state = State.IDLE
				animated_sprite.play("idle")
			elif not is_on_floor():
				coyote_timer.start()
				current_state = State.FALL
				animated_sprite.play("fall")
		State.JUMP:
			if velocity.y > 0:
				current_state = State.FALL
				animated_sprite.play("fall")
		State.FALL:
			if is_on_floor():
				if abs(move_axis) > 0:
					current_state = State.RUN
					animated_sprite.play("run")
				else:
					current_state = State.IDLE
					animated_sprite.play("idle")
			elif wants_jump and can_jump:
				current_state = State.JUMP
				animated_sprite.play("jump")

## Executes movement logic based on current state.
func handle_state(delta: float) -> void:
	var axis = active_input.move_axis
	var wants_jump = jump_buffer_timer.time_left > 0
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	match current_state:
		State.IDLE:
			movement_component.move_horizontal(delta, 0)
			movement_component.apply_gravity(delta)
		State.RUN:
			movement_component.move_horizontal(delta, axis)
			movement_component.apply_gravity(delta)
		State.JUMP:
			if wants_jump and can_jump:
				jump_buffer_timer.stop()
				coyote_timer.stop()
				_disable_player_collision()
				movement_component.jump()
			movement_component.move_horizontal(delta, axis)
			movement_component.apply_gravity(delta)
		State.FALL:
			movement_component.move_horizontal(delta, axis)
			movement_component.apply_gravity(delta)

	movement_component.move_and_slide()

func kill() -> void:
	if death_effect:
		var effect = death_effect.instantiate()
		effect.global_position = global_position
		effect.anim_name = "clanker_death"
		get_parent().add_child(effect)
	queue_free()

# ====================== Player Interaction ======================

## Pushes or carries the player based on relative position.
func _push_player(delta: float) -> void:
	if not owner_player or not is_instance_valid(owner_player):
		return
	owner_player.movement_component.is_pushed = false
	owner_player.movement_component.external_velocity = 0.0
	var delta_pos = global_position - previous_position
	if delta_pos == Vector2.ZERO:
		return
	var distance = owner_player.global_position - global_position
	# Safe check for not teleporting player
	if abs(delta_pos.x) > 10 or abs(delta_pos.y) > 10:
		return
	if not get_collision_mask_value(2):
		if distance.y > 0 or abs(distance.y) > COLLISION_RESTORE_RANGE_Y or abs(distance.x) > COLLISION_RESTORE_RANGE_X:
			_enable_player_collision()
	# Carrying player on top
	if abs(distance.x) < CARRY_RANGE_X and abs(distance.y) < CARRY_RANGE_Y and distance.y < 0:
		owner_player.global_position.y += delta_pos.y * delta
	# Pushing player from side
	# It doesnt working but i leav it here for future fixes
	elif abs(distance.x) < CARRY_RANGE_X and abs(distance.y) < SIDE_PUSH_RANGE_Y and sign(distance.x) == sign(delta_pos.x):
		owner_player.global_position.x += delta_pos.x
		owner_player.movement_component.is_pushed = true
		owner_player.movement_component.external_velocity = velocity.x

## Disables collision mask for player layer so clanker can jump through.
func _disable_player_collision() -> void:
	if not owner_player or not is_instance_valid(owner_player):
		return
	var distance = owner_player.global_position - global_position
	if abs(distance.x) < 9 and abs(distance.y) < 11 and distance.y < 0:
		set_collision_mask_value(2, false)

## Re-enables collision mask for player layer.
func _enable_player_collision() -> void:
	set_collision_mask_value(2, true)

# ====================== Playback & Recording ======================

## Called when playback loop finishes — resets clanker and briefly disables player collision.
func _on_playback_finished() -> void:
	input_playback.reset()
	await _reset_to_start()

## Stops recording, loads recorded input into playback, and switches to playback mode.
func disable_control() -> void:
	record_input = false
	input_component.reset()
	jump_buffer_timer.stop()
	coyote_timer.stop()
	input_playback.load_recording(input_recorder.get_recording())
	await _reset_to_start()
	active_input = input_playback	
