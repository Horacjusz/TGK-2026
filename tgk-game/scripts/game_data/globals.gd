extends Node

var rendering_resolution = null

func rescale_window() :
	if rendering_resolution == null :
		rendering_resolution = DisplayServer.window_get_size()
	print(rendering_resolution)
	pass
