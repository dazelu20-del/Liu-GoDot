class_name MeshFactory
extends RefCounted

## Shared mesh and material helpers for procedural realistic models.


static func material(
	albedo: Color,
	roughness: float = 0.85,
	metallic: float = 0.0,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


static func fabric(color: Color) -> StandardMaterial3D:
	return material(color, 0.92, 0.0)


static func metal(color: Color, roughness: float = 0.35) -> StandardMaterial3D:
	return material(color, roughness, 0.75)


static func plastic(color: Color) -> StandardMaterial3D:
	return material(color, 0.45, 0.05)


static func glass_tint(color: Color, emission_energy: float = 0.25) -> StandardMaterial3D:
	var mat := material(color, 0.08, 0.0, color * 0.6, emission_energy)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.55
	return mat


static func skin() -> StandardMaterial3D:
	var mat := material(Color(0.82, 0.67, 0.55), 0.78)
	mat.rim_enabled = true
	mat.rim = 0.18
	return mat


static func box(
	parent: Node3D,
	size: Vector3,
	mat: Material,
	position: Vector3 = Vector3.ZERO,
	rotation: Vector3 = Vector3.ZERO,
	name: String = ""
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	if not name.is_empty():
		mesh_inst.name = name
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat
	mesh_inst.position = position
	mesh_inst.rotation = rotation
	parent.add_child(mesh_inst)
	return mesh_inst


static func cylinder(
	parent: Node3D,
	top_radius: float,
	bottom_radius: float,
	height: float,
	mat: Material,
	position: Vector3 = Vector3.ZERO,
	rotation: Vector3 = Vector3.ZERO,
	name: String = ""
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	if not name.is_empty():
		mesh_inst.name = name
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_radius
	cyl.bottom_radius = bottom_radius
	cyl.height = height
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	mesh_inst.position = position
	mesh_inst.rotation = rotation
	parent.add_child(mesh_inst)
	return mesh_inst


static func weathered_hull(base: Color, grime_tint: Color = Color(0.45, 0.48, 0.42)) -> StandardMaterial3D:
	var mat := material(base, 0.88, 0.12)
	mat.albedo_color = base.lerp(grime_tint, 0.35)
	return mat


static func moss_weathered(base: Color) -> StandardMaterial3D:
	return material(base.lerp(Color(0.35, 0.42, 0.32), 0.45), 0.95, 0.05)


static func rust_patch() -> StandardMaterial3D:
	return material(Color(0.42, 0.26, 0.16), 0.92, 0.2)


static func grass_ground_material(uv_tiles: float = 20.0) -> StandardMaterial3D:
	var albedo_tex := ImageTexture.create_from_image(_make_grass_albedo_image(512))
	var rough_tex := ImageTexture.create_from_image(_make_grass_roughness_image(256))

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo_tex
	mat.albedo_color = Color(0.92, 0.98, 0.9)
	mat.roughness_texture = rough_tex
	mat.roughness = 0.94
	mat.metallic = 0.0
	mat.uv1_scale = Vector3(uv_tiles, uv_tiles, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


static func sand_ground_material(uv_tiles: float = 20.0) -> StandardMaterial3D:
	var albedo_tex := ImageTexture.create_from_image(_make_sand_albedo_image(512))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo_tex
	mat.albedo_color = Color(0.98, 0.94, 0.84)
	mat.roughness = 0.96
	mat.metallic = 0.0
	mat.uv1_scale = Vector3(uv_tiles, uv_tiles, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


static func water_material() -> StandardMaterial3D:
	var albedo_tex := ImageTexture.create_from_image(_make_water_albedo_image(256))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo_tex
	mat.albedo_color = Color(0.72, 0.9, 0.98, 0.82)
	mat.roughness = 0.08
	mat.metallic = 0.18
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(18.0, 18.0, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


static func pebble_material(variant: float = 0.5) -> StandardMaterial3D:
	var grey := lerpf(0.34, 0.5, variant)
	return material(Color(grey, grey * 0.94, grey * 0.86), lerpf(0.88, 0.97, variant), 0.02)


static func scatter_ground_pebbles(
	parent: Node3D,
	ground_size: Vector2,
	ground_top_y: float,
	count: int,
	clear_center: Vector2 = Vector2.ZERO,
	clear_radius: float = 0.0
) -> void:
	var pebbles := Node3D.new()
	pebbles.name = "Pebbles"
	parent.add_child(pebbles)

	var half_x: float = ground_size.x * 0.5 - 1.5
	var half_z: float = ground_size.y * 0.5 - 1.5
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 4:
		attempts += 1
		var pos := Vector3(
			rng.randf_range(-half_x, half_x),
			ground_top_y,
			rng.randf_range(-half_z, half_z)
		)
		if Vector2(pos.x, pos.z).distance_to(clear_center) < clear_radius:
			continue

		var pebble_size: float = rng.randf_range(0.03, 0.11)
		var flatness: float = rng.randf_range(0.3, 0.7)
		var pebble := MeshInstance3D.new()
		pebble.name = "Pebble"
		var sph := SphereMesh.new()
		sph.radius = pebble_size
		sph.height = pebble_size * 2.0
		sph.radial_segments = 6
		sph.rings = 4
		pebble.mesh = sph
		pebble.material_override = pebble_material(rng.randf())
		pebble.position = pos + Vector3(0.0, pebble_size * flatness * 0.45, 0.0)
		pebble.scale = Vector3(rng.randf_range(0.85, 1.15), flatness, rng.randf_range(0.85, 1.15))
		pebble.rotation = Vector3(
			rng.randf_range(-0.4, 0.4),
			rng.randf() * TAU,
			rng.randf_range(-0.4, 0.4)
		)
		pebbles.add_child(pebble)
		placed += 1


static func _make_grass_albedo_image(size: int) -> Image:
	var patch_noise := FastNoiseLite.new()
	patch_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	patch_noise.frequency = 0.045
	patch_noise.fractal_octaves = 4

	var blade_noise := FastNoiseLite.new()
	blade_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	blade_noise.frequency = 0.22
	blade_noise.fractal_octaves = 3

	var dirt_noise := FastNoiseLite.new()
	dirt_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	dirt_noise.frequency = 0.08

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark_grass := Color(0.16, 0.3, 0.11)
	var mid_grass := Color(0.22, 0.4, 0.15)
	var bright_grass := Color(0.3, 0.52, 0.2)
	var dry_patch := Color(0.34, 0.38, 0.17)

	for y: int in size:
		for x: int in size:
			var patch: float = patch_noise.get_noise_2d(x, y)
			var blade: float = blade_noise.get_noise_2d(x, y)
			var dirt: float = dirt_noise.get_noise_2d(x, y)
			var col: Color = dark_grass.lerp(mid_grass, clampf(patch * 0.5 + 0.5, 0.0, 1.0))
			col = col.lerp(bright_grass, clampf(blade * 0.5 + 0.5, 0.0, 1.0) * 0.55)
			col = col.lerp(dry_patch, clampf(dirt * 0.35 + 0.15, 0.0, 1.0) * 0.25)
			img.set_pixel(x, y, col)

	return img


static func _make_grass_roughness_image(size: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.1
	noise.fractal_octaves = 3

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var n: float = noise.get_noise_2d(x, y)
			var rough: float = clampf(0.88 + n * 0.08, 0.0, 1.0)
			img.set_pixel(x, y, Color(rough, rough, rough))
	return img


static func _make_sand_albedo_image(size: int) -> Image:
	var dune_noise := FastNoiseLite.new()
	dune_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	dune_noise.frequency = 0.06
	dune_noise.fractal_octaves = 4

	var grain_noise := FastNoiseLite.new()
	grain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	grain_noise.frequency = 0.28
	grain_noise.fractal_octaves = 2

	var wet_noise := FastNoiseLite.new()
	wet_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	wet_noise.frequency = 0.05

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dry_sand := Color(0.76, 0.68, 0.5)
	var bright_sand := Color(0.86, 0.78, 0.58)
	var damp_sand := Color(0.58, 0.54, 0.44)

	for y: int in size:
		for x: int in size:
			var dune: float = dune_noise.get_noise_2d(x, y)
			var grain: float = grain_noise.get_noise_2d(x, y)
			var wet: float = wet_noise.get_noise_2d(x, y)
			var col: Color = dry_sand.lerp(bright_sand, clampf(dune * 0.5 + 0.5, 0.0, 1.0))
			col = col.lerp(bright_sand, clampf(grain * 0.5 + 0.5, 0.0, 1.0) * 0.35)
			col = col.lerp(damp_sand, clampf(wet * 0.25 + 0.2, 0.0, 1.0) * 0.22)
			img.set_pixel(x, y, col)

	return img


static func _make_water_albedo_image(size: int) -> Image:
	var wave_noise := FastNoiseLite.new()
	wave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	wave_noise.frequency = 0.14
	wave_noise.fractal_octaves = 3

	var depth_noise := FastNoiseLite.new()
	depth_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	depth_noise.frequency = 0.04
	depth_noise.fractal_octaves = 2

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var shallow := Color(0.22, 0.52, 0.62, 0.75)
	var deep := Color(0.08, 0.28, 0.45, 0.88)

	for y: int in size:
		for x: int in size:
			var wave: float = wave_noise.get_noise_2d(x, y)
			var depth: float = depth_noise.get_noise_2d(x, y)
			var col: Color = shallow.lerp(deep, clampf(depth * 0.5 + 0.5, 0.0, 1.0))
			col.a = clampf(0.72 + wave * 0.12, 0.55, 0.92)
			img.set_pixel(x, y, col)

	return img


static func capsule(
	parent: Node3D,
	radius: float,
	height: float,
	mat: Material,
	position: Vector3 = Vector3.ZERO,
	rotation: Vector3 = Vector3.ZERO,
	name: String = ""
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	if not name.is_empty():
		mesh_inst.name = name
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	mesh_inst.mesh = cap
	mesh_inst.material_override = mat
	mesh_inst.position = position
	mesh_inst.rotation = rotation
	parent.add_child(mesh_inst)
	return mesh_inst


static func sphere(
	parent: Node3D,
	radius: float,
	mat: Material,
	position: Vector3 = Vector3.ZERO,
	name: String = ""
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	if not name.is_empty():
		mesh_inst.name = name
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	mesh_inst.mesh = sph
	mesh_inst.material_override = mat
	mesh_inst.position = position
	parent.add_child(mesh_inst)
	return mesh_inst
