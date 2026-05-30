extends UI

@onready var options_menu: Control = $"../OptionsMenu"
@onready var credits_menu: Control = $"../Credits"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	Globals.resume_game()
	SaveManager.save_game(true)
	SaveManager.load_game()
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
	return_to_parent_menu()
	pass # Replace with function body.
