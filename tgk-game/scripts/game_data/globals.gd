extends Node

var PAUSED = false

var menu = null
var audio = null

func pause_game(no_animation = false) :
	PAUSED = true
	get_tree().paused = PAUSED
	menu.display(no_animation)
	
func resume_game() :
	menu.retract()
	PAUSED = false
	get_tree().paused = PAUSED
