extends UI

@onready var options_menu: Control = $"../OptionsMenu"
@onready var credits_menu: Control = $"../Credits"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_resume_pressed() -> void:
	Globals.resume_game()
	pass # Replace with function body.


func _on_options_pressed() -> void:
	options_menu.parent_menu = self
	get_owner().change_menu(options_menu)
	pass # Replace with function body.


func _on_save_exit_pressed() -> void:
	if parent_menu == null :
		Globals.resume_game()
		return
	return_to_parent_menu()
	pass # Replace with function body.
