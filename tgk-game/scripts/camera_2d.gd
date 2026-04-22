extends Camera2D

@onready var player: Player = get_parent()

func _physics_process(_delta: float) -> void:
	global_position = player.get_camera_target()


func setup_camera_limits(tilemap: TileMapLayer) -> void:
	if not tilemap:
		return
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_map_size = tilemap.tile_set.get_tile_size()
	limit_left = used_rect.position.x
	limit_top = used_rect.position.y * tile_map_size.y
	limit_right = (used_rect.position.x + used_rect.size.x) * tile_map_size.x
	limit_bottom = (used_rect.position.y + used_rect.size.y) * tile_map_size.y
