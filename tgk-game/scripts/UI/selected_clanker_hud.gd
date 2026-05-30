extends Control


var CLANKER_ICONS: Dictionary = {
	"clanker": preload("res://assets/UI/clanker_icon.tres"),
	"defender_clanker": preload("res://assets/UI/clanker_def_icon.tres"),
	"light_clanker": preload("res://assets/UI/clanker_light_icon.tres")
}

var selected_clanker_type: String = "clanker"
var active_tween: Tween

@onready var clanker_icon: TextureRect = %ClankerIcon
@onready var cooldown_progress_bar: ProgressBar = %CooldownProgressBar


func _ready() -> void:
	GlobalSignalBus.clanker_changed.connect(_on_clanker_changed)
	GlobalSignalBus.clanker_cooldown_changed.connect(_on_clanker_cooldown_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_slot_1"):
		GlobalSignalBus.clanker_change_requested.emit("clanker")
	elif event.is_action_pressed("select_slot_2"):
		GlobalSignalBus.clanker_change_requested.emit("defender_clanker")
	elif event.is_action_pressed("select_slot_3"):
		GlobalSignalBus.clanker_change_requested.emit("light_clanker")


func _on_clanker_changed(type: String) -> void:
	selected_clanker_type = type
	
	var icon_texture = CLANKER_ICONS.get(type)
	if icon_texture:	
		clanker_icon.texture = icon_texture


func _on_clanker_cooldown_changed(
	type: String,
	is_on_cooldown: bool,
	duration: float = 0.0,
	time_left: float = 0.0,
) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	if is_on_cooldown:
		var start_value = (time_left / duration) * 100.0
		cooldown_progress_bar.value = start_value
	
		active_tween = create_tween()
		active_tween.set_trans(Tween.TRANS_LINEAR)
		active_tween.tween_property(cooldown_progress_bar, "value", 0, time_left)
	else:
		cooldown_progress_bar.value = 0
