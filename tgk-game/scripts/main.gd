extends Node2D


const LEVEL_TRANSITION_DURATION := 0.2

var level: Level

@onready var player: Player = %Player
@onready var camera: PlayerCamera = %Camera2D
@onready var level_container: Node = %LevelContainer
@onready var reload_level_timer: Timer = %ReloadLevelTimer


func _ready() -> void:
	GlobalSignalBus.player_died.connect(_on_player_died)
	GlobalSignalBus.level_transition_requested.connect(
		_on_level_transition_requested
	)
	add_to_group(SaveManager.SAVABLE_GROUP)


func load_level(level_path: String) -> void:
	if level:
		if level_path == level.scene_file_path:
			return
		level_container.remove_child(level)
		level.queue_free()

	var scene := load(level_path) as PackedScene

	if scene == null:
		push_error("Failed to load level: %s" % level_path)
		return

	level = scene.instantiate() as Level
	level_container.add_child(level)

	_setup_level()


func _setup_level() -> void:
	var tilemap = level.get_background_tilemap()
	camera.setup_camera_limits(tilemap)


func get_save_id() -> String:
	return "main"


func save_state(reset: bool = false) -> Dictionary:
	if reset:
		#return {
			#"level_path": "res://scenes/levels/level_1.tscn" as String,
			#"checkpoint_id": 0 as int,
		#}
		# TEMPORARY CHANGE - CHANGE BACK IF I FORGOR PLEASE
		
		return {
			"level_path": "res://scenes/levels/level_dark.tscn" as String,
			"checkpoint_id": 0 as int,
		}
		
	return {
		"level_path": level.scene_file_path,
		"checkpoint_id": level.current_checkpoint.id,
	}


func load_state(data: Dictionary) -> void:
	# TODO: Handle missing data
	var level_path = data.get("level_path")
	var checkpoint_id = data.get("checkpoint_id")
	
	ProjectileManager.clear_projectiles()
	
	load_level(level_path)
	
	level.set_checkpoint_by_id(checkpoint_id)
	_teleport_player(level.current_checkpoint.global_position)


func _teleport_player(position: Vector2) -> void:
	player.global_position = position
	camera.move_to_player()

	#if player.has_method("set_facing_direction"):
		#player.set_facing_direction(checkpoint.direction)


func _on_player_died() -> void:
	Engine.time_scale = 0.5
	GlobalSignalBus.loading_screen_shown.emit(0.3)
	reload_level_timer.start()


func _on_reload_level_timer_timeout() -> void:
	Engine.time_scale = 1.0
	SaveManager.load_game()
	GlobalSignalBus.loading_screen_hidden.emit(0.1)


func _on_level_transition_requested(
	level_path: String,
	target_checkpoint_id: int
) -> void:
	_level_transition.call_deferred(level_path, target_checkpoint_id)


func _level_transition(level_path: String, target_checkpoint_id: int) -> void:
	Globals.pause_game(false)
	GlobalSignalBus.loading_screen_shown.emit(LEVEL_TRANSITION_DURATION)
	
	await get_tree().create_timer(LEVEL_TRANSITION_DURATION).timeout
	
	load_level(level_path)
	
	var target_checkpoint = level.get_checkpoint_by_id(target_checkpoint_id)
	if target_checkpoint:
		_teleport_player(target_checkpoint.global_position)
	else:
		push_error("Target checkpoint %s not found!" % target_checkpoint_id)
		
	await get_tree().physics_frame
	
	GlobalSignalBus.loading_screen_hidden.emit(LEVEL_TRANSITION_DURATION)
	
	await get_tree().create_timer(LEVEL_TRANSITION_DURATION).timeout
	
	Globals.resume_game()
