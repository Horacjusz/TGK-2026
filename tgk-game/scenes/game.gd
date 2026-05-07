extends Control
@onready var main: Node2D = $SubViewportContainer/GameViewport/Main
@onready var menu: Control = $UI/Menu

func _ready() -> void:
	Globals.menu = menu
	Globals.init_game()
