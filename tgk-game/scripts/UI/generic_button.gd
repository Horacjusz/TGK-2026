extends Control
@onready var button: TextureButton = $"."
@onready var label: Label = %Label

@export var text := "TEST"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
