extends Control
@onready var label: Label = %Label
@onready var button: TextureButton = $"."

@export var text := "TEST"

signal pressed

const margin_size = 4

func val_between(value, low, high) :
	return (
		(
			min(low, high) <= value
		) and (
			max(low, high) > value
		)
	)

func generate_textures() :
	var original_image = button.texture_normal.get_image()
	var original_size = original_image.get_size()
	var new_size = original_size + 2 * Vector2i(margin_size, margin_size) 
	
	var new_image = Image.create(new_size.x, new_size.y, false, Image.FORMAT_RGBA8)
	var hover_image = Image.create(new_size.x, new_size.y, false, Image.FORMAT_RGBA8)
	
	for x in range(new_size.x) :
		for y in range(new_size.y) :
			var local_vector = Vector2(x, y)
			var hover_pixel = Color.WHITE
			hover_pixel.a = 0.0
			for h_x in range(max(0, x - margin_size), min(new_size.x, x + margin_size)) :
				for h_y in range(max(0, y - margin_size), min(new_size.y, y + margin_size)) :
					if (
						(
							val_between(h_x, margin_size, new_size.x - margin_size)
						) and (
							val_between(h_y, margin_size, new_size.y - margin_size)
						) and (
							local_vector.distance_to(Vector2(h_x, h_y)) <= margin_size
						)
					) :
						#hover_pixel.a = max(hover_pixel.a, original_image.get_pixel(h_x - margin_size, h_y - margin_size).a)
						if original_image.get_pixel(h_x - margin_size, h_y - margin_size).a > 0 :
							hover_pixel.a = 1.0
							break
			hover_image.set_pixel(x, y, hover_pixel)
			if (
				(
					val_between(x, margin_size, new_size.x - margin_size)
				) and (
					val_between(y, margin_size, new_size.y - margin_size)
				)
			) :
				var original_pixel = original_image.get_pixel(x - margin_size, y - margin_size)
				new_image.set_pixel(x, y, original_pixel)
				if not (
						(
							val_between(x, 2 * margin_size, new_size.x - 2 * margin_size)
						) and (
							val_between(y, 2 * margin_size, new_size.y - 2 * margin_size)
						)
				) :
					original_pixel = (hover_pixel * (1 - original_pixel.a)) + (original_pixel * original_pixel.a)
				hover_image.set_pixel(x, y, original_pixel)
	
	button.texture_normal = ImageTexture.create_from_image(new_image)
	button.texture_hover = ImageTexture.create_from_image(hover_image)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#generate_textures()
	label.text = text
	label.offset_top += margin_size
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	pressed.emit()
	pass # Replace with function body.
