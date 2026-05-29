extends Control
@onready var button: TextureButton = $"."
@onready var label: Label = %Label

@export var text := "TEST"

var hover_sound_filepath = "res://assets/sounds/hover/hover.mp3"
var unhover_sound_filepath = "res://assets/sounds/hover/unhover.mp3"
var click_sound_filepath = "res://assets/sounds/noice.mp3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pass # Replace with function body.

func _on_mouse_entered() -> void:
	#print("Hover start")
	Globals.audio.play_sound(
		self,
		hover_sound_filepath
	)

func _on_mouse_exited() -> void:
	#print("Hover end")
	Globals.audio.play_sound(
		self,
		unhover_sound_filepath
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	print(label.text, " pressed (this message will be removed once sound is added)")
	Globals.audio.play_sound(
		self,
		click_sound_filepath,
		75
	)
	pass # Replace with function body.
