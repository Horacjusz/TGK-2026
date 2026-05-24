extends Node2D


@export var tutorial: TutorialData

@onready var interactable: Interactable = %Interactable


func _on_interactable_interacted() -> void:
	if !tutorial:
		return
	GlobalSignalBus.tutorial_shown.emit(tutorial)
