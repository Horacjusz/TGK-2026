class_name Player
extends CharacterBody2D


signal died


@onready var animation_tree: AnimationTree = %AnimationTree
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var jump_component: JumpComponent = %JumpComponent
@onready var gravity_component: GravityComponent = %GravityComponent
@onready var clanker_spawner_component: ClankerSpawnerComponent = %ClankerSpawnerComponent


func _physics_process(delta: float) -> void:
	input_component.update()
	gravity_component.handle_gravity(delta)
	
	clanker_spawner_component.handle_clanker_input(
		input_component.clanker_pressed, 
		input_component.reset_clanker_pressed
	)
	
	if clanker_spawner_component.is_controlling_clanker:
		movement_component.handle_movement(0, delta)
	else:
		movement_component.handle_movement(input_component.move_axis, delta)
		jump_component.handle_jump(input_component.jump_pressed, input_component.jump_released)
	
	animation_tree.set("parameters/Airborne/blend_position", velocity.y)
	
	move_and_slide()


func die() -> void:
	collision_shape.set_deferred("disabled", true) # Use set_deferred for physics
	died.emit()
