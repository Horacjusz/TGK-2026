extends Control
@onready var main: Node2D = $SubViewportContainer/GameViewport/Main
@onready var menu: Control = $UI/Menu
@onready var audio_manager: Node = $UI/AudioManager

func _ready() -> void:
	Globals.audio = audio_manager
	Globals.menu = menu
	Globals.init_game()
	#Globals.audio.play_sfx("res://assets/sounds/Girl from Petaluma_short.mp3", 100, 500)
	Globals.audio.play_music("res://assets/sounds/Girl from Petaluma.mp3")
	
