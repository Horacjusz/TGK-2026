extends Control
class_name HoverBlocker

var mouse_owner: Control = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_highest_z_index()

func set_highest_z_index() :
	var parent = self.get_parent()
	if parent != null :
		_set_z_recursive(parent)

func _set_z_recursive(node) :
	if node is not Control:
		return
	z_index = max(z_index, node.z_index + 1)
	for child in node.get_children() :
		_set_z_recursive(child)

func lock(control: Control) -> void:
	mouse_owner = control
	show()

func unlock(control: Control) -> void:
	if mouse_owner != control:
		return
	mouse_owner = null
	hide()
