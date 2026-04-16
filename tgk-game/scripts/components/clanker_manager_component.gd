class_name ClankerManagerComponent
extends Node


signal control_started
signal control_ended

@export_group("Settings")
@export var clanker_scenes: Array[PackedScene]
@export var clanker_cooldown_durations: Array[float]
@export var spawn_offset: Vector2 = Vector2(10, -0.5)

@export_group("Required References")
@export var actor: CharacterBody2D
@export var movement_component: MovementComponent

var current_clanker: Node2D = null
var is_controlling_clanker: bool = false
var spawned_clanker_index: int
var clanker_index: int = 0

@onready var control_timer: Timer = %ControlTimer
@onready var control_return_timer: Timer = %ControlReturnTimer
@onready var cooldown_timers: Array[Timer]

func _ready() -> void:
	for i in clanker_scenes.size():
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = clanker_cooldown_durations[i]
		cooldown_timers.append(timer) 
		add_child(timer)

func handle_clanker_input(wants_spawn: bool, wants_reset: bool, selected_slot: int) -> void:
	var can_spawn = actor.is_on_floor() and cooldown_timers[clanker_index].time_left <= 0
	var wants_chanege_clanker_slot = selected_slot != -1 and selected_slot != clanker_index
	if wants_chanege_clanker_slot:
		clanker_index = selected_slot
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
	
	spawned_clanker_index = clanker_index
	
	var new_clanker = clanker_scenes[clanker_index].instantiate()
	var dir = movement_component.direction
	var starting_position = actor.global_position + Vector2(spawn_offset.x * dir, spawn_offset.y)
	
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
	cooldown_timers[spawned_clanker_index].start()
