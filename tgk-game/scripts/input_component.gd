class_name InputComponent
extends InputSource

var clanker_pressed: bool = false
var reset_clanker_pressed: bool = false
var selected_slot: String = ""

func update() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	clanker_pressed = Input.is_action_just_pressed("spawn_clanker")
	reset_clanker_pressed = Input.is_action_just_pressed("reset_clanker")
	_update_selected_slot()

func _update_selected_slot() -> void:
	if Input.is_action_just_pressed("select_slot_1"):
		selected_slot = "clanker"
	elif Input.is_action_just_pressed("select_slot_2"):
		selected_slot = "light_clanker"
	elif Input.is_action_just_pressed("select_slot_3"):
		selected_slot = "defender_clanker"

func reset() -> void:
	super.reset()
	clanker_pressed = false
	selected_slot = ""
