extends CharacterBody3D
class_name PushBox

@export var cell_size: float = 1.0
@export var move_time: float = 0.12

var _moving: bool = false
var grabbed: bool = false

@onready var col_shape: CollisionShape3D = $CollisionShape3D

func try_push(dir: Vector3) -> bool:
	if grabbed:
		return false
	if _moving:
		return false

	return false

func can_occupy_at(world_pos: Vector3, extra_exclude: Array = []) -> bool:
	if col_shape == null or col_shape.shape == null:
		return false

	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = col_shape.shape
	params.transform = Transform3D(global_transform.basis, world_pos)

	var ex := [self]
	ex.append_array(extra_exclude)
	params.exclude = ex

	params.collide_with_bodies = true
	params.collide_with_areas = false

	var hits: Array = space_state.intersect_shape(params, 1)
	return hits.is_empty()
