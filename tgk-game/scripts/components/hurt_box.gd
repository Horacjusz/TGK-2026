class_name HurtBox
extends Area2D


signal received_damage(amount: int)

var enabled: bool = true


func take_damage(amount: int) -> void:
	received_damage.emit(amount)


func set_enabled(value: bool) -> void:
	enabled = value
	set_deferred("monitorable", enabled)
