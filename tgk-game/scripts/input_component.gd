class_name InputComponent
extends InputSource


var jump_released: bool = false
var clanker_pressed: bool = false
var reset_clanker_pressed: bool = false
var selected_slot: int = -1

func update() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	clanker_pressed = Input.is_action_just_pressed("spawn_clanker")
	reset_clanker_pressed = Input.is_action_just_pressed("reset_clanker")
	selected_slot = -1
	if Input.is_action_just_pressed("select_slot_1"):
		selected_slot = 0
	elif Input.is_action_just_pressed("select_slot_2"):
		selected_slot = 1
	elif Input.is_action_just_pressed("select_slot_3"):
		selected_slot = 2


func reset() -> void:
	super.reset()
	clanker_pressed = false
	selected_slot = -1
