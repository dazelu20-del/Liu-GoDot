extends Node3D

## Single tree, boulder, or mountain with collision and view-aware offloading.

const TYPE_TREE := 0
const TYPE_BOULDER := 1
const TYPE_MOUNTAIN := 2

const TREE_MODEL := preload("res://assets/Tree (wood source)/realistic_tree.glb")
const BOULDER_MODEL := preload("res://assets/Rock (stone source)/rock.glb")
const MOUNTAIN_MODEL := preload(
	"res://assets/Mountain/rock_mountain_with_cave_realistic_85k_by_jj_fbx.glb"
)
const ContentOffloaderScript := preload("res://scripts/content_offloader.gd")

const TREE_TARGET_HEIGHT := 11.0
const BOULDER_TARGET_SIZE := 2.4
const MOUNTAIN_TARGET_SIZE := 95.0

@export var prop_type: int = TYPE_TREE
@export var prop_scale := 1.0
@export var offload_distance := 200.0
@export var restore_distance := 185.0

var _model: Node3D
var _collision_body: StaticBody3D
var _offloader: Node
var _y_rotation := 0.0


func configure(type: int, scale: float, y_rotation: float) -> void:
	prop_type = type
	prop_scale = scale
	_y_rotation = y_rotation


func build() -> void:
	_spawn_model()
	_finalize_placement()
	_setup_offloader()


func _spawn_model() -> void:
	if _model and is_instance_valid(_model):
		_model.queue_free()

	var scene := _get_model_scene()
	_model = scene.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)


func _get_model_scene() -> PackedScene:
	match prop_type:
		TYPE_BOULDER:
			return BOULDER_MODEL
		TYPE_MOUNTAIN:
			return MOUNTAIN_MODEL
		_:
			return TREE_MODEL


func _finalize_placement() -> void:
	if _model == null or not is_instance_valid(_model):
		return

	_model.rotation = Vector3.ZERO
	_model.position = Vector3.ZERO
	_model.scale = Vector3.ONE
	_model.rotate_y(_y_rotation)
	_normalize_scale()
	_snap_to_ground()
	_build_collision()


func _setup_offloader() -> void:
	if _offloader and is_instance_valid(_offloader):
		_offloader.queue_free()

	_offloader = ContentOffloaderScript.new()
	_offloader.name = "ContentOffloader"
	_offloader.content_root = NodePath("Model")
	_offloader.reload_scene = _get_model_scene()
	_offloader.replace_entire_root = true
	_offloader.view_aware_offload = true
	_offloader.auto_offload_distance = offload_distance
	_offloader.auto_restore_distance = restore_distance
	add_child(_offloader)
	_offloader.content_offloaded.connect(_on_content_offloaded)
	_offloader.content_restored.connect(_on_content_restored)


func _on_content_offloaded() -> void:
	_clear_collision()


func _on_content_restored() -> void:
	_model = _offloader.get_content_root()
	call_deferred("_finalize_placement")


func _build_collision() -> void:
	_clear_collision()
	if _model == null or not is_instance_valid(_model):
		return

	var aabb := _get_local_mesh_aabb(_model)
	if aabb.size == Vector3.ZERO:
		return

	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	add_child(body)
	_collision_body = body

	var shape := BoxShape3D.new()
	match prop_type:
		TYPE_TREE:
			shape.size = Vector3(
				maxf(aabb.size.x * 0.32, 0.6),
				aabb.size.y,
				maxf(aabb.size.z * 0.32, 0.6)
			)
		TYPE_MOUNTAIN:
			shape.size = aabb.size * 0.88
		_:
			shape.size = aabb.size * 0.92

	var col := CollisionShape3D.new()
	col.shape = shape
	col.transform = _model.transform * Transform3D(Basis.IDENTITY, aabb.get_center())
	body.add_child(col)


func _clear_collision() -> void:
	if _collision_body and is_instance_valid(_collision_body):
		_collision_body.queue_free()
	_collision_body = null


func _normalize_scale() -> void:
	var aabb := _get_local_mesh_aabb(_model)
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim < 0.01:
		return

	var target := TREE_TARGET_HEIGHT
	match prop_type:
		TYPE_BOULDER:
			target = BOULDER_TARGET_SIZE
		TYPE_MOUNTAIN:
			target = MOUNTAIN_TARGET_SIZE

	var factor := (target * prop_scale) / max_dim
	_model.scale = Vector3.ONE * factor


func _snap_to_ground() -> void:
	var aabb := _get_local_mesh_aabb(_model)
	if aabb.size == Vector3.ZERO:
		return
	_model.position.y -= aabb.position.y


func _get_local_mesh_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for mesh_inst: MeshInstance3D in _find_mesh_instances(root):
		var mesh_aabb: AABB = (
			root.global_transform.affine_inverse()
			* mesh_inst.global_transform
			* mesh_inst.get_aabb()
		)
		if first:
			merged = mesh_aabb
			first = false
		else:
			merged = merged.merge(mesh_aabb)
	return merged


func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child: Node in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result
