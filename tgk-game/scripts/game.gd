extends Control
@onready var main: Node2D = $SubViewportContainer/GameViewport/Main
@onready var menu: Control = $UI/Menu
@onready var audio_manager: Node = $UI/AudioManager

func _ready() -> void:
	Globals.audio = audio_manager
	Globals.menu = menu
	Globals.show_menu(true)
	
	#var music = Globals.audio.loop_music(
		#self, # parent
		#"res://assets/sounds/Girl from Petaluma.mp3", # path to sound
		#100.0, # volume
		#-1, # loop count (-1 means infinite)
		#false, # smooth start
		#false, # smooth loop
		#0.05 # smooth factor
	#)
