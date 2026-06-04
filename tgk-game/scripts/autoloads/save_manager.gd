extends Node

signal game_saved()
signal game_loaded()

const SAVE_DIR := "user://saves/"
const SAVE_FILE := SAVE_DIR + "save.dat"
const SAVABLE_GROUP := "savable"
const SAVE_VERSION := 1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func save_game(new_game: bool = false) -> bool:
	var save := {
		"meta": {
			"version": SAVE_VERSION,
			"timestamp": Time.get_unix_time_from_system()
		},
		"data": {}
	}

	for node in get_tree().get_nodes_in_group(SAVABLE_GROUP):
		if (
			not node.has_method("get_save_id")
			or not node.has_method("save_state")
		):
			continue
		
		var save_id: String = node.get_save_id()
		
		if save_id.is_empty():
			push_warning("%s has empty save ID." % node.name)
			continue
		
		save["data"][save_id] = node.save_state(new_game)
		
	
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to open save file.")
		return false
	
	file.store_var(save)
	file.close()
	
	game_saved.emit()
	return true

func load_game() -> bool:
	var data: Dictionary = {}
	
	if FileAccess.file_exists(SAVE_FILE):
		var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
		
		if file == null:
			push_error("Failed to open save file.")
			return false
		
		var save: Dictionary = file.get_var()
		file.close()
		
		if typeof(save) != TYPE_DICTIONARY:
			push_error("Invalid save format.")
			return false
		
		data = save.get("data", {})
	
	for node in get_tree().get_nodes_in_group(SAVABLE_GROUP):
		if (
			not node.has_method("get_save_id")
			or not node.has_method("load_state")
		):
			continue
		
		var save_id: String = node.get_save_id()
		
		if not data.has(save_id):
			node.load_state({})
		else:
			node.load_state(data[save_id])
	
	game_loaded.emit()
	return true


# Debug input (unchanged, simple and fine)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_save"):
		save_game(false)
	
	if event.is_action_pressed("ui_load"):
		load_game()
