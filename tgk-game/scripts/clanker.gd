class_name Clanker
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
}

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var input_component: InputComponent = $InputComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var jump_buffer_timer: Timer = %JumpBufferTimer
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var input_playback: InputPlayback = %InputPlayback



var input_recorder: InputRecorder = InputRecorder.new()
var current_state: State = State.IDLE
var active_input: InputSource = null
var starting_position: Vector2
var record_input: bool = true
var owner_player: Player = null
var previous_position: Vector2 = Vector2.ZERO
var is_playback: bool = false

func init(pos: Vector2, player: Player) -> void:
	starting_position = pos
	owner_player = player

func _ready() -> void:
	_reset_to_start()
	active_input = input_component
	input_playback.playback_finished.connect(_on_playback_finished)

func _on_playback_finished() -> void:
	owner_player.set_collision_mask_value(3, false)
	input_playback.reset()
	_reset_to_start()
	owner_player.move_and_slide()
	owner_player.set_collision_mask_value(3, true)

func _reset_to_start() -> void:
	global_position = starting_position
	previous_position = starting_position
	velocity = Vector2.ZERO
	current_state = State.IDLE
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	handle_input()
	update_state()
	handle_state(delta)
	_push_player(delta)

func _push_player(delta: float) -> void:
	if not owner_player or not is_instance_valid(owner_player):
		return
	var delta_pos = global_position - previous_position
	if delta_pos == Vector2.ZERO:
		return
	var distance = owner_player.global_position - global_position
	if abs(delta_pos.x) > 10 or abs(delta_pos.y) > 10:
		return
	if not get_collision_mask_value(2):
		if distance.y > 0 or abs(distance.y) > 20 or abs(distance.x) > 15:
			_enable_player_collision()
	if abs(distance.x) < 9 and abs(distance.y) < 11 and distance.y < 0:
		owner_player.global_position.y += delta_pos.y * delta
	elif abs(distance.x) < 9 and abs(distance.y) < 3 and sign(distance.x) == sign(delta_pos.x):
		owner_player.global_position.x += delta_pos.x

func handle_input() -> void:
	active_input.update()
	if record_input:
		input_recorder.record(active_input)
	if active_input.jump_pressed:
		jump_buffer_timer.start()

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
func _disable_player_collision() -> void:
	if not owner_player or not is_instance_valid(owner_player):
		return
	var distance = owner_player.global_position - global_position
	if abs(distance.x) < 9 and abs(distance.y) < 11 and distance.y < 0:
		set_collision_mask_value(2, false)
func _enable_player_collision() -> void:
	set_collision_mask_value(2, true)

func disable_control() -> void:
	record_input = false
	input_component.reset()
	jump_buffer_timer.stop()
	coyote_timer.stop()
	input_playback.load_recording(input_recorder.get_recording())
	_reset_to_start()
	active_input = input_playback
	is_playback = true
