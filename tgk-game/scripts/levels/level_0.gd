extends Node2D
@onready var background: TileMapLayer = %Background_body
func get_background_tilemap() -> TileMapLayer:
	return background
