class_name Player
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	CLANKER,
}

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var input_component: InputComponent = $InputComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var jump_buffer_timer: Timer = %JumpBufferTimer
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var control_return_timer = %ControlReturTimer
var current_state: State = State.IDLE
#=======================new============================
@export var clanker: PackedScene
@export var spawn_offset: int = 10
@onready var clanker_timer: Timer = %ClankerControlTimer
var current_clanker: Node2D = null


func _ready() -> void:
	clanker_timer.timeout.connect(_on_clanker_timer_timeout)
	control_return_timer.timeout.connect(_on_control_return_timer_timeout)

func _on_clanker_timer_timeout() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.disable_control()
	control_return_timer.start()
func _on_control_return_timer_timeout() -> void:
	current_state = State.IDLE
	animated_sprite.play("idle")
func _physics_process(delta: float) -> void:
	handle_input()
	update_state()
	handle_state(delta)


func handle_input() -> void:
	input_component.update()
	
	if input_component.jump_pressed:
		jump_buffer_timer.start()


func update_state() -> void:
	var move_axis = input_component.move_axis
	var wants_jump = jump_buffer_timer.time_left > 0
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var wants_spawn_clanker = input_component.clanker_pressed
	# Placeholder later mb cooldown
	var can_spawn_clanker = true
	
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
			elif wants_spawn_clanker and can_jump and can_spawn_clanker:
				clanker_timer.start()
				spawn_clanker()
				current_state = State.CLANKER
				animated_sprite.play("idle")
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
		State.CLANKER:
			pass
			


func handle_state(delta: float) -> void:
	var axis = input_component.move_axis
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
		State.CLANKER:
			movement_component.move_horizontal(delta, 0)
			movement_component.apply_gravity(delta)
	
	movement_component.move_and_slide()
	
func spawn_clanker() -> void:
	_despawn_clanker()
	var new_clanker = clanker.instantiate()
	var dir = movement_component.direction
	var starting_position = global_position + Vector2(spawn_offset * dir, 0)
	new_clanker.init(starting_position, self)
	get_parent().add_child(new_clanker)
	current_clanker = new_clanker
func kill_clanker() -> void:
	_despawn_clanker()
	clanker_timer.stop()
	control_return_timer.start()
func _despawn_clanker() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.kill()
	current_clanker = null
