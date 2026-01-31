extends CharacterBody3D

@export var speed: float = 14.0
@export var fall_acceleration: float = 75.0
@export var jump_velocity: float = 18.0

@export var mouse_sensitivity: float = 0.002
@export var max_look_up: float = deg_to_rad(80)
@export var max_look_down: float = deg_to_rad(-80)

@export var drag_repeat_delay: float = 0.14
@export var drag_first_delay: float = 0.08
@export var grids: Array[Node]

@onready var grab_ray: RayCast3D = $GrabRay
@onready var camera_pivot: Node3D = $CameraPivot

var grabbed_box: PushBox = null
var pitch: float = 0.0
var target_velocity: Vector3 = Vector3.ZERO

var _drag_timer: float = 0.0
var _last_drag_dir: Vector3 = Vector3.ZERO

@onready var player_col: CollisionShape3D = $CollisionShape3D
var _player_step_moving: bool = false

func set_grid_enabled(grid_name: String, enabled: bool) -> void:
	for grid in grids:
		if grid.name == grid_name:
			grid.visible = enabled

func set_grid_enabled_only(grid_name: String) -> void:
	for grid in grids:
		if grid.name == grid_name:
			grid.visible = true
		else:
			grid.visible = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, max_look_down, max_look_up)
		camera_pivot.rotation.x = pitch

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_grab()
		else:
			_release_grab()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_grid"):
		set_grid_enabled_only(grids[1].name)

func _physics_process(delta: float) -> void:
	var input_dir := _get_input_dir()

	var move_world: Vector3 = (global_transform.basis * input_dir)
	move_world.y = 0.0
	if move_world.length() > 0.0:
		move_world = move_world.normalized()

	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
	else:
		if Input.is_action_just_pressed("jump"):
			target_velocity.y = jump_velocity
		else:
			target_velocity.y = 0.0

	if grabbed_box != null:
		target_velocity.x = 0.0
		target_velocity.z = 0.0
	else:
		target_velocity.x = move_world.x * speed
		target_velocity.z = move_world.z * speed
	
	if grabbed_box != null:
		_handle_dragging(delta, move_world)
	else:
		_try_push_only(move_world)

	velocity = target_velocity
	move_and_slide()


func _get_input_dir() -> Vector3:
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1.0
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1.0
	return input_dir.normalized()


func _handle_dragging(delta: float, move_world: Vector3) -> void:
	if grabbed_box == null:
		return
	if _player_step_moving or grabbed_box.is_moving():
		return

	if move_world.length() < 0.1:
		_drag_timer = 0.0
		_last_drag_dir = Vector3.ZERO
		return

	var dir := _to_cardinal_world(move_world)

	var dir_changed := dir != _last_drag_dir
	if dir_changed:
		_last_drag_dir = dir
		_drag_timer = 0.0

	_drag_timer -= delta
	if _drag_timer > 0.0:
		return

	var cell := grabbed_box.cell_size
	var origin := grabbed_box.grid_origin

	var box_target := _snap_to_grid(grabbed_box.global_position + dir * cell, cell, origin)
	var player_target := _snap_to_grid(global_position + dir * cell, cell, origin)
	player_target.y = global_position.y

	var can_box := grabbed_box.can_occupy_at(box_target, [self.get_rid()])
	var can_player := _can_player_occupy_at(player_target, [grabbed_box.get_rid()])

	if can_box and can_player:
		grabbed_box.move_to(box_target)

		_player_step_moving = true
		var t := create_tween()
		t.tween_property(self, "global_position", player_target, grabbed_box.move_time)
		t.finished.connect(func(): _player_step_moving = false)

		_drag_timer = drag_repeat_delay
		if dir_changed:
			_drag_timer = drag_first_delay
	else:
		_drag_timer = drag_repeat_delay


func _block_player_into_dir(cardinal_dir: Vector3) -> void:
	var move_h := Vector3(target_velocity.x, 0.0, target_velocity.z)
	var into := cardinal_dir.normalized()
	var amount := move_h.dot(into)
	if amount > 0.0:
		move_h -= into * amount
		target_velocity.x = move_h.x
		target_velocity.z = move_h.z


func _to_cardinal_world(dir: Vector3) -> Vector3:
	dir.y = 0.0
	if abs(dir.x) > abs(dir.z):
		return Vector3(signf(dir.x), 0.0, 0.0)
	else:
		return Vector3(0.0, 0.0, signf(dir.z))


func _try_grab() -> void:
	if grabbed_box != null:
		return

	grab_ray.force_raycast_update()
	if not grab_ray.is_colliding():
		return

	var c := grab_ray.get_collider()
	if c is PushBox:
		var box := c as PushBox
		if box.mode != PushBox.Mode.GRABBABLE:
			return
		grabbed_box = box
		grabbed_box.grabbed = true
		_drag_timer = 0.0
		_last_drag_dir = Vector3.ZERO


func _release_grab() -> void:
	if grabbed_box == null:
		return
	grabbed_box.grabbed = false
	grabbed_box = null
	_drag_timer = 0.0
	_last_drag_dir = Vector3.ZERO


func _try_push_only(move_dir: Vector3) -> void:
	if move_dir.length() < 0.1:
		return

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var c := col.get_collider()
		if c is PushBox:
			var box := c as PushBox
			if box.mode != PushBox.Mode.PUSH_ONLY:
				continue

			var into_box: Vector3 = -col.get_normal()
			into_box.y = 0.0
			if into_box.length() < 0.001:
				continue
			into_box = into_box.normalized()

			var md := move_dir.normalized()
			if md.dot(into_box) < 0.6:
				continue

			box.try_push(into_box)
			break

func _snap_to_grid(pos: Vector3, cell: float, origin: Vector3) -> Vector3:
	var p := pos - origin
	p.x = snapped(p.x, cell)
	p.z = snapped(p.z, cell)
	return p + origin


func _can_player_occupy_at(world_pos: Vector3, extra_exclude: Array = []) -> bool:
	if player_col == null or player_col.shape == null:
		return false

	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = player_col.shape
	
	var offset: Vector3 = player_col.global_transform.origin - global_position
	params.transform = Transform3D(player_col.global_transform.basis, world_pos + offset)

	params.exclude = [self.get_rid()]
	params.exclude.append_array(extra_exclude)

	params.collide_with_bodies = true
	params.collide_with_areas = false

	return space_state.intersect_shape(params, 1).is_empty()
