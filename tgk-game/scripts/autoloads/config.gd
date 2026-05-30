extends Node

const SETTINGS_DIR := "user://settings/"
const SETTINGS_FILE := SETTINGS_DIR + "settings.cfg"

func save_settings():
	DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)

	var config = ConfigFile.new()

	if Globals.audio != null:
		config.set_value("audio", "master", Globals.audio.master_volume)
		config.set_value("audio", "music", Globals.audio.music_volume)
		config.set_value("audio", "sfx", Globals.audio.sfx_volume)

	var err = config.save(SETTINGS_FILE)
	if err != OK:
		push_error("Error saving settings")


func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)

	if err != OK:
		print("No config file found, creating defaults")
		save_settings()

		# ponowna próba wczytania świeżo utworzonego pliku
		err = config.load(SETTINGS_FILE)
		if err != OK:
			push_error("Failed to create settings file")
			return

	if Globals.audio != null:
		Globals.audio.master_volume = config.get_value(
			"audio", "master", Globals.audio.master_volume
		)
		Globals.audio.music_volume = config.get_value(
			"audio", "music", Globals.audio.music_volume
		)
		Globals.audio.sfx_volume = config.get_value(
			"audio", "sfx", Globals.audio.sfx_volume
		)
