class_name ClankerSpawnerComponent
extends Node


signal control_started
signal control_ended

@export_group("Settings")
@export var clanker_scene: PackedScene
@export var spawn_offset: int = 10

@export_group("Required References")
@export var actor: CharacterBody2D
@export var movement_component: MovementComponent

var current_clanker: Node2D = null
var is_controlling_clanker: bool = false

@onready var control_timer: Timer = %ControlTimer
@onready var control_return_timer: Timer = %ControlReturnTimer
@onready var cooldown_timer: Timer = %CooldownTimer


func handle_clanker_input(wants_spawn: bool, wants_reset: bool) -> void:
	var can_spawn = actor.is_on_floor() and cooldown_timer.time_left <= 0

	# Logic for Spawning/Controlling
	if wants_spawn and can_spawn and not is_controlling_clanker:
		spawn_clanker()

	# Logic for Resetting/Despawning
	if wants_reset and current_clanker and is_instance_valid(current_clanker):
		if is_controlling_clanker:
			# Was controlling clanker — despawn with cooldown
			reset_clanker()
		else:
			# Not controlling — just despawn instantly
			despawn_clanker()


func spawn_clanker() -> void:
	despawn_clanker()
	
	var new_clanker = clanker_scene.instantiate()
	var dir = movement_component.direction
	var starting_position = actor.global_position + Vector2(spawn_offset * dir, -0.5)
	
	new_clanker.init(starting_position, actor)
	actor.get_parent().add_child(new_clanker)
	
	new_clanker.connect("died", _on_clanker_died)
	
	current_clanker = new_clanker
	is_controlling_clanker = true
	control_timer.start()
	control_started.emit()


func reset_clanker() -> void:
	despawn_clanker()
	control_timer.stop()
	control_return_timer.start()


func despawn_clanker() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.kill()
	current_clanker = null


func _on_control_timer_timeout() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.disable_control()
	control_return_timer.start()


func _on_control_return_timer_timeout() -> void:
	is_controlling_clanker = false
	control_ended.emit()


func _on_clanker_died() -> void:
	reset_clanker()
	cooldown_timer.start()
