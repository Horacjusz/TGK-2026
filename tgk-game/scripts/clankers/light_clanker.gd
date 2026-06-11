extends Clanker
class_name LightClanker

const WORLD_LAYER := 1
const LIGHT_CLANKER_LAYER := 1 << 3
const IGNORE_SLAMMER_BODY_GROUP := "ignore_slammer_body_collision"
const SLAMMER_BODY_GROUP := "slammer_bodies"

@onready var hurt_box: HurtBox = get_node_or_null("HurtBox")


func _ready() -> void:
	add_to_group(IGNORE_SLAMMER_BODY_GROUP)
	collision_layer = LIGHT_CLANKER_LAYER
	collision_mask = WORLD_LAYER
	_disable_hurt_box_collision()
	_ignore_existing_slammer_bodies()

	super._ready()


func _disable_hurt_box_collision() -> void:
	if hurt_box == null:
		return

	hurt_box.collision_layer = 0
	hurt_box.collision_mask = 0
	hurt_box.monitoring = false
	hurt_box.monitorable = false


func _ignore_existing_slammer_bodies() -> void:
	for node in get_tree().get_nodes_in_group(SLAMMER_BODY_GROUP):
		if node is PhysicsBody2D:
			add_collision_exception_with(node)
			node.add_collision_exception_with(self)
