extends Node2D
class_name Level


var current_checkpoint: Checkpoint

@export var background_tilemap: TileMapLayer


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if node is Checkpoint:
			node.checkpoint_entered.connect(_on_checkpoint_entered)


func get_background_tilemap() -> TileMapLayer:
	return background_tilemap


func set_checkpoint_by_id(checkpoint_id: int) -> void:
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if node is Checkpoint and node.id == checkpoint_id:
			current_checkpoint = node
			return
	push_warning("Checkpoint not found: %s" % checkpoint_id)


func get_checkpoint_by_id(checkpoint_id: int) -> Checkpoint:
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if node is Checkpoint and node.id == checkpoint_id:
			return node
	return null


func _on_checkpoint_entered(checkpoint: Checkpoint):
	if not current_checkpoint or checkpoint.id > current_checkpoint.id:
		current_checkpoint = checkpoint
		SaveManager.save_game()
