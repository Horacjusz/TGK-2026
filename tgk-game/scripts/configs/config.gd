extends Node

const filename = "res://settings.cfg"

func save_settings() :
	var config = ConfigFile.new()
	
	config.set_value("video", "resolution", Globals.rendering_resolution)
	
	var err = config.save(filename)
	if err != OK :
		print("Error saving settings")
		

func load_settings() :
	var config = ConfigFile.new()
	var err = config.load(filename)

	if err == OK:
		var resolution = config.get_value("video", "resolution")
		Globals.rendering_resolution = resolution
	else:
		print("No config file found, using defaults")
