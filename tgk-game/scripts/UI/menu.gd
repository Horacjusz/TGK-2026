extends Control
@onready var gradient: TextureRect = $Background/Gradient
@onready var reference_rect: ReferenceRect = $Buttons/ReferenceRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var start_menu: Control = $Buttons/ReferenceRect/ReferenceRect/StartMenu
@onready var buttons: Control = $Buttons
@onready var menus_level: ReferenceRect = $Buttons/ReferenceRect/ReferenceRect
@onready var main_menu: Control = $Buttons/ReferenceRect/ReferenceRect/MainMenu
@onready var hover_blocker: HoverBlocker = $HoverBlocker

signal animation_breakpoint

const gradient_offsets = [0.0, 0.4, 0.7]
const animation_speedup = 3

var current_menu

var music = null
var menu_action_id = 0

func _animation_breakpoint() :
	animation_player.pause()
	animation_breakpoint.emit()

func set_menu(new_menu, menu_show = true) :
	self.current_menu = new_menu
	hide_menus()
	if menu_show :
		self.current_menu.turn_on()

func change_menu(new_menu) :
	animation_player.play("toggle_menu")
	await animation_breakpoint
	
	self.current_menu.turn_off()
	set_menu(new_menu)
	self.current_menu.turn_on()
	
	animation_player.play()
	await animation_player.animation_finished

func hide_menus() :
	for child in menus_level.get_children() :
		child.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = animation_speedup
	set_menu(start_menu)
	pass # Replace with function body.

func setup_ui() :
	gradient.texture.width = int(get_viewport().get_visible_rect().size.x)
	gradient.texture.gradient.offsets = gradient_offsets
	
	reference_rect.anchor_left = gradient_offsets[-1]
	reference_rect.anchor_top = 0
	reference_rect.anchor_right = 1
	reference_rect.anchor_bottom = 1
	
	queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	if Input.is_action_just_pressed("pause") :
		if current_menu == main_menu :
			toggle_pause()


func toggle_pause() :
	set_menu(main_menu)
	if Globals.PAUSED :
		Globals.resume_game()
	else :
		Globals.pause_game()

func display() :
	menu_action_id += 1
	var action_id = menu_action_id
	Config.load_settings()
	setup_ui()
	show()
	if music == null :
		music = Globals.audio.loop_music(
			self,                                           # parent
			"res://assets/sounds/Girl from Petaluma.mp3",   # resource path
			100,                                            # volume
			-1,                                             # loop count (-1 means infinite)
			false,                                          # smooth start
			false,                                          # smooth_loop
			0.05                                            # smooth_factor
		)
		return
	music.set_volume(100, Globals.MENU_MUSIC_FADE_TIME)
	animation_player.play('appear')
	await animation_player.animation_finished


func retract() :
	if not self.visible : return
	menu_action_id += 1
	var action_id = menu_action_id
	music.set_volume(0, Globals.MENU_MUSIC_FADE_TIME)
	animation_player.play('disappear')
	await animation_player.animation_finished
	if action_id == menu_action_id :
		hide()

func mouse_lock(control) :
	hover_blocker.lock(control)
	
func mouse_unlock(control) :
	hover_blocker.unlock(control)
