extends Node

var PAUSED = false

var menu = null

func pause_game() :
	PAUSED = true
	get_tree().paused = PAUSED
	menu.display()
	
func resume_game() :
	menu.retract()
	PAUSED = false
	get_tree().paused = PAUSED
