extends Node2D


signal reset_level()


func _on_kill_zone_kill_zone_entered() -> void:
	print("dsa")
	reset_level.emit()
