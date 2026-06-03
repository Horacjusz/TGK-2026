extends Control


var tween: Tween

@onready var color_rect: ColorRect = %ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect.color.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	GlobalSignalBus.loading_screen_shown.connect(
		_on_loading_screen_shown
	)
	GlobalSignalBus.loading_screen_hidden.connect(
		_on_loading_screen_hidden
	)


func _on_loading_screen_shown(duration: float = 0.1) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	# Block mouse inputs so the player can't click menus mid-transition
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1.0, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)


func _on_loading_screen_hidden(duration: float = 0.1) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 0.0, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	
	# Stop blocking inputs once the screen is completely revealed again
	tween.finished.connect(func(): mouse_filter = Control.MOUSE_FILTER_IGNORE)
