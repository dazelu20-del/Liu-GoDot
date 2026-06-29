extends Node3D

const SHADOW_RADIUS := 0.52
const SHADOW_HEIGHT := 0.02
const RAY_LENGTH := 8.0
const GROUND_OFFSET := 0.03
const MAX_ALPHA := 0.42
const MIN_ALPHA := 0.12

@onready var _player: CharacterBody3D = get_parent()
@onready var _shadow_mesh: MeshInstance3D = $ShadowMesh

var _shadow_material: StandardMaterial3D


func _ready() -> void:
	_shadow_material = StandardMaterial3D.new()
	_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shadow_material.albedo_texture = _make_soft_circle_texture()
	_shadow_material.albedo_color = Color(0.0, 0.0, 0.0, MAX_ALPHA)
	_shadow_mesh.material_override = _shadow_material

	var disc := CylinderMesh.new()
	disc.top_radius = SHADOW_RADIUS
	disc.bottom_radius = SHADOW_RADIUS
	disc.height = SHADOW_HEIGHT
	disc.radial_segments = 32
	_shadow_mesh.mesh = disc
	_shadow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	var origin := _player.global_position + Vector3(0.0, 0.8, 0.0)
	var space_state := _player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * RAY_LENGTH)
	query.exclude = [_player.get_rid()]
	var hit := space_state.intersect_ray(query)

	var ground_point: Vector3
	var height_above_ground: float
	if hit.is_empty():
		ground_point = Vector3(_player.global_position.x, GROUND_OFFSET, _player.global_position.z)
		height_above_ground = maxf(_player.global_position.y - GROUND_OFFSET, 0.0)
	else:
		ground_point = hit.position + Vector3(0.0, GROUND_OFFSET, 0.0)
		height_above_ground = maxf(_player.global_position.y - hit.position.y, 0.0)

	global_position = ground_point

	var stretch := clampf(1.0 + height_above_ground * 0.1, 1.0, 1.45)
	_shadow_mesh.scale = Vector3(stretch, 1.0, stretch * 0.92)

	var alpha := clampf(MAX_ALPHA - height_above_ground * 0.08, MIN_ALPHA, MAX_ALPHA)
	_shadow_material.albedo_color.a = alpha
	_shadow_mesh.visible = _player.can_control or height_above_ground < 3.0


func _make_soft_circle_texture() -> Texture2D:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := size * 0.5

	for y: int in size:
		for x: int in size:
			var dist := Vector2(x, y).distance_to(center) / radius
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = pow(alpha, 1.8)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	var texture := ImageTexture.create_from_image(image)
	return texture
