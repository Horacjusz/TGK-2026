extends Control
@onready var main: Node2D = $SubViewportContainer/GameViewport/Main
@onready var menu: Control = $UI/Menu

func _ready() -> void:
	Globals.menu = menu
	Globals.pause_game()

func _process(delta : float) -> void:
	if Input.is_action_just_pressed("pause") :
		Globals.pause_game()
