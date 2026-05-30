extends Node2D
class_name Level


var current_checkpoint_id: String = ""

@export var background_tilemap: TileMapLayer


func get_background_tilemap() -> TileMapLayer:
	return background_tilemap


func set_checkpoint(checkpoint_id: String) -> void:
	current_checkpoint_id = checkpoint_id


func get_checkpoint(checkpoint_id: String) -> Checkpoint:
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if node is Checkpoint and node.id == checkpoint_id:
			return node
	return null
