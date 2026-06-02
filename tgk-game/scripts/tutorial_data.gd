extends Resource
class_name TutorialData


@export var title: String
@export_multiline var content: String
@export var animation_name: String = ""
@export var wait_for_animation: bool = true
@export var hide_sprite = false
@export var next_tutorial: TutorialData
@export var previous_tutorial: TutorialData
@export var unlock_clanker: String = ""
