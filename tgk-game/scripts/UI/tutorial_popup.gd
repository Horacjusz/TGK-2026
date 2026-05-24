extends Control
class_name TutorialPopup


var current_tutorial: TutorialData

@onready var tutorial_content: RichTextLabel = %TutorialContent


func set_tutorial(tutorial: TutorialData) -> void:
	current_tutorial = tutorial
	tutorial_content.text = tutorial.content


func open() -> void:
	visible = true
	set_process_input(true)
	GlobalSignalBus.input_disabled_changed.emit(true)


func close() -> void:
	visible = false
	set_process_input(false)
	GlobalSignalBus.input_disabled_changed.emit(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_handle_interact()
	get_viewport().set_input_as_handled()


func _handle_interact() -> void:
	if current_tutorial and current_tutorial.next_tutorial:
		set_tutorial(current_tutorial.next_tutorial)
	else:
		GlobalSignalBus.tutorial_hidden.emit()
