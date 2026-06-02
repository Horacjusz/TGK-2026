extends Area2D
class_name Interactor


var can_interact: bool = true
var interactables: Array[Interactable] = []
var current_interactable: Interactable = null


func set_can_interact(value: bool) -> void:
	can_interact = value
	_update_current_interactable()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interactables:
		_on_interact()


func _on_interact() -> void:
	if current_interactable:
		current_interactable.interact()
		_update_current_interactable()


func _update_current_interactable():
	if !can_interact:
		current_interactable = null
		GlobalSignalBus.interaction_hud_hidden.emit()
		return
	
	var closest_interactable: Interactable = null
	var min_distance = INF
	
	for interactable in interactables:
		if interactable.is_disabled: continue
		
		var distance = global_position.distance_to(interactable.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_interactable = interactable
			
	if closest_interactable != current_interactable:
		current_interactable = closest_interactable
		if current_interactable:
			GlobalSignalBus.interaction_hud_shown.emit(current_interactable.text)
		else:
			GlobalSignalBus.interaction_hud_hidden.emit()


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		interactables.append(area)
		area.cooldown_finished.connect(_on_interactable_cooldown_finished)
		_update_current_interactable()


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		interactables.erase(area)
		if area.cooldown_finished.is_connected(_on_interactable_cooldown_finished):
			area.cooldown_finished.disconnect(_on_interactable_cooldown_finished)
		_update_current_interactable()


func _on_interactable_cooldown_finished():
	_update_current_interactable()
