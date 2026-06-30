extends Node3D

## Seated passenger figure for cabin intro. Proportions based on average adult (~1.75 m).
## See docs/model-build-guide.md for rigging and high-poly replacement notes.

@export var shirt_color: Color = Color(0.25, 0.35, 0.55)
@export var hair_color: Color = Color(0.22, 0.16, 0.12)
@export var seated_recline: float = 15.0
## Assign an imported seated-passenger scene (.glb) to replace the procedural placeholder.
@export var rig_scene: PackedScene


func _ready() -> void:
	if rig_scene:
		_spawn_rig()
		return
	_build_passenger()


func _spawn_rig() -> void:
	var rig: Node3D = rig_scene.instantiate() as Node3D
	if rig == null:
		push_warning("Passenger rig_scene must instantiate a Node3D.")
		_build_passenger()
		return
	add_child(rig)


func _build_passenger() -> void:
	var shirt := MeshFactory.fabric(shirt_color)
	var pants := MeshFactory.fabric(Color(0.15, 0.15, 0.18))
	var skin_mat := MeshFactory.skin()
	var hair_mat := MeshFactory.fabric(hair_color)
	var shoe_mat := MeshFactory.fabric(Color(0.1, 0.1, 0.11))
	var belt_mat := MeshFactory.metal(Color(0.4, 0.4, 0.42), 0.5)

	var lean := deg_to_rad(-seated_recline)

	# Pelvis / lower torso
	MeshFactory.box(
		self, Vector3(0.36, 0.22, 0.3), pants,
		Vector3(0, 0.52, 0.04), Vector3(lean, 0, 0), "Pelvis"
	)

	# Upper torso / chest
	MeshFactory.box(
		self, Vector3(0.38, 0.32, 0.26), shirt,
		Vector3(0, 0.74, -0.02), Vector3(lean, 0, 0), "Torso"
	)

	# Shoulders — wider than chest
	MeshFactory.box(
		self, Vector3(0.48, 0.12, 0.22), shirt,
		Vector3(0, 0.86, -0.04), Vector3(lean, 0, 0), "Shoulders"
	)

	# Neck
	MeshFactory.cylinder(
		self, 0.06, 0.07, 0.1, skin_mat,
		Vector3(0, 0.98, -0.1), Vector3(lean, 0, 0), "Neck"
	)

	# Head
	MeshFactory.sphere(self, 0.13, skin_mat, Vector3(0, 1.1, -0.14), "Head")

	# Hair cap
	MeshFactory.sphere(self, 0.135, hair_mat, Vector3(0, 1.14, -0.16), "Hair")

	# Arms resting on armrests
	for side: float in [-1.0, 1.0]:
		var arm_x: float = side * 0.28
		MeshFactory.cylinder(
			self, 0.055, 0.05, 0.28, shirt,
			Vector3(arm_x, 0.72, 0.06), Vector3(0.4, 0, side * 0.3), "UpperArm"
		)
		MeshFactory.cylinder(
			self, 0.045, 0.04, 0.24, skin_mat,
			Vector3(arm_x + side * 0.08, 0.6, 0.14), Vector3(1.2, 0, side * 0.2), "Forearm"
		)
		MeshFactory.sphere(
			self, 0.05, skin_mat,
			Vector3(arm_x + side * 0.12, 0.56, 0.22), "Hand"
		)

	# Thighs
	for side: float in [-1.0, 1.0]:
		MeshFactory.cylinder(
			self, 0.1, 0.11, 0.32, pants,
			Vector3(side * 0.12, 0.42, 0.18), Vector3(1.1, 0, side * 0.15), "Thigh"
		)
		MeshFactory.cylinder(
			self, 0.08, 0.07, 0.3, pants,
			Vector3(side * 0.12, 0.22, 0.32), Vector3(1.4, 0, 0), "Shin"
		)
		MeshFactory.box(
			self, Vector3(0.1, 0.06, 0.2), shoe_mat,
			Vector3(side * 0.12, 0.06, 0.42)
		)

	# Seat belt across lap
	MeshFactory.box(
		self, Vector3(0.34, 0.02, 0.03), belt_mat,
		Vector3(0, 0.58, 0.1), Vector3(lean, 0, 0), "SeatBelt"
	)
