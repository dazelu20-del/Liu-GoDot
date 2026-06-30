extends Node3D

## Grass ground with scattered pebbles — outdoor play area only.

const GROUND_SIZE := Vector2(2000.0, 2000.0)


func _ready() -> void:
	_build_ground()


func _build_ground() -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "Terrain"
	add_child(terrain_root)

	var ground_thickness := 0.8
	var ground_top_y := ground_thickness * 0.5 - 0.4
	var grass_mat := MeshFactory.grass_ground_material(GROUND_SIZE.x / 4.0)
	var pebble_count := int(280.0 * (GROUND_SIZE.x * GROUND_SIZE.y) / (120.0 * 120.0))
	pebble_count = mini(pebble_count, 12000)

	MeshFactory.box(
		terrain_root,
		Vector3(GROUND_SIZE.x, ground_thickness, GROUND_SIZE.y),
		grass_mat,
		Vector3(0, -0.4, 0),
		Vector3.ZERO,
		"GroundBase"
	)

	MeshFactory.scatter_ground_pebbles(
		terrain_root,
		GROUND_SIZE,
		ground_top_y,
		pebble_count,
		Vector2(8.0, -5.0),
		18.0
	)

	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundCollision"
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(GROUND_SIZE.x, ground_thickness, GROUND_SIZE.y)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, -0.4, 0)
	floor_body.add_child(col_shape)
	terrain_root.add_child(floor_body)
