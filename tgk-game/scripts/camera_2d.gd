extends Camera2D

@export_category("Follow Player")
@export var player: Player
@export_category("Camera Smoothing")
@export var smoothing_enable: bool
@export_range(1, 10) var smoothing_distance: int = 8


func _physics_process(delta: float) -> void:
	var target: Vector2 = player.get_camera_target()
	if smoothing_enable:
		target = global_position.lerp(target, (11 - smoothing_distance) * delta)
		target =(target * zoom).floor() / zoom
	global_position = target

func setup_camera_limits(tilemap: TileMapLayer) -> void:
	if not tilemap:
		return
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_map_size = tilemap.tile_set.get_tile_size()
	limit_left = used_rect.position.x
	limit_top = used_rect.position.y * tile_map_size.y
	limit_right = (used_rect.position.x + used_rect.size.x) * tile_map_size.x
	limit_bottom = (used_rect.position.y + used_rect.size.y) * tile_map_size.y
