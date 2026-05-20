class_name HurtBox
extends Area2D


signal received_damage(amount: int)


func take_damage(amount: int) -> void:
	received_damage.emit(amount)
