extends Node3D

## Crash-site wilderness environment with realistic wreckage and forest shelter.
## Replaces the flat placeholder baseplate for post-intro gameplay.
## See docs/model-build-guide.md for high-poly asset specifications.


func _ready() -> void:
	_build_terrain()
	_build_flight_377_wreck()
	_build_scattered_debris()
	_build_forest()
	_build_ranger_station()


# Boeing 737-800 class proportions (meters, 1 unit = 1 m)
const FUSE_RADIUS := 1.88
const FUSE_DIAMETER := FUSE_RADIUS * 2.0
const BELLY_Y := FUSE_RADIUS
const AXIS_ROLL := Vector3(0, 0, PI * 0.5)  # Cylinder Y-axis → fuselage X-axis


func _build_flight_377_wreck() -> void:
	var wreck := Node3D.new()
	wreck.name = "Flight377Wreck"
	wreck.position = Vector3(6, 0, -4)
	wreck.rotation_degrees = Vector3(3, -18, 4)
	add_child(wreck)

	var hull := MeshFactory.weathered_hull(Color(0.72, 0.74, 0.76))
	var hull_moss := MeshFactory.moss_weathered(Color(0.62, 0.66, 0.6))
	var hull_dark := MeshFactory.weathered_hull(Color(0.55, 0.56, 0.58), Color(0.35, 0.38, 0.34))
	var char_mat := MeshFactory.material(Color(0.12, 0.1, 0.09), 0.95)
	var frame_mat := MeshFactory.metal(Color(0.48, 0.5, 0.52), 0.5)
	var interior_mat := MeshFactory.fabric(Color(0.18, 0.22, 0.32))
	var wing_mat := MeshFactory.weathered_hull(Color(0.68, 0.7, 0.72))
	var engine_mat := MeshFactory.metal(Color(0.5, 0.52, 0.54), 0.55)
	var tail_orange := MeshFactory.weathered_hull(Color(0.78, 0.55, 0.22))
	var window_dark := MeshFactory.material(Color(0.08, 0.1, 0.12), 0.2, 0.1)
	var livery_red := MeshFactory.material(Color(0.45, 0.22, 0.16), 0.9, 0.05)
	var rust := MeshFactory.rust_patch()

	# --- Fuselage (horizontal on belly, nose toward +X) ---
	# Forward section: nose through wing root
	_fuselage_tube(wreck, 17.0, 9.5, hull, "FuselageForward")
	# Aft section: separated at break, dropped slightly
	var aft := Node3D.new()
	aft.name = "FuselageAft"
	aft.position = Vector3(-1.2, -0.35, 0.15)
	aft.rotation_degrees = Vector3(0, 6, -2)
	wreck.add_child(aft)
	_fuselage_tube(aft, 14.0, -7.5, hull_dark, "FuselageAftHull")

	# Nose cone — tapered 737 radome
	MeshFactory.cylinder(
		wreck, 0.15, FUSE_RADIUS, 5.5, hull,
		Vector3(19.5, BELLY_Y, 0), AXIS_ROLL, "NoseCone"
	)
	MeshFactory.cylinder(
		wreck, 0.08, 0.35, 1.2, hull,
		Vector3(22.0, BELLY_Y + 0.15, 0), AXIS_ROLL, "NoseTip"
	)

	# Cockpit windshield band (upper forward fuselage)
	MeshFactory.box(
		wreck, Vector3(2.2, 0.55, FUSE_DIAMETER - 0.2), window_dark,
		Vector3(17.8, BELLY_Y + 0.85, 0), Vector3(0, 0, -0.12), "CockpitGlass"
	)
	for i: int in 4:
		MeshFactory.box(
			wreck, Vector3(0.35, 0.22, 0.04), window_dark,
			Vector3(16.8 + i * 0.45, BELLY_Y + 1.05, FUSE_RADIUS - 0.08),
			Vector3(-0.35, 0, 0), "CockpitWindow"
		)

	# Passenger window row (starboard side, visible from approach angle)
	for win_i: int in 18:
		var wx: float = 15.0 - win_i * 1.55
		if wx < -4.0:
			continue
		var win_mat: Material = window_dark if win_i % 5 != 0 else rust
		MeshFactory.box(
			wreck, Vector3(0.32, 0.38, 0.05), win_mat,
			Vector3(wx, BELLY_Y + 0.55, FUSE_RADIUS - 0.02), Vector3.ZERO, "PassengerWindow"
		)

	# Fuselage break behind wings — jagged tear + exposed ribs
	for rib_i: int in 7:
		var rib_x: float = 0.8 - rib_i * 0.22
		MeshFactory.box(
			wreck, Vector3(0.05, 1.5, 0.1), frame_mat,
			Vector3(rib_x, BELLY_Y, 0.4), Vector3(0, 0, 0.35), "ExposedRib"
		)
		MeshFactory.box(
			wreck, Vector3(0.04, 1.2, 0.06), interior_mat,
			Vector3(rib_x, BELLY_Y - 0.1, 0.15)
		)
	# Torn skin flap hanging at break
	MeshFactory.box(
		wreck, Vector3(1.8, 1.4, 0.06), hull_moss,
		Vector3(0.5, BELLY_Y + 0.2, FUSE_RADIUS + 0.5), Vector3(0, 0.4, 0.8), "TornSkinFlap"
	)
	MeshFactory.box(
		wreck, Vector3(1.2, 0.8, 0.05), char_mat,
		Vector3(1.0, BELLY_Y - 0.3, -FUSE_RADIUS - 0.2), Vector3(0.2, -0.3, 0), "BentPanel"
	)

	# Moss / grime streaks on upper fuselage
	for streak_i: int in 6:
		MeshFactory.box(
			wreck, Vector3(4.5, 0.08, 0.35), hull_moss,
			Vector3(12.0 - streak_i * 4.5, BELLY_Y + FUSE_RADIUS - 0.05, 0.2),
			Vector3(0, 0, 0.1), "MossStreak"
		)
	for rust_i: int in 4:
		MeshFactory.box(
			wreck, Vector3(1.5, 0.6, 0.04), rust,
			Vector3(6.0 - rust_i * 5.0, BELLY_Y + 0.3, FUSE_RADIUS - 0.01)
		)

	# Airline livery — "SURVIVE" + "FLIGHT 377" distressed panels
	MeshFactory.box(wreck, Vector3(5.5, 0.9, 0.03), livery_red, Vector3(8.0, BELLY_Y + 0.15, FUSE_RADIUS + 0.02), Vector3.ZERO, "LiveryTitle")
	MeshFactory.box(wreck, Vector3(3.2, 0.45, 0.03), livery_red, Vector3(8.0, BELLY_Y - 0.35, FUSE_RADIUS + 0.02), Vector3.ZERO, "LiverySubtitle")
	MeshFactory.box(wreck, Vector3(1.4, 0.18, 0.02), MeshFactory.plastic(Color(0.2, 0.2, 0.22)), Vector3(18.5, BELLY_Y + 0.5, FUSE_RADIUS + 0.02), Vector3.ZERO, "ModelBadge")

	# --- Low wings (737 low-wing mount) ---
	var wing_root_x := 5.0
	var wing_y := BELLY_Y - 0.55
	# Left wing (port) — extends toward -Z, visible in scene
	MeshFactory.box(
		wreck, Vector3(3.8, 0.22, 11.0), wing_mat,
		Vector3(wing_root_x, wing_y, -5.8), Vector3(0, 0, 0.06), "LeftWing"
	)
	MeshFactory.box(
		wreck, Vector3(1.4, 0.14, 2.4), wing_mat,
		Vector3(wing_root_x - 1.8, wing_y - 0.05, -10.5), Vector3(0, 0, 0.35), "LeftWingTip"
	)
	# Right wing — partially buried in terrain
	MeshFactory.box(
		wreck, Vector3(3.5, 0.2, 5.0), wing_mat,
		Vector3(wing_root_x, wing_y - 0.45, 3.2), Vector3(0.35, 0, -0.15), "RightWingBuried"
	)
	# Wing fairing / root glove
	MeshFactory.box(
		wreck, Vector3(2.0, 0.5, FUSE_DIAMETER + 0.4), hull,
		Vector3(wing_root_x, wing_y + 0.35, 0), Vector3.ZERO, "WingFairing"
	)

	# CFM56-style engine nacelle under left wing
	var engine_pos := Vector3(wing_root_x + 0.5, 0.55, -4.5)
	MeshFactory.cylinder(wreck, 1.05, 1.1, 3.2, engine_mat, engine_pos, AXIS_ROLL, "EngineIntake")
	MeshFactory.cylinder(
		wreck, 0.85, 0.9, 2.4, engine_mat,
		Vector3(engine_pos.x - 2.8, engine_pos.y, engine_pos.z), AXIS_ROLL, "EngineCore"
	)
	MeshFactory.cylinder(
		wreck, 0.55, 0.75, 1.2, char_mat,
		Vector3(engine_pos.x - 4.0, engine_pos.y - 0.05, engine_pos.z), AXIS_ROLL, "EngineExhaust"
	)
	MeshFactory.box(
		wreck, Vector3(0.15, 1.0, 0.8), engine_mat,
		Vector3(wing_root_x + 0.3, wing_y + 0.1, -4.5), Vector3.ZERO, "Pylon"
	)

	# --- Tail assembly (aft section) ---
	var tail_x := -14.5
	MeshFactory.box(
		aft, Vector3(0.14, 5.8, 2.6), tail_orange,
		Vector3(tail_x, BELLY_Y + 3.2, 0), Vector3(0, 0, -0.08), "VerticalStabilizer"
	)
	MeshFactory.box(
		aft, Vector3(0.12, 1.8, 4.8), tail_orange,
		Vector3(tail_x + 0.8, BELLY_Y + 1.6, 0), Vector3.ZERO, "HorizontalStabilizer"
	)
	MeshFactory.box(
		aft, Vector3(0.08, 1.2, 1.0),
		MeshFactory.weathered_hull(Color(0.78, 0.55, 0.22).lerp(Color(0.5, 0.35, 0.15), 0.4)),
		Vector3(tail_x + 0.05, BELLY_Y + 5.5, 0), Vector3(0, 0, -0.08), "TailLogoPanel"
	)
	# APU exhaust / tail cone
	MeshFactory.cylinder(
		aft, 0.35, 0.55, 1.5, hull_dark,
		Vector3(tail_x - 0.5, BELLY_Y, 0), AXIS_ROLL, "TailCone"
	)

	# Belly skid marks / char where plane slid
	MeshFactory.box(
		wreck, Vector3(14.0, 0.04, 2.5), char_mat,
		Vector3(6.0, 0.02, 0), Vector3.ZERO, "GroundScorch"
	)


func _fuselage_tube(parent: Node3D, length: float, center_x: float, mat: Material, part_name: String) -> void:
	MeshFactory.cylinder(
		parent, FUSE_RADIUS, FUSE_RADIUS, length, mat,
		Vector3(center_x, BELLY_Y, 0), AXIS_ROLL, part_name
	)


func _build_terrain() -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "Terrain"
	add_child(terrain_root)

	var ground_size := Vector2(120.0, 120.0)
	var ground_thickness := 0.8
	var ground_top_y := ground_thickness * 0.5 - 0.4
	var grass_mat := MeshFactory.grass_ground_material(ground_size.x / 4.0)
	var dirt_mat := MeshFactory.grass_ground_material(ground_size.x / 5.0)
	dirt_mat.albedo_color = Color(0.78, 0.72, 0.62)
	var rock_mat := MeshFactory.material(Color(0.42, 0.4, 0.38), 0.95)

	# Undulating ground — layered boxes for height variation
	MeshFactory.box(terrain_root, Vector3(ground_size.x, ground_thickness, ground_size.y), grass_mat, Vector3(0, -0.4, 0), Vector3.ZERO, "GroundBase")
	MeshFactory.box(terrain_root, Vector3(40, 1.2, 30), dirt_mat, Vector3(-15, 0.1, 10), Vector3.ZERO, "DirtMound")
	MeshFactory.box(terrain_root, Vector3(25, 0.6, 20), dirt_mat, Vector3(20, 0.0, -12), Vector3.ZERO, "CrashCrater")
	MeshFactory.box(terrain_root, Vector3(8, 1.5, 6), rock_mat, Vector3(12, 0.5, 8), Vector3(0, 0.3, 0), "Boulder")

	MeshFactory.scatter_ground_pebbles(terrain_root, ground_size, ground_top_y, 280, Vector2(0, -4), 6.0)

	# Static collision floor
	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundCollision"
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(120, 0.8, 120)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, -0.4, 0)
	floor_body.add_child(col_shape)
	terrain_root.add_child(floor_body)


func _build_scattered_debris() -> void:
	var debris := Node3D.new()
	debris.name = "ScatteredDebris"
	add_child(debris)

	var luggage_mat := MeshFactory.fabric(Color(0.25, 0.22, 0.2))
	var seat_mat := MeshFactory.fabric(Color(0.18, 0.2, 0.28))
	var metal_mat := MeshFactory.metal(Color(0.55, 0.56, 0.58))
	var panel_mat := MeshFactory.weathered_hull(Color(0.65, 0.67, 0.7))

	# Debris clustered around fuselage break and wing root (near wreck at ~6, -4)
	var debris_items: Array = [
		[Vector3(4, 0.2, 0), Vector3(0, 30, 0), Vector3(0.5, 0.35, 0.7), luggage_mat],
		[Vector3(6, 0.15, 2), Vector3(0, 80, 10), Vector3(0.6, 0.3, 0.4), luggage_mat],
		[Vector3(3, 0.12, -3), Vector3(20, 120, 5), Vector3(0.44, 0.1, 0.46), seat_mat],
		[Vector3(5, 0.08, -6), Vector3(5, 45, 15), Vector3(1.4, 0.06, 0.9), panel_mat],
		[Vector3(2, 0.05, 1), Vector3(0, 15, 25), Vector3(0.8, 0.05, 0.6), metal_mat],
		[Vector3(7, 0.25, -2), Vector3(0, 60, 0), Vector3(0.35, 0.35, 0.35), luggage_mat],
		[Vector3(1, 0.1, -1), Vector3(70, 0, 40), Vector3(0.5, 0.08, 1.1), metal_mat],
	]

	for item: Array in debris_items:
		var pos: Vector3 = item[0]
		var rot: Vector3 = item[1]
		var size: Vector3 = item[2]
		var mat: Material = item[3]
		MeshFactory.box(debris, size, mat, pos, Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))


func _build_forest() -> void:
	var forest := Node3D.new()
	forest.name = "Forest"
	add_child(forest)

	var trunk_mat := MeshFactory.fabric(Color(0.35, 0.22, 0.12))
	var bark_dark := MeshFactory.fabric(Color(0.25, 0.15, 0.08))
	var foliage_mat := MeshFactory.fabric(Color(0.18, 0.42, 0.2))
	var foliage_dark := MeshFactory.fabric(Color(0.12, 0.32, 0.15))

	var tree_positions: Array = [
		Vector3(-25, 0, -20), Vector3(-30, 0, 10), Vector3(-20, 0, 25),
		Vector3(25, 0, -25), Vector3(30, 0, 15), Vector3(22, 0, 28),
		Vector3(-15, 0, -30), Vector3(18, 0, -18), Vector3(-28, 0, -8),
		Vector3(35, 0, -5), Vector3(-22, 0, 18), Vector3(28, 0, 22),
	]

	for pos: Vector3 in tree_positions:
		_build_tree(forest, pos, trunk_mat, bark_dark, foliage_mat, foliage_dark)


func _build_tree(
	parent: Node3D,
	tree_position: Vector3,
	trunk_mat: Material,
	bark_mat: Material,
	foliage_mat: Material,
	foliage_dark: Material
) -> void:
	var tree := Node3D.new()
	tree.position = tree_position
	var scale_factor: float = randf_range(0.85, 1.25)
	tree.scale = Vector3.ONE * scale_factor
	parent.add_child(tree)

	var trunk_h: float = randf_range(5.5, 8.0)
	MeshFactory.cylinder(tree, 0.22, 0.32, trunk_h, trunk_mat, Vector3(0, trunk_h * 0.5, 0), Vector3.ZERO, "Trunk")
	MeshFactory.cylinder(tree, 0.24, 0.24, trunk_h * 0.3, bark_mat, Vector3(0, trunk_h * 0.25, 0))

	# Layered conifer foliage clusters
	for layer: int in 4:
		var layer_y: float = trunk_h * 0.55 + layer * 1.1
		var layer_r: float = 1.6 - layer * 0.3
		var mat: Material = foliage_mat if layer % 2 == 0 else foliage_dark
		MeshFactory.cylinder(
			tree, layer_r, 0.15, 1.4, mat,
			Vector3(0, layer_y, 0), Vector3.ZERO, "FoliageLayer"
		)


func _build_ranger_station() -> void:
	var building := Node3D.new()
	building.name = "AbandonedRangerStation"
	building.position = Vector3(35, 0, -30)
	building.rotation_degrees = Vector3(0, -15, 0)
	add_child(building)

	var wood_mat := MeshFactory.fabric(Color(0.42, 0.32, 0.22))
	var wood_dark := MeshFactory.fabric(Color(0.3, 0.22, 0.15))
	var roof_mat := MeshFactory.fabric(Color(0.25, 0.2, 0.18))
	var window_mat := MeshFactory.glass_tint(Color(0.45, 0.55, 0.65), 0.1)
	var metal_roof := MeshFactory.metal(Color(0.38, 0.4, 0.42), 0.55)

	# Foundation / floor platform
	MeshFactory.box(building, Vector3(8.0, 0.3, 6.0), wood_dark, Vector3(0, 0.15, 0), Vector3.ZERO, "Foundation")

	# Walls — log-cabin style horizontal logs
	for log_i: int in 8:
		var log_y: float = 0.4 + log_i * 0.38
		MeshFactory.box(building, Vector3(8.0, 0.32, 0.28), wood_mat, Vector3(0, log_y, 2.86), Vector3.ZERO, "FrontLog")
		MeshFactory.box(building, Vector3(8.0, 0.32, 0.28), wood_mat, Vector3(0, log_y, -2.86))
		MeshFactory.box(building, Vector3(0.28, 0.32, 6.0), wood_mat, Vector3(-3.86, log_y, 0))
		MeshFactory.box(building, Vector3(0.28, 0.32, 6.0), wood_mat, Vector3(3.86, log_y, 0))

	# Door opening
	MeshFactory.box(building, Vector3(1.2, 2.2, 0.1), wood_dark, Vector3(0, 1.5, 2.9), Vector3.ZERO, "DoorFrame")

	# Windows
	for win_x: float in [-2.5, 2.5]:
		MeshFactory.box(building, Vector3(1.2, 1.0, 0.06), window_mat, Vector3(win_x, 2.0, 2.88), Vector3.ZERO, "Window")
		MeshFactory.box(building, Vector3(1.3, 1.1, 0.08), wood_dark, Vector3(win_x, 2.0, 2.9), Vector3.ZERO, "WindowFrame")

	# Gabled roof — two sloped panels
	MeshFactory.box(building, Vector3(8.6, 0.15, 3.6), roof_mat, Vector3(0, 3.6, 0.9), Vector3(deg_to_rad(-28), 0, 0), "RoofFront")
	MeshFactory.box(building, Vector3(8.6, 0.15, 3.6), roof_mat, Vector3(0, 3.6, -0.9), Vector3(deg_to_rad(28), 0, 0), "RoofBack")
	MeshFactory.box(building, Vector3(8.4, 0.08, 6.2), metal_roof, Vector3(0, 3.35, 0), Vector3.ZERO, "RoofCap")

	# Chimney
	MeshFactory.box(building, Vector3(0.6, 1.8, 0.6), wood_dark, Vector3(2.5, 4.2, -1.5), Vector3.ZERO, "Chimney")
	MeshFactory.box(building, Vector3(0.7, 0.1, 0.7), metal_roof, Vector3(2.5, 5.1, -1.5), Vector3.ZERO, "ChimneyCap")

	# Porch steps
	for step: int in 3:
		MeshFactory.box(
			building, Vector3(2.0 - step * 0.2, 0.18, 0.5), wood_dark,
			Vector3(0, 0.18 + step * 0.18, 3.2 + step * 0.25)
		)
