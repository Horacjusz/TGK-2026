extends Area2D


signal kill_zone_entered()

@onready var timer: Timer = %Timer


func _on_body_entered(body: Node2D) -> void:
	if body is Clanker:
		body.owner_player.kill_clanker()
		return
	if body is Player:
		Engine.time_scale = 0.5
		body.get_node("CollisionShape2D").queue_free()
		timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	kill_zone_entered.emit()
