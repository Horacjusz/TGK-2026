extends Control


var is_tutorial_popup_visible: bool = false
var is_interact_hud_visible: bool = false
var is_clanker_hud_visible: bool = true


@onready var tutorial_popup: TutorialPopup = %TutorialPopup
@onready var interact_hud: Control = %InteractHUD
@onready var clanker_hud: Control = %ClankerHUD
@onready var interact_label: Label = %InteractLabel


func _ready() -> void:
	GlobalSignalBus.interaction_hud_shown.connect(_on_interaction_hud_shown)
	GlobalSignalBus.interaction_hud_hidden.connect(_on_interaction_hud_hidden)
	GlobalSignalBus.tutorial_shown.connect(_on_tutorial_shown)
	GlobalSignalBus.tutorial_hidden.connect(_on_tutorial_hidden)
	
	_update_hud()


func _update_hud() -> void:
	if is_tutorial_popup_visible:
		tutorial_popup.open()
	else:
		tutorial_popup.close()
	
	interact_hud.visible = is_interact_hud_visible and !is_tutorial_popup_visible
	clanker_hud.visible = is_clanker_hud_visible and !is_tutorial_popup_visible

func _on_tutorial_shown(tutorial: TutorialData) -> void:
	tutorial_popup.set_tutorial(tutorial)
	is_tutorial_popup_visible = true
	_update_hud()


func _on_tutorial_hidden() -> void:
	is_tutorial_popup_visible = false
	_update_hud()


func _on_interaction_hud_shown(text: String = "Interact") -> void:
	interact_label.text = text
	is_interact_hud_visible = true
	_update_hud()


func _on_interaction_hud_hidden() -> void:
	is_interact_hud_visible = false
	_update_hud()
