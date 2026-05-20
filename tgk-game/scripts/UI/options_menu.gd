extends UI

@onready var audio: VBoxContainer = $Menu/Audio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func turn_on() :
	self.audio.set_sliders()
	super.turn_on()
	
func turn_off() :
	super.turn_off()
	self.audio.set_sliders()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_return_pressed() -> void:
	return_to_parent_menu()
	pass # Replace with function body.
