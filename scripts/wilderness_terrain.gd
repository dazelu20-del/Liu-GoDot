extends StaticBody3D

## Large open-world wilderness floor: grass interior, sandy beaches, and ocean edges.

@export var world_size := Vector2(3000.0, 3000.0)
@export var beach_width := 300.0
@export var water_extension := 700.0
@export var ground_thickness := 0.5
@export var water_surface_y := -0.1
@export var pebble_count := 1800
@export var spawn_clear_radius := 28.0


func _ready() -> void:
	_build_world()
	_scatter_pebbles()


func get_world_half_extent() -> float:
	return maxf(world_size.x, world_size.y) * 0.5


func _build_world() -> void:
	var land_half_x := world_size.x * 0.5
	var land_half_z := world_size.y * 0.5
	var grass_size := Vector2(
		maxf(world_size.x - beach_width * 2.0, 100.0),
		maxf(world_size.y - beach_width * 2.0, 100.0)
	)
	var grass_half_z := grass_size.y * 0.5
	var grass_half_x := grass_size.x * 0.5

	var terrain_root := Node3D.new()
	terrain_root.name = "Terrain"
	add_child(terrain_root)

	var collision_root := Node3D.new()
	collision_root.name = "TerrainCollision"
	add_child(collision_root)

	_build_water(terrain_root, land_half_x, land_half_z)
	_build_wading_collisions(collision_root, land_half_x, land_half_z)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(grass_size.x, ground_thickness, grass_size.y),
		Vector3.ZERO,
		MeshFactory.grass_ground_material(grass_size.x / 120.0),
		"GrassInterior"
	)

	var sand_mat := MeshFactory.sand_ground_material(world_size.x / 90.0)
	var north_sand_z := grass_half_z + beach_width * 0.5
	var south_sand_z := -grass_half_z - beach_width * 0.5
	var east_sand_x := grass_half_x + beach_width * 0.5
	var west_sand_x := -grass_half_x - beach_width * 0.5

	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(world_size.x, ground_thickness, beach_width),
		Vector3(0.0, 0.0, north_sand_z),
		sand_mat,
		"SandNorth"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(world_size.x, ground_thickness, beach_width),
		Vector3(0.0, 0.0, south_sand_z),
		sand_mat,
		"SandSouth"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(beach_width, ground_thickness, grass_size.y),
		Vector3(east_sand_x, 0.0, 0.0),
		sand_mat,
		"SandEast"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(beach_width, ground_thickness, grass_size.y),
		Vector3(west_sand_x, 0.0, 0.0),
		sand_mat,
		"SandWest"
	)

	# Corner sand fills so the shoreline stays continuous.
	var corner_size := Vector2(beach_width, beach_width)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(corner_size.x, ground_thickness, corner_size.y),
		Vector3(land_half_x - corner_size.x * 0.5, 0.0, land_half_z - corner_size.y * 0.5),
		sand_mat,
		"SandCornerNE"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(corner_size.x, ground_thickness, corner_size.y),
		Vector3(-land_half_x + corner_size.x * 0.5, 0.0, land_half_z - corner_size.y * 0.5),
		sand_mat,
		"SandCornerNW"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(corner_size.x, ground_thickness, corner_size.y),
		Vector3(land_half_x - corner_size.x * 0.5, 0.0, -land_half_z + corner_size.y * 0.5),
		sand_mat,
		"SandCornerSE"
	)
	_add_ground_panel(
		terrain_root,
		collision_root,
		Vector3(corner_size.x, ground_thickness, corner_size.y),
		Vector3(-land_half_x + corner_size.x * 0.5, 0.0, -land_half_z + corner_size.y * 0.5),
		sand_mat,
		"SandCornerSW"
	)


func _build_water(terrain_root: Node3D, land_half_x: float, land_half_z: float) -> void:
	var water_root := Node3D.new()
	water_root.name = "Water"
	terrain_root.add_child(water_root)

	var water_mat := MeshFactory.water_material()
	var span_x := world_size.x + water_extension * 2.0
	var span_z := world_size.y + water_extension * 2.0

	_add_water_panel(
		water_root,
		Vector3(span_x, 0.12, water_extension),
		Vector3(0.0, water_surface_y, land_half_z + water_extension * 0.5),
		water_mat,
		"WaterNorth"
	)
	_add_water_panel(
		water_root,
		Vector3(span_x, 0.12, water_extension),
		Vector3(0.0, water_surface_y, -land_half_z - water_extension * 0.5),
		water_mat,
		"WaterSouth"
	)
	_add_water_panel(
		water_root,
		Vector3(water_extension, 0.12, world_size.y),
		Vector3(land_half_x + water_extension * 0.5, water_surface_y, 0.0),
		water_mat,
		"WaterEast"
	)
	_add_water_panel(
		water_root,
		Vector3(water_extension, 0.12, world_size.y),
		Vector3(-land_half_x - water_extension * 0.5, water_surface_y, 0.0),
		water_mat,
		"WaterWest"
	)

	# Broad outer ocean planes so the horizon keeps reading as open water.
	_add_water_panel(
		water_root,
		Vector3(span_x + 1200.0, 0.12, span_z + 1200.0),
		Vector3(0.0, water_surface_y - 0.02, 0.0),
		water_mat,
		"WaterHorizon"
	)


func _build_wading_collisions(collision_root: Node3D, land_half_x: float, land_half_z: float) -> void:
	var shelf_depth := minf(water_extension * 0.55, 380.0)
	var shelf_y := water_surface_y + 0.02
	var shelf_thickness := 0.35

	_add_wading_shelf(
		collision_root,
		Vector3(world_size.x + shelf_depth * 2.0, shelf_thickness, shelf_depth),
		Vector3(0.0, shelf_y, land_half_z + shelf_depth * 0.5),
		"WadeNorth"
	)
	_add_wading_shelf(
		collision_root,
		Vector3(world_size.x + shelf_depth * 2.0, shelf_thickness, shelf_depth),
		Vector3(0.0, shelf_y, -land_half_z - shelf_depth * 0.5),
		"WadeSouth"
	)
	_add_wading_shelf(
		collision_root,
		Vector3(shelf_depth, shelf_thickness, world_size.y),
		Vector3(land_half_x + shelf_depth * 0.5, shelf_y, 0.0),
		"WadeEast"
	)
	_add_wading_shelf(
		collision_root,
		Vector3(shelf_depth, shelf_thickness, world_size.y),
		Vector3(-land_half_x - shelf_depth * 0.5, shelf_y, 0.0),
		"WadeWest"
	)


func _add_wading_shelf(
	collision_root: Node3D,
	shelf_size: Vector3,
	shelf_position: Vector3,
	shelf_name: String
) -> void:
	var collision := CollisionShape3D.new()
	collision.name = shelf_name
	var shape := BoxShape3D.new()
	shape.size = shelf_size
	collision.shape = shape
	collision.position = shelf_position
	collision_root.add_child(collision)


func _scatter_pebbles() -> void:
	var grass_size := Vector2(
		maxf(world_size.x - beach_width * 2.0, 100.0),
		maxf(world_size.y - beach_width * 2.0, 100.0)
	)
	MeshFactory.scatter_ground_pebbles(
		self,
		grass_size,
		ground_thickness * 0.5,
		pebble_count,
		Vector2.ZERO,
		spawn_clear_radius
	)


func _add_ground_panel(
	terrain_root: Node3D,
	collision_root: Node3D,
	panel_size: Vector3,
	panel_position: Vector3,
	mat: Material,
	panel_name: String
) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = panel_name
	var box := BoxMesh.new()
	box.size = panel_size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = panel_position
	terrain_root.add_child(mesh_inst)

	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % panel_name
	var shape := BoxShape3D.new()
	shape.size = panel_size
	collision.shape = shape
	collision.position = panel_position
	collision_root.add_child(collision)


func _add_water_panel(
	water_root: Node3D,
	panel_size: Vector3,
	panel_position: Vector3,
	mat: Material,
	panel_name: String
) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = panel_name
	var box := BoxMesh.new()
	box.size = panel_size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = panel_position
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(mesh_inst)
