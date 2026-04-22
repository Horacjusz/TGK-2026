class_name Clanker
extends CharacterBody2D

signal died

# Max horizontal distance where player is considered "on" or "beside" clanker
const CARRY_RANGE_X: float = 9.0
# Max vertical distance where player is considered "on top" of clanker
const CARRY_RANGE_Y: float = 11.0
# Max vertical distance where player is considered "beside" clanker
const SIDE_PUSH_RANGE_Y: float = 3.0
# Distance at which collision with player is restored (player moved away)
const COLLISION_RESTORE_RANGE_X: float = 12.0
const COLLISION_RESTORE_RANGE_Y: float = 15.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var input_component: InputComponent = $InputComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var gravity_component: GravityComponent = %GravityComponent
@onready var jump_component: JumpComponent = %JumpComponent
@onready var input_playback: InputPlayback = %InputPlayback
@export_group("Death Effect Settings")
@export var death_effect: PackedScene
@export var death_anim_name: String = "clanker_death"
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
	set_collision_layer_value(3, false)
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
	set_collision_layer_value(3, true)
	set_physics_process(true)

# ====================== Main Loop ======================

## Main physics loop — reads input, updates state, moves clanker, pushes player.
func _physics_process(delta: float) -> void:
	previous_position = global_position
	handle_input()
	movement_component.handle_movement(active_input.move_axis, delta)
	jump_component.handle_jump(active_input.jump_pressed, false)
	gravity_component.handle_gravity(delta)
	
	animation_tree.set("parameters/Moving/Airborne/blend_position", velocity.y)
	move_and_slide()
	#_push_player(delta)

## Reads input from active source and starts jump buffer if needed.
func handle_input() -> void:
	active_input.update()
	if record_input:
		input_recorder.record(active_input)


# TODO: move this to die, handle death effect with animation player
func kill() -> void:
	if death_effect:
		var effect = death_effect.instantiate()
		effect.global_position = global_position
		effect.anim_name = death_anim_name
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
	input_playback.load_recording(input_recorder.get_recording())
	await _reset_to_start()
	active_input = input_playback	


func die():
	died.emit()
	queue_free()
