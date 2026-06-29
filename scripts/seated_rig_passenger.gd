extends Node3D

## Seats a Kenney characterMedium rig in an airplane seat.

@export var rig_scene: PackedScene
@export_range(0.1, 1.5, 0.01) var model_scale := 0.45
@export var facing_yaw_degrees := 180.0
@export var seat_height := 0.0
@export var seat_forward := 0.05
@export var seat_offset := Vector3(0.05, 0.0, 0.03)
@export var target_eye_height := 1.08
@export_range(0.5, 1.0, 0.01) var head_scale := 0.82
@export_range(0.0, 12.0, 0.5) var head_look_lift_degrees := 4.0
@export var skin_texture: Texture2D
@export var idle_animation_scene: PackedScene

var _facing: Node3D
var _model: Node3D
var _rig: Node3D
var _skeleton: Skeleton3D
var _breath_bones: Array[int] = []
var _breath_base: Array[Quaternion] = []


func _ready() -> void:
	if rig_scene == null:
		push_warning("SeatedRigPassenger: rig_scene is not set.")
		return
	_setup_character()


func _setup_character() -> void:
	_facing = Node3D.new()
	_facing.name = "Facing"
	add_child(_facing)

	_model = Node3D.new()
	_model.name = "Model"
	_facing.add_child(_model)

	_rig = rig_scene.instantiate() as Node3D
	if _rig == null:
		push_warning("SeatedRigPassenger: rig_scene must instantiate a Node3D.")
		return

	_model.add_child(_rig)
	_facing.rotation_degrees.y = facing_yaw_degrees
	_model.rotation_degrees.x = 180.0
	_model.scale = Vector3.ONE * maxf(model_scale, 0.1)
	_model.position = Vector3(0.0, seat_height, seat_forward)

	if skin_texture:
		_apply_skin_texture(_rig, skin_texture)

	await get_tree().process_frame

	_skeleton = _find_skeleton(_rig)
	if _skeleton:
		_skeleton.reset_bone_poses()
		_apply_seated_pose()
		_orient_head_forward()
		_cache_breath_bones()

	await get_tree().process_frame
	_align_to_eye_level()
	_model.position += seat_offset


func _align_to_eye_level() -> void:
	var eye_y := _get_eye_height_local()
	if eye_y == INF:
		return
	_model.position.y += target_eye_height - eye_y


func _get_eye_height_local() -> float:
	if _skeleton:
		var head_idx := _skeleton.find_bone("Head")
		if head_idx >= 0:
			var head_world := _skeleton.to_global(_skeleton.get_bone_global_pose(head_idx).origin)
			return to_local(head_world).y

	var highest_y := -INF
	for mesh_inst: MeshInstance3D in _find_all_mesh_instances(_rig):
		var mesh_aabb: AABB = _model.global_transform.affine_inverse() * mesh_inst.global_transform * mesh_inst.get_aabb()
		highest_y = maxf(highest_y, mesh_aabb.end.y)
	if highest_y == -INF:
		return INF
	return highest_y * 0.92


func _process(_delta: float) -> void:
	if _skeleton == null or _breath_bones.is_empty():
		return
	var breath := sin(Time.get_ticks_msec() * 0.0015) * 0.018
	var weights: Array[float] = [1.0, 0.7, 0.4]
	for i: int in _breath_bones.size():
		var tilt := Quaternion.from_euler(Vector3(breath * weights[i], 0.0, 0.0))
		_skeleton.set_bone_pose_rotation(_breath_bones[i], _breath_base[i] * tilt)


func _apply_seated_pose() -> void:
	_rotate_bone("Hips", Vector3(deg_to_rad(-6.0), 0.0, 0.0))
	_rotate_bone("Spine", Vector3(deg_to_rad(-14.0), 0.0, 0.0))
	_rotate_bone("Chest", Vector3(deg_to_rad(-8.0), 0.0, 0.0))
	_rotate_bone("UpperChest", Vector3(deg_to_rad(-6.0), 0.0, 0.0))
	_scale_bone("Neck", Vector3(0.92, 0.92, 0.92))
	_scale_bone("Head", Vector3.ONE * head_scale)

	# Legs: positive hip pitch + negative knee bend reads as forward-facing sit after the model X flip.
	_rotate_bone("LeftUpLeg", Vector3(deg_to_rad(76.0), deg_to_rad(2.0), deg_to_rad(10.0)))
	_rotate_bone("RightUpLeg", Vector3(deg_to_rad(76.0), deg_to_rad(-2.0), deg_to_rad(-10.0)))
	_rotate_bone("LeftLeg", Vector3(deg_to_rad(84.0), 0.0, 0.0))
	_rotate_bone("RightLeg", Vector3(deg_to_rad(84.0), 0.0, 0.0))
	_rotate_bone("LeftFoot", Vector3(deg_to_rad(10.0), 0.0, 0.0))
	_rotate_bone("RightFoot", Vector3(deg_to_rad(10.0), 0.0, 0.0))

	# Drop shoulders ~90° so arms hang straight at the sides.
	_rotate_bone("LeftShoulder", Vector3(deg_to_rad(-150.0), 0.0, 0.0))
	_rotate_bone("RightShoulder", Vector3(deg_to_rad(-150.0), 0.0, 0.0))
	_rotate_bone("LeftArm", Vector3.ZERO)
	_rotate_bone("RightArm", Vector3.ZERO)
	_rotate_bone("LeftForeArm", Vector3.ZERO)
	_rotate_bone("RightForeArm", Vector3.ZERO)


func _cabin_look_direction() -> Vector3:
	return Vector3(
		0.0,
		sin(deg_to_rad(head_look_lift_degrees)),
		-cos(deg_to_rad(head_look_lift_degrees))
	).normalized()


func _orient_head_forward() -> void:
	var neck_idx := _skeleton.find_bone("Neck")
	var head_idx := _skeleton.find_bone("Head")
	if head_idx < 0:
		return

	_rotate_bone("Neck", Vector3.ZERO)
	_rotate_bone("Head", Vector3.ZERO)
	_skeleton.force_update_all_bone_transforms()

	var look_dir := _cabin_look_direction()
	if neck_idx >= 0:
		_aim_bone_forward(neck_idx, look_dir, deg_to_rad(40.0))
		_skeleton.force_update_bone_child_transform(neck_idx)
	_aim_bone_forward(head_idx, look_dir, deg_to_rad(30.0))


func _get_bone_face_forward(bone_idx: int) -> Vector3:
	var bone_world := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_idx)
	var bone_basis := bone_world.basis
	var candidates: Array[Vector3] = [
		-bone_basis.z, bone_basis.z, bone_basis.x, -bone_basis.x, bone_basis.y, -bone_basis.y,
	]
	var cabin_forward_flat := Vector3(0.0, 0.0, -1.0)
	var best := -bone_basis.z
	var best_score := -INF
	for dir: Vector3 in candidates:
		var flat := Vector3(dir.x, 0.0, dir.z)
		if flat.length_squared() < 0.0001:
			continue
		flat = flat.normalized()
		var score := flat.dot(cabin_forward_flat)
		if score > best_score:
			best_score = score
			best = dir.normalized()
	return best


func _aim_bone_forward(bone_idx: int, world_dir: Vector3, max_angle: float) -> void:
	var face_forward := _get_bone_face_forward(bone_idx)
	var angle := face_forward.angle_to(world_dir)
	if angle < 0.002:
		return
	angle = minf(angle, max_angle)

	var axis := face_forward.cross(world_dir)
	if axis.length_squared() < 0.000001:
		return
	axis = axis.normalized()

	var delta := Quaternion(axis, angle)
	var bone_world := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_idx)
	var bone_world_rot := bone_world.basis.get_rotation_quaternion()
	var new_world_rot := delta * bone_world_rot

	var parent_idx := _skeleton.get_bone_parent(bone_idx)
	var parent_world_rot: Quaternion
	if parent_idx >= 0:
		var parent_world := _skeleton.global_transform * _skeleton.get_bone_global_pose(parent_idx)
		parent_world_rot = parent_world.basis.get_rotation_quaternion()
	else:
		parent_world_rot = _skeleton.global_transform.basis.get_rotation_quaternion()

	_skeleton.set_bone_pose_rotation(bone_idx, parent_world_rot.inverse() * new_world_rot)


func _rotate_bone(bone_name: String, euler: Vector3) -> void:
	var bone_idx := _skeleton.find_bone(bone_name)
	if bone_idx < 0:
		return
	_skeleton.set_bone_pose_rotation(bone_idx, Quaternion.from_euler(euler))


func _scale_bone(bone_name: String, bone_scale: Vector3) -> void:
	var bone_idx := _skeleton.find_bone(bone_name)
	if bone_idx < 0:
		return
	_skeleton.set_bone_pose_scale(bone_idx, bone_scale)


func _cache_breath_bones() -> void:
	_breath_bones.clear()
	_breath_base.clear()
	for bone_name: String in ["UpperChest", "Chest", "Spine"]:
		var bone_idx := _skeleton.find_bone(bone_name)
		if bone_idx < 0:
			continue
		_breath_bones.append(bone_idx)
		_breath_base.append(_skeleton.get_bone_pose_rotation(bone_idx))


func _play_idle(root: Node) -> void:
	var player := _find_animation_player(root)
	if player == null and idle_animation_scene:
		_merge_idle_animation(root)
		player = _find_animation_player(root)
	if player == null:
		return

	for anim_name: String in player.get_animation_list():
		if "idle" in anim_name.to_lower():
			player.play(anim_name)
			return
	var animations := player.get_animation_list()
	if not animations.is_empty():
		player.play(animations[0])


func _merge_idle_animation(root: Node) -> void:
	var idle_inst: Node = idle_animation_scene.instantiate()
	var idle_player := _find_animation_player(idle_inst)
	var skeleton := _find_skeleton(root)
	if idle_player == null or skeleton == null:
		idle_inst.queue_free()
		return

	var player := _find_animation_player(root)
	if player == null:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		root.add_child(player)

	var skeleton_path := player.get_path_to(skeleton)
	for library_name: String in idle_player.get_animation_library_list():
		var source_library: AnimationLibrary = idle_player.get_animation_library(library_name)
		if source_library == null:
			continue
		if not player.has_animation_library("kenney"):
			player.add_animation_library("kenney", AnimationLibrary.new())
		var target_library: AnimationLibrary = player.get_animation_library("kenney")
		for anim_name: String in source_library.get_animation_list():
			if target_library.has_animation(anim_name):
				continue
			var animation: Animation = source_library.get_animation(anim_name).duplicate()
			_remap_animation_paths(animation, skeleton_path)
			target_library.add_animation(anim_name, animation)

	idle_inst.queue_free()


func _remap_animation_paths(animation: Animation, skeleton_path: NodePath) -> void:
	for track_idx: int in animation.get_track_count():
		var path := String(animation.track_get_path(track_idx))
		if ":" not in path:
			continue
		var bone_name := path.split(":")[1]
		animation.track_set_path(track_idx, NodePath("%s:%s" % [skeleton_path, bone_name]))


func _apply_skin_texture(root: Node, texture: Texture2D) -> void:
	for mesh_inst: MeshInstance3D in _find_all_mesh_instances(root):
		var surface_count := mesh_inst.mesh.get_surface_count() if mesh_inst.mesh else 1
		for surface_idx: int in surface_count:
			var skin_mat := StandardMaterial3D.new()
			skin_mat.albedo_texture = texture
			skin_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			mesh_inst.set_surface_override_material(surface_idx, skin_mat)


func _find_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var results: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		results.append(node)
	for child: Node in node.get_children():
		results.append_array(_find_all_mesh_instances(child))
	return results


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child: Node in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
