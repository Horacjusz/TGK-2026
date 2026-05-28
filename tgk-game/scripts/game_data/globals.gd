extends Node

var PAUSED = false

var menu = null
var audio = null

func show_menu(no_animation = false) :
	pause_game()
	menu.display(no_animation)

func hide_menu() :
	menu.retract()
	resume_game()

func pause_game() :
	PAUSED = true
	get_tree().paused = PAUSED

func resume_game() :
	PAUSED = false
	get_tree().paused = PAUSED
