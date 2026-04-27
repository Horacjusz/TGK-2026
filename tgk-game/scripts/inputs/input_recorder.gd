class_name InputRecorder
extends Node

var recording: Array[Dictionary] = []
var last_input: Dictionary = {}
@export var record_jump: bool = true
@export var record_move_yaxis: bool = true
func record(input_component: InputComponent) -> void:
	var frame_input = {
		"move_axis": input_component.move_axis,
	}
	if record_jump:
		frame_input["jump_pressed"] = input_component.jump_pressed
		frame_input["jump_released"] = input_component.jump_released
	if record_move_yaxis:
		frame_input["move_yaxis"] = input_component.move_yaxis
	
	if _same_as_last(frame_input):
		recording[-1]["duration"] += 1
	else:
		frame_input["duration"] = 1
		recording.append(frame_input)
		last_input = frame_input

func _same_as_last(input: Dictionary) -> bool:
	if recording.is_empty():
		return false
	return input == last_input

func get_recording() -> Array[Dictionary]:
	return recording

func clear() -> void:
	recording.clear()
	last_input = {}
