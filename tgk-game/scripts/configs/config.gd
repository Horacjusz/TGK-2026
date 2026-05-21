extends Node

const filename = "res://settings.cfg"

func save_settings() :
	var config = ConfigFile.new()
	
	#config.set_value("video", "resolution", Globals.rendering_resolution)
	config.set_value("audio", "master", Globals.audio.master_volume)
	config.set_value("audio", "music", Globals.audio.music_volume)
	config.set_value("audio", "sfx", Globals.audio.sfx_volume)
	
	var err = config.save(filename)
	if err != OK :
		print("Error saving settings")
		

func load_settings() :
	print("loading settings")
	var config = ConfigFile.new()
	var err = config.load(filename)

	if err == OK:
		#var resolution = config.get_value("video", "resolution")
		#Globals.rendering_resolution = resolution
		Globals.audio.master_volume = config.get_value("audio", "master")
		Globals.audio.music_volume = config.get_value("audio", "music")
		Globals.audio.sfx_volume = config.get_value("audio", "sfx")
	else:
		print("No config file found, using defaults")
