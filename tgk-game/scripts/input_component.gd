class_name InputComponent
extends InputSource


var jump_released: bool = false
var clanker_pressed: bool = false
var reset_clanker_pressed: bool = false


func update() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	clanker_pressed = Input.is_action_just_pressed("spawn_clanker")
	reset_clanker_pressed = Input.is_action_just_pressed("reset_clanker")


func reset() -> void:
	super.reset()
	clanker_pressed = false
