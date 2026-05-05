class_name HitBox
extends Area2D


signal damaged_hurt_box(hurt_box: HurtBox)

@export var damage: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtBox:
		area.take_damage(damage)
		damaged_hurt_box.emit(area)
