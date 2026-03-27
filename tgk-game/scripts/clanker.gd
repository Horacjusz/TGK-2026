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
@export var push_force: float = 1.0
var input_recorder: InputRecorder = InputRecorder.new()
var current_state: State = State.IDLE
var active_input: InputSource = null
var starting_position: Vector2
var record_input: bool = true
var owner_player: Player = null
var velocity_before_slide: Vector2 = Vector2.ZERO
func init(pos: Vector2, player: Player) -> void:
	starting_position = pos
	owner_player = player

func _ready() -> void:
	_reset_to_start()
	active_input = input_component
	input_playback.playback_finished.connect(_on_playback_finished)

func _on_playback_finished() -> void:
	input_playback.reset()
	_reset_to_start()

func _reset_to_start() -> void:
	global_position = starting_position
	velocity = Vector2.ZERO
	current_state = State.IDLE
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	handle_input()
	update_state()
	handle_state(delta)

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
				movement_component.jump()
			movement_component.move_horizontal(delta, axis)
			movement_component.apply_gravity(delta)
		State.FALL:
			movement_component.move_horizontal(delta, axis)
			movement_component.apply_gravity(delta)
	velocity_before_slide = velocity
	movement_component.move_and_slide()
	_push_player()

func _push_player() -> void:
	if record_input:
		return
	if not owner_player or not is_instance_valid(owner_player):
		return
	var distance = global_position.distance_to(owner_player.global_position)
	var push_radius = 10.0
	if distance < push_radius:
		var direction = (owner_player.global_position - global_position).normalized()
		owner_player.velocity.x = velocity_before_slide.x + direction.x * abs(velocity_before_slide.x)
		if velocity_before_slide.y < 0:
			owner_player.velocity.y = velocity_before_slide.y

func disable_control() -> void:
	record_input = false
	input_component.reset()
	jump_buffer_timer.stop()
	coyote_timer.stop()
	input_playback.load_recording(input_recorder.get_recording())
	_reset_to_start()
	active_input = input_playback
