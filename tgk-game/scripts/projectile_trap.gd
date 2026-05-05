extends Node2D

@export var projectile_scene: PackedScene
@onready var projectile_spawn_marker: Marker2D = %ProjectileSpawnMarker


func shoot():
	if not projectile_scene:
		return
	
	ProjectileManager.spawn_projectile(
		projectile_scene,
		projectile_spawn_marker.global_position,
		global_rotation,
	)


func _on_projectile_spawn_timer_timeout() -> void:
	shoot()
