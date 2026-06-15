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
	add_to_group(SaveManager.SAVABLE_GROUP)
	for clanker_name in clankers_data.clankers_available:
		_register_clanker_timer(clanker_name)
	GlobalSignalBus.clanker_change_requested.connect(_on_clanker_change_requested)
	GlobalSignalBus.clanker_unlock_requested.connect(unlock_clanker)
	GlobalSignalBus.clanker_changed.emit(selected_clanker_type)


func _register_clanker_timer(clanker_name: String) -> void:
	if clanker_name in cooldown_timers:
		return
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = clankers_data.clankers_cooldown_durations.get(clanker_name, 3.0)
	timer.timeout.connect(_on_cooldown_timer_timeout.bind(clanker_name))
	cooldown_timers[clanker_name] = timer
	add_child(timer)


func unlock_clanker(clanker_name: String) -> void:
	clankers_data.unlock(clanker_name)
	_register_clanker_timer(clanker_name)
	selected_clanker_type = clanker_name
	GlobalSignalBus.clanker_changed.emit(clanker_name)
	GlobalSignalBus.clanker_unlocked.emit(clanker_name)

func handle_clanker_input(
	wants_spawn: bool,
	ray_is_coliding: bool,
	wants_reset: bool,
) -> void:
	if wants_spawn and is_controlling_clanker and control_timer.time_left > 0:
		end_control_phase()
		return
	
	var can_spawn = (
		!ray_is_coliding
		and actor.is_on_floor()
		and cooldown_timers.has(selected_clanker_type)
		and cooldown_timers[selected_clanker_type].time_left <= 0
		and clankers_data.is_unlocked(selected_clanker_type)
	)
	# Logic for Spawning/Controlling
	if wants_spawn and can_spawn and not is_controlling_clanker:
		spawn_clanker()

	# Logic for Resetting/Despawning
	if wants_reset and current_clanker and is_instance_valid(current_clanker):
		if is_controlling_clanker:
			current_clanker.die()
		else:
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

func despawn_clanker() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.despawn()
	current_clanker = null


func end_control_phase() -> void:
	if control_timer.time_left > 0:
		control_timer.stop()
		
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.disable_control()
		
	control_return_timer.start()


func _on_clanker_change_requested(type: String) -> void:
	if type != selected_clanker_type:
		if not clankers_data.is_unlocked(type):
			return
		selected_clanker_type = type
		var cooldown_timer = cooldown_timers.get(type)
		GlobalSignalBus.clanker_changed.emit(type)
		if cooldown_timer:
			GlobalSignalBus.clanker_cooldown_changed.emit(
				type,
				!cooldown_timer.is_stopped(),
				cooldown_timer.wait_time,
				cooldown_timer.time_left,
			)


func _on_control_timer_timeout() -> void:
	end_control_phase()


func _on_control_return_timer_timeout() -> void:
	is_controlling_clanker = false
	control_ended.emit()


func _on_cooldown_timer_timeout(type: String) -> void:
	GlobalSignalBus.clanker_cooldown_changed.emit(type, false)


func _on_clanker_died() -> void:
	control_timer.stop()
	control_return_timer.start()
	cooldown_timers[spawned_clanker_type].start()
	GlobalSignalBus.clanker_cooldown_changed.emit(
		spawned_clanker_type,
		true,
		cooldown_timers[spawned_clanker_type].wait_time,
		cooldown_timers[spawned_clanker_type].time_left,
	)


func get_save_id() -> String:
	return "player_clanker_manager"


func save_state(reset: bool = false) -> Dictionary:
	if reset:
		return {
			"unlocked_clankers": [] as Array[String],
			"selected_clanker": "" as String
		}
		
	return {
		"unlocked_clankers": clankers_data.clankers_available,
		"selected_clanker": selected_clanker_type
	}


func load_state(data: Dictionary) -> void:
	# TODO: Handle missing data
	var unlocked_clankers = data.get("unlocked_clankers")
	var selected_clanker = data.get("selected_clanker")
	
	clankers_data.unlock_all(unlocked_clankers)
	
	for clanker_name in clankers_data.clankers_available:
		_register_clanker_timer(clanker_name)
	
	selected_clanker_type = selected_clanker
	GlobalSignalBus.clanker_changed.emit(selected_clanker_type)
