extends Control
@onready var options_menu: Control = $"../OptionsMenu"
@onready var credits_menu: Control = $"../Credits"

var start_menu = true
var parent_menu = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup_start_button() :
	var value = "Resume"
	if start_menu : value = "Start"
	$Start/Label.text = value
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	Globals.resume_game()
	start_menu = false
	pass # Replace with function body.


func _on_options_pressed() -> void:
	print("Options pressed")
	options_menu.parent_menu = self
	get_owner().set_menu(options_menu)
	pass # Replace with function body.


func _on_credits_pressed() -> void:
	credits_menu.parent_menu = self
	get_owner().set_menu(credits_menu)
	pass # Replace with function body.


func _on_return_pressed() -> void:
	if parent_menu == null :
		Globals.resume_game()
		return
	self.get_parent().get_owner().set_menu(self.parent_menu)
	pass # Replace with function body.
