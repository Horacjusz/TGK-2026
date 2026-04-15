extends Node2D


@onready var reload_level_timer: Timer = %ReloadLevelTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_died() -> void:
	Engine.time_scale = 0.5
	reload_level_timer.start()


func _on_reload_level_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
