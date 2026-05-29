extends VBoxContainer
@onready var label: Label = $Label
@onready var slider: HSlider = $Slider

@export var text = "TEST"
@export var min_value: int
@export var value: int
@export var max_value: int

signal value_changed(value)

func set_value(new_value) :
	slider.value = new_value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_slider_value_changed(new_value: float) -> void:
	print("Valu changed to ", new_value)
	self.value = new_value
	value_changed.emit(self.value)
	pass # Replace with function body.
