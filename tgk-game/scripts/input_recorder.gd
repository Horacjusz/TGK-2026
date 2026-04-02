class_name InputRecorder

var recording: Array[Dictionary] = []
var last_input: Dictionary = {}

func record(input_component: InputComponent) -> void:
	var frame_input = {
		"move_axis": input_component.move_axis,
		"jump_pressed": input_component.jump_pressed,
	}
	
	if _same_as_last(frame_input):
		recording[-1]["duration"] += 1
	else:
		frame_input["duration"] = 1
		recording.append(frame_input)
		last_input = frame_input

func _same_as_last(input: Dictionary) -> bool:
	if recording.is_empty():
		return false
	return (
		input["move_axis"] == last_input["move_axis"]
		and input["jump_pressed"] == last_input["jump_pressed"]
	)

func get_recording() -> Array[Dictionary]:
	return recording

func clear() -> void:
	recording.clear()
	last_input = {}
