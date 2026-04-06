class_name Player
extends CharacterBody2D


@export var clanker: PackedScene
@export var spawn_offset: int = 10

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var jump_component: JumpComponent = %JumpComponent
@onready var gravity_component: GravityComponent = %GravityComponent
@onready var control_return_timer = %ControlReturTimer
@onready var clanker_timer: Timer = %ClankerControlTimer
@onready var clanker_cooldown_timer = %ClankerCooldownTimer

var is_controlling_clanker: bool = false


func _ready() -> void:
	clanker_timer.timeout.connect(_on_clanker_timer_timeout)
	control_return_timer.timeout.connect(_on_control_return_timer_timeout)


func _on_clanker_timer_timeout() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.disable_control()
	control_return_timer.start()


func _on_control_return_timer_timeout() -> void:
	is_controlling_clanker = false
	# animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	input_component.update()
	gravity_component.handle_gravity(delta)

	# TODO: Extract clanker logic into component
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var wants_spawn_clanker = input_component.clanker_pressed
	var can_spawn_clanker = clanker_cooldown_timer.time_left <= 0

	if not is_controlling_clanker:
		movement_component.handle_movement(input_component.move_axis, delta)
		jump_component.handle_jump(input_component.jump_pressed, input_component.jump_released)

		if wants_spawn_clanker and can_jump and can_spawn_clanker:
				clanker_timer.start()
				spawn_clanker()
				is_controlling_clanker = true

	if input_component.reset_clanker_pressed and current_clanker and is_instance_valid(current_clanker):
		if is_controlling_clanker:
			# Was controlling clanker — despawn with cooldown
			_reset_clanker()
		else:
			# Not controlling — just despawn instantly
			_despawn_clanker()

	move_and_slide()


func spawn_clanker() -> void:
	_despawn_clanker()
	var new_clanker = clanker.instantiate()
	var dir = movement_component.direction
	var starting_position = global_position + Vector2(spawn_offset * dir, -0.5)
	new_clanker.init(starting_position, self)
	get_parent().add_child(new_clanker)
	current_clanker = new_clanker


func _reset_clanker() -> void:
	_despawn_clanker()
	clanker_timer.stop()
	control_return_timer.start()


func kill_clanker() -> void:
	_reset_clanker()
	clanker_cooldown_timer.start()


func _despawn_clanker() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.kill()
	current_clanker = null