extends Node2D


@onready var reload_level_timer: Timer = %ReloadLevelTimer
# in future replace with Level interface
@onready var active_level: Node2D = %Level_0
@onready var camera: Camera2D = %Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_level()

func _setup_level() -> void:
	var tilemap = active_level.get_background_tilemap()
	camera.setup_camera_limits(tilemap)

func pause_game() :
	self.process_mode = Node.PROCESS_MODE_DISABLED

func resume_game() :
	self.process_mode = Node.PROCESS_MODE_INHERIT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_died() -> void:
	Engine.time_scale = 0.5
	reload_level_timer.start()


func _on_reload_level_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
