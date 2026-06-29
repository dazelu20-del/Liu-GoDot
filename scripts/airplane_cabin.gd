extends Node3D

const SEAT_SCENE := preload("res://scenes/airplane_seat.tscn")
const KENNEY_PASSENGER_MALE := preload("res://scenes/kenney_passenger_male.tscn")
const KENNEY_PASSENGER_FEMALE := preload("res://scenes/kenney_passenger_female.tscn")

const ROW_COUNT := 9
const ROW_SPACING := 0.81
const FIRST_ROW_Z := 1.0
const RIGHT_SEATS: Array[float] = [0.58, 1.1, 1.62]
const LEFT_SEATS: Array[float] = [-0.58, -1.1, -1.62]

const PLAYER_ROW := 1
const PLAYER_SEAT_X := 1.62

const CABIN_HALF_WIDTH := 2.1
const BULKHEAD_HEIGHT := 2.35
const BULKHEAD_THICKNESS := 0.08
const DOOR_WIDTH := 0.72
const DOOR_HEIGHT := 1.95
const FRONT_BULKHEAD_Z := -6.1
const REAR_BULKHEAD_Z := 2.9


func _ready() -> void:
	_build_cabin_details()
	_build_seats()
	_build_windows()
	_build_reading_lights()
	_place_passengers()


func get_player_seat_position() -> Vector3:
	var row_z: float = FIRST_ROW_Z - PLAYER_ROW * ROW_SPACING
	return Vector3(PLAYER_SEAT_X, 0.02, row_z)


## Seated eye offset from seat root — matches passenger_model.gd head placement.
func get_player_eye_offset() -> Vector3:
	return Vector3(0.0, 1.22, -0.14)


func _build_cabin_details() -> void:
	var shell: Node3D = $Shell
	var wall_mat := MeshFactory.material(Color(0.74, 0.74, 0.78), 0.7)
	var trim_mat := MeshFactory.plastic(Color(0.55, 0.55, 0.58))
	var carpet_mat := MeshFactory.fabric(Color(0.42, 0.4, 0.38))

	# Curved ceiling panels (segmented boxes simulate barrel vault)
	for i: int in 5:
		var panel_z: float = -1.6 - i * 1.6
		MeshFactory.box(
			shell, Vector3(3.6, 0.06, 1.4), wall_mat,
			Vector3(0, 2.28 + i * 0.02, panel_z), Vector3(0, 0, 0), "CeilingPanel"
		)

	# Overhead PSU strips with reading light bezels per row
	for row: int in ROW_COUNT:
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		for side_x: float in [-1.2, 1.2]:
			MeshFactory.box(
				shell, Vector3(0.5, 0.06, 0.12), trim_mat,
				Vector3(side_x, 2.12, row_z - 0.3), Vector3.ZERO, "PSUPanel"
			)
			MeshFactory.box(
				shell, Vector3(0.08, 0.04, 0.08), MeshFactory.plastic(Color(0.9, 0.88, 0.82)),
				Vector3(side_x, 2.08, row_z - 0.3), Vector3.ZERO, "OxygenMaskHousing"
			)

	# Overhead bin door seams
	for side_x: float in [-1.45, 1.45]:
		for seam_i: int in 8:
			var seam_z: float = -2.0 - seam_i * 0.95
			MeshFactory.box(
				shell, Vector3(0.42, 0.02, 0.04), trim_mat,
				Vector3(side_x, 1.88, seam_z)
			)

	_build_bulkhead_with_door(
		shell, FRONT_BULKHEAD_Z, wall_mat, trim_mat, carpet_mat,
		"Front", true
	)
	_build_bulkhead_with_door(
		shell, REAR_BULKHEAD_Z, wall_mat, trim_mat, carpet_mat,
		"Rear", false
	)

	# Window reveals (depth in fuselage wall)
	for row: int in ROW_COUNT:
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		for wall_x: float in [1.95, -1.95]:
			MeshFactory.box(
				shell, Vector3(0.12, 0.56, 0.48), wall_mat,
				Vector3(wall_x, 1.28, row_z), Vector3.ZERO, "WindowReveal"
			)


func _build_bulkhead_with_door(
	shell: Node3D,
	bulkhead_z: float,
	wall_mat: StandardMaterial3D,
	trim_mat: StandardMaterial3D,
	curtain_mat: StandardMaterial3D,
	prefix: String,
	is_front: bool
) -> void:
	var side_panel_width: float = CABIN_HALF_WIDTH - DOOR_WIDTH * 0.5
	var side_x: float = DOOR_WIDTH * 0.5 + side_panel_width * 0.5
	var wall_y: float = BULKHEAD_HEIGHT * 0.5
	var lintel_height: float = BULKHEAD_HEIGHT - DOOR_HEIGHT
	var door_center_y: float = DOOR_HEIGHT * 0.5

	MeshFactory.box(
		shell, Vector3(side_panel_width, BULKHEAD_HEIGHT, BULKHEAD_THICKNESS), wall_mat,
		Vector3(-side_x, wall_y, bulkhead_z), Vector3.ZERO, "%sBulkheadLeft" % prefix
	)
	MeshFactory.box(
		shell, Vector3(side_panel_width, BULKHEAD_HEIGHT, BULKHEAD_THICKNESS), wall_mat,
		Vector3(side_x, wall_y, bulkhead_z), Vector3.ZERO, "%sBulkheadRight" % prefix
	)
	MeshFactory.box(
		shell, Vector3(DOOR_WIDTH, lintel_height, BULKHEAD_THICKNESS), wall_mat,
		Vector3(0, DOOR_HEIGHT + lintel_height * 0.5, bulkhead_z), Vector3.ZERO, "%sBulkheadLintel" % prefix
	)

	var frame_depth: float = 0.06
	var frame_thickness: float = 0.07
	var door_z: float = bulkhead_z + (frame_depth * 0.5 if is_front else -frame_depth * 0.5)

	MeshFactory.box(
		shell, Vector3(frame_thickness, DOOR_HEIGHT, frame_depth), trim_mat,
		Vector3(-DOOR_WIDTH * 0.5 - frame_thickness * 0.5, door_center_y, door_z),
		Vector3.ZERO, "%sDoorFrameLeft" % prefix
	)
	MeshFactory.box(
		shell, Vector3(frame_thickness, DOOR_HEIGHT, frame_depth), trim_mat,
		Vector3(DOOR_WIDTH * 0.5 + frame_thickness * 0.5, door_center_y, door_z),
		Vector3.ZERO, "%sDoorFrameRight" % prefix
	)
	MeshFactory.box(
		shell, Vector3(DOOR_WIDTH + frame_thickness * 2.0, frame_thickness, frame_depth), trim_mat,
		Vector3(0, DOOR_HEIGHT + frame_thickness * 0.5, door_z),
		Vector3.ZERO, "%sDoorFrameTop" % prefix
	)

	var panel_z: float = bulkhead_z + (0.03 if is_front else -0.03)
	MeshFactory.box(
		shell, Vector3(DOOR_WIDTH - 0.08, DOOR_HEIGHT - 0.12, 0.04), wall_mat,
		Vector3(0, door_center_y, panel_z), Vector3.ZERO, "%sDoorPanel" % prefix
	)
	MeshFactory.box(
		shell, Vector3(0.12, 0.04, 0.03), trim_mat,
		Vector3(DOOR_WIDTH * 0.28, door_center_y, panel_z + (0.02 if is_front else -0.02)),
		Vector3.ZERO, "%sDoorHandle" % prefix
	)

	if is_front:
		var galley_z: float = bulkhead_z - 0.18
		MeshFactory.box(
			shell, Vector3(3.6, 2.05, 0.04), curtain_mat,
			Vector3(0, 1.12, galley_z), Vector3.ZERO, "GalleyCurtain"
		)
	else:
		var lav_sign_z: float = bulkhead_z - 0.05
		MeshFactory.box(
			shell, Vector3(0.22, 0.08, 0.02), trim_mat,
			Vector3(0, DOOR_HEIGHT - 0.18, lav_sign_z), Vector3.ZERO, "LavatorySign"
		)


func _build_seats() -> void:
	var seats_root := $Seats
	for row: int in ROW_COUNT:
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		for seat_x: float in RIGHT_SEATS:
			_place_seat(seats_root, seat_x, row_z)
		for seat_x: float in LEFT_SEATS:
			_place_seat(seats_root, seat_x, row_z)


func _place_seat(parent: Node3D, seat_x: float, row_z: float) -> void:
	var seat: Node3D = SEAT_SCENE.instantiate()
	seat.position = Vector3(seat_x, 0.0, row_z)
	parent.add_child(seat)


func _build_windows() -> void:
	var windows_root := $Windows
	for row: int in ROW_COUNT:
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		_place_window(windows_root, 1.95, row_z)
		_place_window(windows_root, -1.95, row_z)


func _place_window(parent: Node3D, wall_x: float, row_z: float) -> void:
	var frame_mat := MeshFactory.metal(Color(0.68, 0.68, 0.72), 0.3)
	var glass_mat := MeshFactory.glass_tint(Color(0.5, 0.7, 0.92), 0.35)

	MeshFactory.box(parent, Vector3(0.08, 0.52, 0.42), frame_mat, Vector3(wall_x, 1.28, row_z), Vector3.ZERO, "WindowFrame")
	MeshFactory.box(
		parent, Vector3(0.04, 0.44, 0.36), glass_mat,
		Vector3(wall_x - signf(wall_x) * 0.06, 1.28, row_z), Vector3.ZERO, "WindowGlass"
	)
	# Sun shade partially down on some rows
	if int(row_z * 10) % 3 == 0:
		MeshFactory.box(
			parent, Vector3(0.03, 0.2, 0.34), MeshFactory.fabric(Color(0.15, 0.15, 0.18)),
			Vector3(wall_x - signf(wall_x) * 0.05, 1.38, row_z), Vector3.ZERO, "SunShade"
		)


func _build_reading_lights() -> void:
	var lights_root := Node3D.new()
	lights_root.name = "ReadingLights"
	add_child(lights_root)

	for row: int in ROW_COUNT:
		if row % 2 != 0:
			continue
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, 2.05, row_z - 0.3)
		light.light_color = Color(1.0, 0.95, 0.88)
		light.light_energy = 0.25
		light.omni_range = 3.5
		light.shadow_enabled = false
		lights_root.add_child(light)


func _place_passengers() -> void:
	var passengers_root := $Passengers
	for row: int in ROW_COUNT:
		var row_z: float = FIRST_ROW_Z - row * ROW_SPACING
		for seat_x: float in RIGHT_SEATS:
			_place_seat_passenger(passengers_root, row, seat_x, row_z)
		for seat_x: float in LEFT_SEATS:
			_place_seat_passenger(passengers_root, row, seat_x, row_z)


func _place_seat_passenger(parent: Node3D, row: int, seat_x: float, row_z: float) -> void:
	if row == PLAYER_ROW and is_equal_approx(seat_x, PLAYER_SEAT_X):
		return

	var seat_index: int = absi(int(roundf(seat_x * 100.0)))
	var use_female: bool = (row + seat_index) % 2 == 0
	_place_kenney_passenger(
		parent,
		Vector3(seat_x, 0.02, row_z),
		use_female,
		"Passenger_R%d_S%d" % [row, seat_index]
	)


func _place_kenney_passenger(
	parent: Node3D,
	seat_position: Vector3,
	use_female_skin: bool,
	node_name: String = ""
) -> void:
	var passenger_scene: PackedScene = KENNEY_PASSENGER_FEMALE if use_female_skin else KENNEY_PASSENGER_MALE
	var passenger: Node3D = passenger_scene.instantiate()
	if not node_name.is_empty():
		passenger.name = node_name
	passenger.position = seat_position
	parent.add_child(passenger)
