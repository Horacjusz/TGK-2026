extends UI

@onready var main_menu: Control = $"../MainMenu"
@onready var options_menu: Control = $"../OptionsMenu"
@onready var credits_menu: Control = $"../Credits"
@onready var entry_image: TextureRect = $"../../../../Background/EntryImage"

func turn_on() :
	self.entry_image.show()
	super.turn_on()
	
func turn_off() :
	super.turn_off()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_continue_pressed() -> void:
	self.entry_image.hide()
	Globals.resume_game()
	main_menu.parent_menu = self
	get_owner().set_menu(main_menu)
	pass # Replace with function body.

func _on_new_game_pressed() -> void:
	_on_continue_pressed()
	pass # Replace with function body.

func _on_options_pressed() -> void:
	options_menu.parent_menu = self
	get_owner().change_menu(options_menu)
	pass # Replace with function body.


func _on_credits_pressed() -> void:
	credits_menu.parent_menu = self
	get_owner().change_menu(credits_menu)
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
