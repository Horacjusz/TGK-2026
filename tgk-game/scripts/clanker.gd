class_name Clanker
extends CharacterBody2D

signal died

@export var collision_layer_index: int
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var input_component: InputComponent = $InputComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var gravity_component: GravityComponent = %GravityComponent
@onready var jump_component: JumpComponent = %JumpComponent
@onready var input_playback: InputPlayback = %InputPlayback

var input_recorder: InputRecorder = InputRecorder.new()
var active_input: InputSource = null
var starting_position: Vector2
var record_input: bool = true
var owner_player: Player = null
var previous_position: Vector2 = Vector2.ZERO

var is_spawning: bool = false
var is_despawning: bool = false

# ====================== Initialization ======================

## Sets starting position and reference to the owning player.
func init(pos: Vector2, player: Player) -> void:
	starting_position = pos
	owner_player = player

## Initializes clanker state and connects playback signal.
func _ready() -> void:
	animation_tree.active = true
	await _reset_to_start(true)
	active_input = input_component

## Resets clanker to its starting position and clears velocity.
func _reset_to_start(on_ready: bool = false) -> void:
	set_physics_process(false)
	set_collision_layer_value(collision_layer_index, false)
	if not on_ready:
		is_despawning = true
		await animation_tree.animation_finished
		is_despawning = false
	global_position = starting_position
	previous_position = starting_position
	velocity = Vector2.ZERO
	is_spawning = true
	await animation_tree.animation_finished
	is_spawning = false
	set_collision_layer_value(collision_layer_index, true)
	set_physics_process(true)

# ====================== Main Loop ======================

## Main physics loop — reads input, updates state, moves clanker, pushes player.
func _physics_process(delta: float) -> void:
	previous_position = global_position
	handle_input()
	movement_component.handle_movement(active_input.move_axis, delta)
	jump_component.handle_jump(active_input.jump_pressed, active_input.jump_released)
	gravity_component.handle_gravity(delta)
	
	animation_tree.set("parameters/Moving/Airborne/blend_position", velocity.y)
	move_and_slide()

## Reads input from active source and starts jump buffer if needed.
func handle_input() -> void:
	active_input.update()
	if record_input:
		input_recorder.record(active_input)






## Called when playback loop finishes — resets clanker and briefly disables player collision.
func _on_playback_finished() -> void:
	input_playback.reset()
	await _reset_to_start()

## Stops recording, loads recorded input into playback, and switches to playback mode.
func disable_control() -> void:
	record_input = false
	input_component.reset()
	input_playback.load_recording(input_recorder.get_recording())
	await _reset_to_start()
	active_input = input_playback	

func die() -> void:
	set_physics_process(false)
	set_collision_layer_value(3, false)
	died.emit()
	animation_tree.set("parameters/conditions/is_dead", true)
	await animation_tree.animation_finished
	queue_free()

func despawn() -> void:
	set_physics_process(false)
	set_collision_layer_value(3, false)
	animation_tree.set("parameters/conditions/is_dead", true)
	await animation_tree.animation_finished
	queue_free()
