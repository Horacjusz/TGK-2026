extends VBoxContainer
@onready var label: Label = $Label
@onready var slider: HSlider = $Slider

@export var text = "TEST"
@export var min_value: int
@export var value: int
@export var max_value: int

const CLICKS = [
	"res://assets/sounds/clicks/click1.ogg",
	"res://assets/sounds/clicks/click2.ogg"
]

var _silent = false

signal value_changed(value)

func set_value(new_value) :
	_silent = true
	slider.value = new_value
	_silent = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_slider_value_changed(new_value: float) -> void:
	#print("Valu changed to ", new_value)
	self.value = new_value
	value_changed.emit(self.value)
	if not _silent :
		Globals.audio.play_sound(
			self,
			CLICKS[randi_range(0, CLICKS.size() - 1)],
			50 # half of the max volume
		)
	
	pass # Replace with function body.
