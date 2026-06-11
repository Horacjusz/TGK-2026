extends Polygon2D
class_name DarknessZone

@onready var light_occluder: LightOccluder2D = $LightOccluder2D


const MAX_LIGHTS := 16
const MAX_ZONE_POINTS := 64
const DARKNESS_SHADER := preload("res://shaders/components/darkness_zone.gdshader")

@export var darkness_color := Color.BLACK
@export var darkness_z_index := 1000
@export_range(0.0, 256.0, 1.0) var fade_distance := 8.0
@export var shader_render_rect := Rect2(-4096.0, -4096.0, 8192.0, 8192.0)
@export var block_native_lights := false
@export_flags_2d_render var native_light_occluder_mask := 1
@export var light_radius_fallback := 96.0
@export var light_radius_multiplier := 1.0
@export_range(0.0, 0.95, 0.01) var inner_radius_ratio := 0.15
@export_range(1, MAX_LIGHTS, 1) var max_lights := MAX_LIGHTS
@export var scan_root_path: NodePath

var shader_material: ShaderMaterial
var source_polygon := PackedVector2Array()


func _ready() -> void:
	source_polygon = polygon
	light_occluder.occluder.polygon = source_polygon
	light_occluder.occluder_light_mask = native_light_occluder_mask if block_native_lights else 0
	
	z_index = darkness_z_index
	z_as_relative = false
	color = Color.WHITE
	polygon = _get_rect_polygon(shader_render_rect)
	_setup_shader()
	update_darkness()


func _process(_delta: float) -> void:
	update_darkness()


func update_darkness() -> void:
	if shader_material == null:
		return

	var light_positions := PackedVector2Array()
	var light_radii := PackedFloat32Array()
	var light_strengths := PackedFloat32Array()
	var light_count := 0

	for light in _get_local_lights():
		if light_count >= max_lights:
			break
		if not is_instance_valid(light) or not light.enabled:
			continue

		light_positions.append(_get_light_screen_position(light))
		light_radii.append(_get_light_screen_radius(light))
		light_strengths.append(_get_light_strength(light))
		light_count += 1

	while light_positions.size() < MAX_LIGHTS:
		light_positions.append(Vector2.ZERO)
		light_radii.append(0.0)
		light_strengths.append(0.0)

	shader_material.set_shader_parameter("darkness_color", darkness_color)
	shader_material.set_shader_parameter("fade_distance", fade_distance)
	shader_material.set_shader_parameter("inner_radius_ratio", inner_radius_ratio)
	shader_material.set_shader_parameter("light_count", light_count)
	shader_material.set_shader_parameter("light_positions", light_positions)
	shader_material.set_shader_parameter("light_radii", light_radii)
	shader_material.set_shader_parameter("light_strengths", light_strengths)
	_update_zone_shape_shader_parameters()


func _setup_shader() -> void:
	if shader_material != null:
		return

	shader_material = ShaderMaterial.new()
	shader_material.shader = DARKNESS_SHADER
	material = shader_material
	_update_zone_shape_shader_parameters()


func _update_zone_shape_shader_parameters() -> void:
	if shader_material == null:
		return

	var zone_points := PackedVector2Array()
	var point_count: int = mini(source_polygon.size(), MAX_ZONE_POINTS)

	for i in point_count:
		zone_points.append(source_polygon[i])

	while zone_points.size() < MAX_ZONE_POINTS:
		zone_points.append(Vector2.ZERO)

	shader_material.set_shader_parameter("zone_point_count", point_count)
	shader_material.set_shader_parameter("zone_points", zone_points)


func _get_rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])


func _get_local_lights() -> Array[Light2D]:
	var root := get_node_or_null(scan_root_path)
	if root == null:
		root = get_tree().current_scene
	if root == null:
		root = get_tree().root

	var result: Array[Light2D] = []
	if root != null:
		_collect_lights(root, result)
	return result


func _collect_lights(node: Node, result: Array[Light2D]) -> void:
	if node is Light2D and not node is DirectionalLight2D:
		result.append(node)

	for child in node.get_children():
		_collect_lights(child, result)


func _get_light_screen_position(light: Light2D) -> Vector2:
	return light.get_global_transform_with_canvas().origin


func _get_light_screen_radius(light: Light2D) -> float:
	var canvas_scale := _get_max_canvas_scale(light)

	if light is PointLight2D and light.texture:
		var texture_size: Vector2 = light.texture.get_size()
		var texture_radius: float = max(texture_size.x, texture_size.y) * 0.5
		return texture_radius * light.texture_scale * canvas_scale * light_radius_multiplier

	return light_radius_fallback * canvas_scale * light_radius_multiplier


func _get_light_strength(light: Light2D) -> float:
	return max(light.energy, 0.0)


func _get_max_canvas_scale(node: Node2D) -> float:
	var scale := node.get_global_transform_with_canvas().get_scale()
	return max(max(abs(scale.x), abs(scale.y)), 0.001)
