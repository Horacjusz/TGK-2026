class_name InputSource
extends Node

var move_axis: float = 0.0
var jump_pressed: bool = false
var jump_released: bool = false
var move_yaxis: float = 0.0

func update() -> void:
	pass

func reset() -> void:
	move_axis = 0.0
	jump_pressed = false
	jump_released = false
	move_yaxis = 0.0
