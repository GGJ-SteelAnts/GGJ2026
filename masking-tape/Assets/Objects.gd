extends CharacterBody3D
class_name PushBox

enum Mode { GRABBABLE, PUSH_ONLY }
@export var mode: Mode = Mode.GRABBABLE

@export var cell_size: float = 1.0
@export var move_time: float = 0.12
@export var grid_origin: Vector3 = Vector3.ZERO

var _moving: bool = false
var grabbed: bool = false

@onready var col_shape: CollisionShape3D = $CollisionShape3D


func is_moving() -> bool:
	return _moving


func move_to(target_pos: Vector3) -> void:
	if _moving:
		return

	_moving = true
	var t := create_tween()
	t.tween_property(self, "global_position", target_pos, move_time)
	t.finished.connect(func(): _moving = false)


func try_push(world_dir: Vector3) -> bool:
	if grabbed or _moving:
		return false

	var dir := _to_cardinal_world(world_dir)
	if dir.length() < 0.9:
		return false

	return _step_to(dir, [])


func try_drag(world_dir: Vector3, extra_exclude: Array = []) -> bool:
	if _moving:
		return false

	var dir := _to_cardinal_world(world_dir)
	if dir.length() < 0.9:
		return false

	return _step_to(dir, extra_exclude)

func _step_to(cardinal_dir: Vector3, extra_exclude: Array) -> bool:
	var target_pos := _snap_to_grid(global_position + cardinal_dir * cell_size)

	if not can_occupy_at(target_pos, extra_exclude):
		return false

	move_to(target_pos)
	return true


func can_occupy_at(world_pos: Vector3, extra_exclude: Array = []) -> bool:
	if col_shape == null or col_shape.shape == null:
		return false

	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = col_shape.shape
	params.transform = Transform3D(global_transform.basis, world_pos)
	params.exclude = [self.get_rid()]
	params.exclude.append_array(extra_exclude)
	params.collide_with_bodies = true
	params.collide_with_areas = false

	return space_state.intersect_shape(params, 1).is_empty()


func _to_cardinal_world(dir: Vector3) -> Vector3:
	dir.y = 0.0
	if abs(dir.x) > abs(dir.z):
		return Vector3(signf(dir.x), 0.0, 0.0)
	else:
		return Vector3(0.0, 0.0, signf(dir.z))


func _snap_to_grid(pos: Vector3) -> Vector3:
	var p := pos - grid_origin
	p.x = snapped(p.x, cell_size)
	p.z = snapped(p.z, cell_size)
	return p + grid_origin
