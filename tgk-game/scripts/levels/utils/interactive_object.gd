extends Area2D
class_name InteractiveObject2D

signal interacted
signal player_exited

@export_category("Setup")
@export var can_reinteract: bool = false
@export var reinteract_cooldown: float = 30.0

@onready var interact_prompt: Node2D = %InteractPrompt
@onready var cooldown_timer: Timer = $CooldownTimer

var is_disabled: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	cooldown_timer.wait_time = reinteract_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	interact_prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body is Player or is_disabled:
		return
	interact_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player_exited.emit()
	interact_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if interact_prompt.visible:
		if event.is_action_pressed("interact"):
			_on_interact()
	elif event.is_action_pressed("quit"):
		interact_prompt.visible = false
		player_exited.emit()

func _on_interact() -> void:
	interact_prompt.visible = false
	interacted.emit()

func _on_interaction_end() -> void:
	is_disabled = true
	if can_reinteract:
		cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	is_disabled = false
