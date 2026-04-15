class_name InputPlayback
extends InputSource


signal playback_finished

var recording: Array[Dictionary] = []
var current_index: int = 0
var remaining_ticks: int = 0


func load_recording(data: Array[Dictionary]) -> void:
	recording = data
	remaining_ticks = data[0]["duration"] if not data.is_empty() else 0


func reset() -> void:
	super.reset()
	current_index = 0
	remaining_ticks = recording[0]["duration"] if not recording.is_empty() else 0


func update() -> void:
	jump_pressed = false
	if current_index >= recording.size():
		move_axis = 0.0
		playback_finished.emit()
		return
	
	var frame = recording[current_index]
	move_axis = frame["move_axis"]
	jump_pressed = frame["jump_pressed"]
	
	remaining_ticks -= 1
	if remaining_ticks <= 0:
		current_index += 1
		if current_index < recording.size():
			remaining_ticks = recording[current_index]["duration"]
