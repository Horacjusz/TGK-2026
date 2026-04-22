extends Node
class_name ClankerManagerComponent


signal control_started
signal control_ended

@export_group("Settings")
@export var spawn_offset: Vector2 = Vector2(10, -0.5)

@export_group("Required References")
@export var actor: CharacterBody2D
@export var movement_component: MovementComponent

var current_clanker: Node2D = null
var is_controlling_clanker: bool = false
var spawned_clanker_type: String
var selected_clanker_type: String = "clanker"
@onready var clankers_data: ClankersData = %ClankersData
@onready var control_timer: Timer = %ControlTimer
@onready var control_return_timer: Timer = %ControlReturnTimer
var cooldown_timers: Dictionary[String, Timer] = {}

func _ready() -> void:
	# for developing purposes
	clankers_data.unlock_all(["clanker", "light_clanker", "defender_clanker"])
	for clanker_name in clankers_data.clankers_available:
		_register_clanker_timer(clanker_name)

func _register_clanker_timer(clanker_name: String) -> void:
	if clanker_name in cooldown_timers:
		return
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = clankers_data.clankers_cooldown_durations.get(clanker_name, 3.0)
	add_child(timer)
	cooldown_timers[clanker_name] = timer

func unlock_clanker(clanker_name: String) -> void:
	clankers_data.unlock(clanker_name)
	_register_clanker_timer(clanker_name)

func handle_clanker_input(wants_spawn: bool, wants_reset: bool, selected_slot: String) -> void:
	var can_spawn = actor.is_on_floor() and cooldown_timers[selected_clanker_type].time_left <= 0
	can_spawn = can_spawn and clankers_data.is_unlocked(selected_clanker_type)
	var wants_chanege_clanker_slot = selected_slot and selected_slot != selected_clanker_type
	if wants_chanege_clanker_slot:
		print(selected_slot)
		selected_clanker_type = selected_slot
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
	
	spawned_clanker_type = selected_clanker_type
	
	var new_clanker = clankers_data.clankers_scenes[selected_clanker_type].instantiate()
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
	cooldown_timers[spawned_clanker_type].start()
