extends Projectile


@export var default_damage: int = 1
@export var default_speed: float = 100.0

var damage: int
var speed: float


func _ready() -> void:
	damage = default_damage
	speed = default_speed


func _process(delta: float):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta


func initialize(
	initial_position: Vector2,
	initial_rotation := 0.0,
	data := {}
):
	super.initialize(
		initial_position,
		initial_rotation,
	)
	speed = data.get("speed", default_speed)
	damage = data.get("damage", default_damage)


func destroy():
	queue_free()


func _on_body_entered(_body: Node2D):
	# Hit a wall
	destroy()


func _on_hit_box_damaged_hurt_box(hurt_box: HurtBox) -> void:
	# Hit an enemy
	destroy()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
