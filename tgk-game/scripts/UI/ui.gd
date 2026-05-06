extends Control
@onready var gradient: TextureRect = $Background/Gradient
@onready var reference_rect: ReferenceRect = $Buttons/ReferenceRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const gradient_offsets = [0.0, 0.4, 0.7]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = 4
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
func _process(delta: float) -> void:
	pass

func display() :
	setup_ui()
	show()
	animation_player.play('appear')
	await animation_player.animation_finished


func retract() :
	animation_player.play('fade_away')
	await animation_player.animation_finished
	hide()


func _on_start_button_down() -> void:
	print("Pressed button")
	Globals.resume_game()
	pass # Replace with function body.
