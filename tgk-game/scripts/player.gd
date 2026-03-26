class_name Player
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

var current_state: State = State.IDLE

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
	
	movement_component.move_and_slide()
