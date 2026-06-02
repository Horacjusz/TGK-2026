extends Area2D
class_name Interactable


signal interacted
signal cooldown_finished

@export_category("Setup")
@export var can_reinteract: bool = true
@export var reinteract_cooldown: float = 1.0
@export var text: String = "Interact"

@onready var cooldown_timer: Timer = $CooldownTimer

var is_disabled: bool = false


func interact() -> void:
	is_disabled = true
	interacted.emit()
	
	if can_reinteract:
		if reinteract_cooldown > 0.0:
			cooldown_timer.wait_time = reinteract_cooldown
			cooldown_timer.start()
		else:
			_handle_cooldown_finished()


func _handle_cooldown_finished() -> void:
	is_disabled = false
	cooldown_finished.emit()


func _on_cooldown_timer_timeout() -> void:
	_handle_cooldown_finished()
