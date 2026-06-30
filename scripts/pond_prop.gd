extends Node3D

## Pond with a muddy base, imported water surface, and view-aware offloading.

const WATER_MODEL := preload("res://assets/Pond/ga_free_151_forgotten_sanctuary_lake.glb")
const ContentOffloaderScript := preload("res://scripts/content_offloader.gd")

@export var pond_radius := 6.0
@export var offload_distance := 200.0
@export var restore_distance := 185.0

var _content: Node3D
var _collision_body: StaticBody3D
var _offloader: Node
var _y_rotation := 0.0


func configure(radius: float, y_rotation: float) -> void:
	pond_radius = radius
	_y_rotation = y_rotation


func build() -> void:
	_ensure_content()
	_build_content()
	_build_collision()
	_setup_offloader()


func _ensure_content() -> void:
	_content = get_node_or_null("Content") as Node3D
	if _content == null:
		_content = Node3D.new()
		_content.name = "Content"
		add_child(_content)


func _build_content() -> void:
	for child: Node in _content.get_children():
		child.queue_free()

	_content.rotation = Vector3.ZERO
	_content.rotate_y(_y_rotation)

	var mud_mat := MeshFactory.material(Color(0.24, 0.19, 0.13), 0.96)
	var rim_mat := MeshFactory.material(Color(0.34, 0.3, 0.22), 0.92)
	var floor_thickness := 0.08
	var rim_height := 0.22
	var rim_center_y := 0.14
	var water_surface_y := 0.17

	MeshFactory.cylinder(
		_content,
		pond_radius * 1.05,
		pond_radius * 1.12,
		rim_height,
		rim_mat,
		Vector3(0.0, rim_center_y, 0.0),
		Vector3.ZERO,
		"PondRim"
	)
	MeshFactory.cylinder(
		_content,
		pond_radius * 0.96,
		pond_radius * 0.96,
		floor_thickness,
		mud_mat,
		Vector3(0.0, floor_thickness * 0.5, 0.0),
		Vector3.ZERO,
		"PondBasin"
	)

	var water := WATER_MODEL.instantiate() as Node3D
	water.name = "WaterModel"
	_content.add_child(water)
	_apply_water_material(water)
	call_deferred("_fit_water_model", water, water_surface_y)


func _apply_water_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		mesh_inst.material_override = MeshFactory.water_material()
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_apply_water_material(child)


func _fit_water_model(water: Node3D, surface_y: float) -> void:
	if not is_instance_valid(water):
		return

	water.rotation = Vector3.ZERO
	water.position = Vector3.ZERO
	water.scale = Vector3.ONE

	var aabb := _get_local_mesh_aabb(water)
	if aabb.size == Vector3.ZERO:
		_add_procedural_water(surface_y)
		water.queue_free()
		return

	var xz_span := maxf(aabb.size.x, aabb.size.z)
	if xz_span < 0.01:
		_add_procedural_water(surface_y)
		water.queue_free()
		return

	var xz_fit := (pond_radius * 1.92) / xz_span
	var target_depth := 0.12
	var y_fit := target_depth / maxf(aabb.size.y, 0.01)
	water.scale = Vector3(xz_fit, y_fit, xz_fit)

	aabb = _get_local_mesh_aabb(water)
	var water_center_y := aabb.position.y + aabb.size.y * 0.5
	water.position.y = surface_y - water_center_y


func _add_procedural_water(surface_y: float) -> void:
	var depth := 0.12
	MeshFactory.box(
		_content,
		Vector3(pond_radius * 1.85, depth, pond_radius * 1.85),
		MeshFactory.water_material(),
		Vector3(0.0, surface_y - depth * 0.5, 0.0),
		Vector3.ZERO,
		"WaterFallback"
	)


func _setup_offloader() -> void:
	if _offloader and is_instance_valid(_offloader):
		_offloader.queue_free()

	_offloader = ContentOffloaderScript.new()
	_offloader.name = "ContentOffloader"
	_offloader.content_root = NodePath("Content")
	_offloader.replace_entire_root = false
	_offloader.view_aware_offload = true
	_offloader.auto_offload_distance = offload_distance
	_offloader.auto_restore_distance = restore_distance
	add_child(_offloader)
	_offloader.content_offloaded.connect(_on_content_offloaded)
	_offloader.content_restored.connect(_on_content_restored)


func _on_content_offloaded() -> void:
	_clear_collision()


func _on_content_restored() -> void:
	_build_content()
	call_deferred("_build_collision")


func _build_collision() -> void:
	_clear_collision()
	_ensure_content()

	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	_content.add_child(body)
	_collision_body = body

	var wall_height := 0.55
	var wall_thickness := 0.45
	var outer_radius := pond_radius * 1.12
	var segments := 12

	for i: int in segments:
		var angle := (float(i) / float(segments)) * TAU
		var next_angle := (float(i + 1) / float(segments)) * TAU
		var mid_angle := (angle + next_angle) * 0.5
		var arc_width := outer_radius * (next_angle - angle) + wall_thickness

		var shape := BoxShape3D.new()
		shape.size = Vector3(wall_thickness, wall_height, maxf(arc_width, 0.8))
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = Vector3(
			cos(mid_angle) * outer_radius,
			wall_height * 0.5,
			sin(mid_angle) * outer_radius
		)
		col.rotation = Vector3(0.0, -mid_angle, 0.0)
		body.add_child(col)


func _clear_collision() -> void:
	if _collision_body and is_instance_valid(_collision_body):
		_collision_body.queue_free()
	_collision_body = null


func _get_local_mesh_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for mesh_inst: MeshInstance3D in _find_mesh_instances(root):
		var mesh_aabb: AABB = (
			root.global_transform.affine_inverse()
			* mesh_inst.global_transform
			* mesh_inst.get_aabb()
		)
		if first:
			merged = mesh_aabb
			first = false
		else:
			merged = merged.merge(mesh_aabb)
	return merged


func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child: Node in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result
