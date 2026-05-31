extends Node2D


var level: Level

@onready var player: Player = %Player
@onready var camera: PlayerCamera = %Camera2D
@onready var level_container: Node = %LevelContainer
@onready var reload_level_timer: Timer = %ReloadLevelTimer


func _ready() -> void:
	GlobalSignalBus.player_died.connect(_on_player_died)
	add_to_group(SaveManager.SAVABLE_GROUP)


func load_level(level_path: String) -> void:
	if level:
		if level_path == level.scene_file_path:
			return
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


func pause_game() :
	self.process_mode = Node.PROCESS_MODE_DISABLED


func resume_game() :
	self.process_mode = Node.PROCESS_MODE_INHERIT


func get_save_id() -> String:
	return "main"


func save_state(reset: bool = false) -> Dictionary:
	if reset:
		return {
			"level_path": "res://scenes/levels/level_1.tscn" as String,
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
	
	load_level(level_path)
	
	level.set_checkpoint_by_id(checkpoint_id)
	_spawn_player_at_checkpoint()


func _spawn_player_at_checkpoint() -> void:
	var checkpoint := level.current_checkpoint

	player.global_position = checkpoint.global_position
	camera.move_to_player()

	#if player.has_method("set_facing_direction"):
		#player.set_facing_direction(checkpoint.direction)


func _on_player_died() -> void:
	Engine.time_scale = 0.5
	reload_level_timer.start()


func _on_reload_level_timer_timeout() -> void:
	Engine.time_scale = 1.0
	SaveManager.load_game()
