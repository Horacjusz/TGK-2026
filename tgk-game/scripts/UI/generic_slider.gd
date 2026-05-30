extends UI_PIECE
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
var _dragging = false

signal value_changed(value)

func set_value(new_value) :
	_silent = true
	slider.value = new_value
	_silent = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
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
		if Globals.audio != null :
			Globals.audio.play_sound(
				self,
				CLICKS[randi_range(0, CLICKS.size() - 1)],
				50 # half of the max volume
			)
	
	pass # Replace with function body.

func _on_slider_drag_started() -> void:
	slider.grab_focus()
	Globals.menu.mouse_lock(self)
	pass # Replace with function body.


func _on_slider_drag_ended(value_changed: bool) -> void:
	Globals.menu.mouse_unlock(self)
	slider.release_focus()
	pass # Replace with function body.


func _on_slider_focus_entered() -> void:
	print("Entered ", self)
	pass # Replace with function body.


func _on_slider_focus_exited() -> void:
	print("Exited ", self)
	pass # Replace with function body.
