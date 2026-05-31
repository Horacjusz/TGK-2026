extends Node

const MENU_MUSIC_FADE_TIME = 1 # seconds

var PAUSED = false

var menu = null
var audio = null


func pause_game(show_menu = true) :
	PAUSED = true
	get_tree().paused = PAUSED
	if show_menu :
		menu.display()

func resume_game() :
	menu.retract()
	PAUSED = false
	get_tree().paused = PAUSED
