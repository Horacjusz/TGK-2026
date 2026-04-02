# death_effect.gd
class_name DeathEffect
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var anim_name: String = "default"

func _ready() -> void:
	animated_sprite.play(anim_name)
	animated_sprite.animation_finished.connect(queue_free)
