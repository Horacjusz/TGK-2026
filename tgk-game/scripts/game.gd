extends Control
@onready var main: Node2D = $SubViewportContainer/GameViewport/Main
@onready var menu: Control = $UI/Menu
@onready var audio_manager: Node = $UI/AudioManager

func _ready() -> void:
	Globals.audio = audio_manager
	Globals.menu = menu
	Globals.pause_game()
