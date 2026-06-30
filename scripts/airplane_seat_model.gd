extends Node3D

## Procedural narrow-body economy seat based on Boeing 737-class dimensions.
## See docs/model-build-guide.md for full art specifications.


func _ready() -> void:
	_build_seat()


func _build_seat() -> void:
	var fabric_blue := MeshFactory.fabric(Color(0.18, 0.22, 0.32))
	var fabric_dark := MeshFactory.fabric(Color(0.12, 0.14, 0.2))
	var frame_metal := MeshFactory.metal(Color(0.55, 0.56, 0.58), 0.4)
	var plastic_trim := MeshFactory.plastic(Color(0.2, 0.2, 0.22))

	# Seat pan — tapered cushion stack
	MeshFactory.box(self, Vector3(0.44, 0.06, 0.46), fabric_blue, Vector3(0, 0.42, 0))
	MeshFactory.box(self, Vector3(0.42, 0.04, 0.44), fabric_dark, Vector3(0, 0.47, 0.01))

	# Seat back — slight recline (~18°)
	var back_tilt := deg_to_rad(-18.0)
	MeshFactory.box(
		self, Vector3(0.44, 0.62, 0.08), fabric_blue,
		Vector3(0, 0.78, 0.22), Vector3(back_tilt, 0, 0), "SeatBack"
	)
	MeshFactory.box(
		self, Vector3(0.4, 0.5, 0.04), fabric_dark,
		Vector3(0, 0.76, 0.2), Vector3(back_tilt, 0, 0), "BackPadding"
	)

	# Headrest with side wings (realistic bucket shape)
	MeshFactory.box(
		self, Vector3(0.24, 0.18, 0.1), fabric_dark,
		Vector3(0, 1.1, 0.2), Vector3(back_tilt, 0, 0), "Headrest"
	)
	MeshFactory.box(
		self, Vector3(0.08, 0.14, 0.08), fabric_dark,
		Vector3(-0.14, 1.08, 0.2), Vector3(back_tilt, 0, 0), "HeadrestWingL"
	)
	MeshFactory.box(
		self, Vector3(0.08, 0.14, 0.08), fabric_dark,
		Vector3(0.14, 1.08, 0.2), Vector3(back_tilt, 0, 0), "HeadrestWingR"
	)

	# Armrests with metal cores
	for side_x: float in [-0.25, 0.25]:
		MeshFactory.box(
			self, Vector3(0.06, 0.16, 0.36), plastic_trim,
			Vector3(side_x, 0.56, 0.02), Vector3.ZERO, "Armrest"
		)
		MeshFactory.box(
			self, Vector3(0.04, 0.12, 0.32), frame_metal,
			Vector3(side_x, 0.54, 0.02)
		)

	# Folded tray table on back of seat in front (visible from behind rows)
	MeshFactory.box(
		self, Vector3(0.38, 0.02, 0.28), plastic_trim,
		Vector3(0, 0.55, -0.28), Vector3.ZERO, "TrayTable"
	)

	# Seat belt buckle and strap hints
	MeshFactory.box(
		self, Vector3(0.12, 0.02, 0.04), frame_metal,
		Vector3(0.08, 0.5, 0.12), Vector3.ZERO, "BeltBuckle"
	)
	MeshFactory.box(
		self, Vector3(0.04, 0.02, 0.22), fabric_dark,
		Vector3(-0.06, 0.5, 0.04), Vector3.ZERO, "BeltStrap"
	)

	# Floor track legs
	for leg_x: float in [-0.16, 0.16]:
		MeshFactory.box(
			self, Vector3(0.04, 0.38, 0.04), frame_metal,
			Vector3(leg_x, 0.19, 0.14)
		)
		MeshFactory.cylinder(
			self, 0.02, 0.02, 0.38, frame_metal,
			Vector3(leg_x, 0.19, -0.12)
		)
