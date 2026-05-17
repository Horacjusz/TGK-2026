extends Node2D
class_name TutorialObject

signal tutorial_end

@export_category("Content")
@export_multiline var text: String = ""
@export var next_tutorial: TutorialObject
@export var trigger: InteractiveObject2D

@export_category("Setup")
@onready var tutorial_prompt: Node2D = %TutorialPrompt
@onready var label: Label = %Label
@onready var is_active: bool = false;

func _ready() -> void:
	text +="\n [Q] Quit tutorial\t [E] Next step"
	label.text = text
	hide_tutorial()

func next() -> void:
	if next_tutorial == null:
		tutorial_end.emit()
		hide_tutorial()
		return
	hide_tutorial()
	next_tutorial.show_tutorial()

func show_tutorial() -> void:
	is_active = true
	tutorial_prompt.visible = true
	
func _on_player_exited() -> void:
	hide_tutorial()
	if next_tutorial == null:
		return
	next_tutorial._on_player_exited()
func hide_tutorial() -> void:
	is_active = false
	tutorial_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("interact"):
		next()
	
