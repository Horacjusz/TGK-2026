extends Control
@onready var background: TextureRect = $Background


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Config.load_settings()
	Globals.rescale_window()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
