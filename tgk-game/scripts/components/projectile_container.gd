class_name ProjectileContainer
extends Node


func _ready() -> void:
	ProjectileManager.register_container(self)


func _exit_tree() -> void:
	ProjectileManager.unregister_container(self)
