extends UI_PIECE
@onready var button: TextureButton = $"."
@onready var label: Label = $Label

@export var text := "TEST"

const click_sound_filepath = "res://assets/sounds/noice.mp3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	label.text = text
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	Globals.audio.play_sound(
		self,
		click_sound_filepath,
		75
	)
	pass # Replace with function body.
