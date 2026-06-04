extends Node


var projectile_container: ProjectileContainer


func register_container(container: ProjectileContainer):
	projectile_container = container


func unregister_container(container: ProjectileContainer):
	if projectile_container == container:
		projectile_container = null


func spawn_projectile(
	projectile_scene: PackedScene,
	position: Vector2,
	rotation: float,
	data := {}
):
	if projectile_container == null:
		push_error("No projectile container registered")
		return
	
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.initialize(position, rotation, data)
	projectile_container.add_child(projectile)
	
	return projectile


func clear_projectiles() -> void:
	if not projectile_container:
		return
		
	for child in projectile_container.get_children():
		child.queue_free()
