extends Control
class_name TutorialPopup


var current_tutorial: TutorialData
var text_tween: Tween

@onready var tutorial_content: RichTextLabel = %TutorialContent


func set_tutorial(tutorial: TutorialData) -> void:
	current_tutorial = tutorial
	
	if text_tween and text_tween.is_running():
		text_tween.kill()
		
	tutorial_content.text = tutorial.content
	tutorial_content.visible_ratio = 0.0
	
	text_tween = create_tween()
	text_tween.tween_property(
		tutorial_content, 
		"visible_ratio", 
		1.0, 
		1.0
	)\
	.set_trans(Tween.TRANS_LINEAR)\
	.set_ease(Tween.EASE_IN_OUT)


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
	if text_tween and text_tween.is_running():
		text_tween.kill()
		tutorial_content.visible_ratio = 1.0
		return
	
	if current_tutorial and current_tutorial.next_tutorial:
		set_tutorial(current_tutorial.next_tutorial)
	else:
		GlobalSignalBus.tutorial_hidden.emit()
