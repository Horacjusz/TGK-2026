class_name Player
extends CharacterBody2D


signal died


@onready var animation_tree: AnimationTree = %AnimationTree
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var jump_component: JumpComponent = %JumpComponent
@onready var gravity_component: GravityComponent = %GravityComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var clanker_manager_component: ClankerManagerComponent = %ClankerManagerComponent
@onready var spawn_ray: RayCast2D = %RayCast2D

var is_controlling_clanker: bool = false


func _on_clanker_control_started() -> void:
	is_controlling_clanker = true

func _on_clanker_control_ended() -> void:
	is_controlling_clanker = false

func _physics_process(delta: float) -> void:
	input_component.update()
	spawn_ray.force_raycast_update()
	gravity_component.handle_gravity(delta)
	clanker_manager_component.handle_clanker_input(
		input_component.clanker_pressed, 
		spawn_ray.is_colliding(),
		input_component.reset_clanker_pressed,
		input_component.selected_slot
	)
	
	if is_controlling_clanker:
		movement_component.handle_movement(0, delta)
	else:
		movement_component.handle_movement(input_component.move_axis, delta)
		jump_component.handle_jump(input_component.jump_pressed, input_component.jump_released)
	
	animation_tree.set("parameters/Airborne/blend_position", velocity.y)
	
	move_and_slide()

func get_camera_target() -> Vector2:
	if is_controlling_clanker and clanker_manager_component.current_clanker and is_instance_valid(clanker_manager_component.current_clanker):
		return clanker_manager_component.current_clanker.global_position
	return global_position

func die() -> void:
	collision_shape.set_deferred("disabled", true) # Use set_deferred for physics
	died.emit()


func _on_hurt_box_received_damage(amount) -> void:
	health_component.damage(amount)


func _on_health_component_health_changed(current_health: int) -> void:
	pass


func _on_health_component_died() -> void:
	die()
