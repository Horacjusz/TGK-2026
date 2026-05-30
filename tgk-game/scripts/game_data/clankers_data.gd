extends Node
class_name ClankersData


@export var clankers_scenes: Dictionary[String, PackedScene]
@export var clankers_available: Array[String]
@export var clankers_cooldown_durations: Dictionary[String, float]


func unlock(name: String) -> void:
	if name not in clankers_available:
		clankers_available.append(name)


func unlock_all(names: Array[String]) -> void:
	for name in names:
		unlock(name)


func lock(name: String) -> void:
	clankers_available.erase(name)


func is_unlocked(name: String) -> bool:
	return name in clankers_available
