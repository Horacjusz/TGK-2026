class_name HealthComponent
extends Node


signal health_changed(current_health: int)
signal died

@export var max_health: int = 1
@onready var current_health: int = max_health:
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health)
		if current_health <= 0:
			died.emit()


func damage(amount: int) -> void:
	current_health -= amount


func heal(amount: int) -> void:
	current_health += amount
