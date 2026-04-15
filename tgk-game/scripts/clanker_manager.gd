class_name ClankerManager
extends Node

signal control_ended

@export var clanker_scenes: Array[PackedScene]
@export var clanker_cooldown_durations: Array[float]
@export var spawn_offset: Vector2 = Vector2(10, -0.5)

@onready var control_timer: Timer = %ClankerControlTimer
@onready var control_return_timer: Timer = %ControlReturnTimer

var slots: Array[Slot]
var current_clanker: Node2D = null
var spawned_clanker_index: int
var clanker_index: int = 0

func set_clanker_index(index: int) -> void:
	clanker_index = index

class Slot:
	var scene: PackedScene
	var cooldown_timer: Timer
	
	func setup(p_scene: PackedScene, cooldown_duration: float) -> void:
		scene = p_scene
		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		cooldown_timer.wait_time = cooldown_duration


func _ready() -> void:
	control_timer.timeout.connect(_on_clanker_timer_timeout)
	control_return_timer.timeout.connect(_on_control_return_timer_timeout)
	for i in clanker_scenes.size():
		var slot = Slot.new();
		slot.setup(clanker_scenes[i], clanker_cooldown_durations[i]);
		add_child(slot.cooldown_timer)
		slots.append(slot)

func _on_control_return_timer_timeout() -> void:
	control_ended.emit()

func _on_clanker_timer_timeout() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.disable_control()
	control_return_timer.start()

func spawn_clanker(direction: int, player_global_position: Vector2, parent: Node) -> void:
	despawn_clanker()
	if clanker_index < 0 or clanker_index >= clanker_scenes.size():
		return
	if slots[clanker_index].cooldown_timer.time_left > 0:
		return
	spawned_clanker_index = clanker_index
	var new_clanker = slots[clanker_index].scene.instantiate()
	var starting_position = player_global_position + Vector2(spawn_offset.x * direction, spawn_offset.y)
	new_clanker.init(starting_position, self)
	parent.add_child(new_clanker)
	current_clanker = new_clanker

func reset_clanker() -> void:
	despawn_clanker()
	control_timer.stop()
	control_return_timer.start()

func kill_clanker() -> void:
	reset_clanker()
	slots[spawned_clanker_index].cooldown_timer.start()

func despawn_clanker() -> void:
	if current_clanker and is_instance_valid(current_clanker):
		current_clanker.kill()
	current_clanker = null
