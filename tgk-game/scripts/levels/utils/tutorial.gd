extends Node2D


@export var tutorial: TutorialData
@export var tutorial_sprite: AnimatedSprite2D

@onready var interactable: Interactable = %Interactable


func _on_interactable_interacted() -> void:
	if !tutorial:
		return
	if tutorial.unlock_clanker != "":
		GlobalSignalBus.clanker_unlock_requested.emit(tutorial.unlock_clanker)
	GlobalSignalBus.tutorial_shown.emit(tutorial, tutorial_sprite)
