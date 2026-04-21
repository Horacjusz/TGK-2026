extends Node
@export var clanker_scenes: Dictionary[String, PackedScene]
@export var clanker_available: Array[String]
@export var clanker_cooldown_durations: Dictionary[String, float]

func unlock(name: String) -> void:
	if name not in clanker_available:
		clanker_available.append(name)
func lock(name: String) -> void:
	clanker_available.erase(name)
