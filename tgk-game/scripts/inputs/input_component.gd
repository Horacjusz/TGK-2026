class_name InputComponent
extends InputSource


var is_disabled: bool = false
var clanker_pressed: bool = false
var reset_clanker_pressed: bool = false


func _ready() -> void:
	GlobalSignalBus.input_disabled_changed.connect(_on_input_disabled_changed)


func update() -> void:
	if is_disabled:
		return
	
	move_axis = Input.get_axis("move_left", "move_right")
	move_yaxis = Input.get_axis("move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	clanker_pressed = Input.is_action_just_pressed("spawn_clanker")
	reset_clanker_pressed = Input.is_action_just_pressed("reset_clanker")


func reset() -> void:
	super.reset()
	clanker_pressed = false


func _on_input_disabled_changed(value: bool) -> void:
	is_disabled = value
	if is_disabled:
		reset()
