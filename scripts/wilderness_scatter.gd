extends Node3D

## Randomly scatters trees, boulders, mountains, and ponds across the map.

const NaturalPropScript := preload("res://scripts/natural_prop.gd")
const PondPropScript := preload("res://scripts/pond_prop.gd")

@export var scatter_seed := 37742
@export var tree_count := 140
@export var boulder_count := 70
@export var mountain_count := 10
@export var pond_count := 16
@export var scatter_radius := 420.0
@export var mountain_inner_radius := 260.0
@export var clear_center := Vector2(6.0, -4.0)
@export var clear_radius := 42.0
@export var tree_min_spacing := 9.0
@export var boulder_min_spacing := 6.0
@export var mountain_min_spacing := 110.0
@export var pond_min_spacing := 38.0
@export var props_per_frame := 6
@export var offload_distance := 200.0
@export var restore_distance := 185.0

var _scattered := false
var _placed_positions: Array[Vector2] = []


func scatter() -> void:
	if _scattered:
		return
	_scattered = true
	call_deferred("_scatter_async")


func _scatter_async() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	_placed_positions.clear()

	await _scatter_mountains(rng)
	await _scatter_props(rng, NaturalPropScript.TYPE_TREE, tree_count, tree_min_spacing)
	await _scatter_props(rng, NaturalPropScript.TYPE_BOULDER, boulder_count, boulder_min_spacing)
	await _scatter_ponds(rng)


func _scatter_mountains(rng: RandomNumberGenerator) -> void:
	var spawned := 0
	var attempts := 0
	var max_attempts := mountain_count * 40

	while spawned < mountain_count and attempts < max_attempts:
		attempts += 1
		var pos := _pick_ring_position(rng, mountain_inner_radius, scatter_radius, mountain_min_spacing)
		if pos == Vector2.INF:
			continue

		var prop := Node3D.new()
		prop.name = "Mountain_%d" % spawned
		prop.set_script(NaturalPropScript)
		prop.position = Vector3(pos.x, 0.0, pos.y)
		add_child(prop)

		var scale := rng.randf_range(0.85, 1.15)
		prop.configure(NaturalPropScript.TYPE_MOUNTAIN, scale, rng.randf_range(0.0, TAU))
		prop.offload_distance = offload_distance + 80.0
		prop.restore_distance = restore_distance + 60.0
		prop.build()

		_placed_positions.append(pos)
		spawned += 1
		if spawned % props_per_frame == 0:
			await get_tree().process_frame


func _scatter_props(
	rng: RandomNumberGenerator,
	prop_type: int,
	count: int,
	min_spacing: float
) -> void:
	var spawned := 0
	var attempts := 0
	var max_attempts := count * 30

	while spawned < count and attempts < max_attempts:
		attempts += 1
		var pos := _pick_position(rng, min_spacing)
		if pos == Vector2.INF:
			continue

		var prop := Node3D.new()
		match prop_type:
			NaturalPropScript.TYPE_BOULDER:
				prop.name = "Boulder_%d" % spawned
			_:
				prop.name = "Tree_%d" % spawned
		prop.set_script(NaturalPropScript)
		prop.position = Vector3(pos.x, 0.0, pos.y)
		add_child(prop)

		var scale := rng.randf_range(0.82, 1.28)
		if prop_type == NaturalPropScript.TYPE_BOULDER:
			scale = rng.randf_range(0.7, 1.45)
		prop.configure(prop_type, scale, rng.randf_range(0.0, TAU))
		prop.offload_distance = offload_distance
		prop.restore_distance = restore_distance
		prop.build()

		_placed_positions.append(pos)
		spawned += 1
		if spawned % props_per_frame == 0:
			await get_tree().process_frame


func _scatter_ponds(rng: RandomNumberGenerator) -> void:
	var spawned := 0
	var attempts := 0
	var max_attempts := pond_count * 40

	while spawned < pond_count and attempts < max_attempts:
		attempts += 1
		var pos := _pick_position(rng, pond_min_spacing)
		if pos == Vector2.INF:
			continue

		var pond := Node3D.new()
		pond.name = "Pond_%d" % spawned
		pond.set_script(PondPropScript)
		pond.position = Vector3(pos.x, 0.0, pos.y)
		add_child(pond)

		var radius := rng.randf_range(4.5, 8.5)
		pond.configure(radius, rng.randf_range(0.0, TAU))
		pond.offload_distance = offload_distance
		pond.restore_distance = restore_distance
		pond.build()

		_placed_positions.append(pos)
		spawned += 1
		if spawned % props_per_frame == 0:
			await get_tree().process_frame


func _pick_position(rng: RandomNumberGenerator, min_spacing: float) -> Vector2:
	for _attempt: int in 24:
		var pos := Vector2(
			rng.randf_range(-scatter_radius, scatter_radius),
			rng.randf_range(-scatter_radius, scatter_radius)
		)
		if pos.length() > scatter_radius:
			continue
		if pos.distance_to(clear_center) < clear_radius:
			continue
		if _is_too_close(pos, min_spacing):
			continue
		return pos
	return Vector2.INF


func _pick_ring_position(
	rng: RandomNumberGenerator,
	inner_radius: float,
	outer_radius: float,
	min_spacing: float
) -> Vector2:
	for _attempt: int in 24:
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(inner_radius, outer_radius)
		var pos := Vector2(cos(angle) * radius, sin(angle) * radius)
		if pos.distance_to(clear_center) < clear_radius + 80.0:
			continue
		if _is_too_close(pos, min_spacing):
			continue
		return pos
	return Vector2.INF


func _is_too_close(pos: Vector2, min_spacing: float) -> bool:
	for existing: Vector2 in _placed_positions:
		if pos.distance_to(existing) < min_spacing:
			return true
	return false
