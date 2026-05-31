extends Node


signal player_died()

signal input_disabled_changed(is_disabled: bool)

signal interaction_hud_shown(text: String)
signal interaction_hud_hidden()

signal tutorial_shown(tutorial: TutorialData)
signal tutorial_hidden()

signal clanker_change_requested(type: String)
signal clanker_changed(type: String)
signal clanker_cooldown_changed(
	type: String, 
	is_on_cooldown: bool, 
	duration: float, 
	time_left: float,
)
