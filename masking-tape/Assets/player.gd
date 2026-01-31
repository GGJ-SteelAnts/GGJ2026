extends CharacterBody3D

@export var speed := 14.0
@export var fall_acceleration := 75.0
@export var jump_velocity := 18.0

@export var mouse_sensitivity := 0.002
@export var max_look_up := deg_to_rad(80.0)
@export var max_look_down := deg_to_rad(-80.0)

var grid_index: int = 0
@export var grids: Array[Node]

@onready var camera_pivot: Node3D = $CameraPivot

var pitch := 0.0

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
		pitch = clamp(
			pitch - event.relative.y * mouse_sensitivity,
			max_look_down,
			max_look_up
		)
		camera_pivot.rotation.x = pitch

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_grid"):
		grid_index = grid_index + 1
		if grid_index > (grids.size() -1):
			grid_index = 0
		set_grid_enabled_only(grids[grid_index].name)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var dir := (global_transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if is_on_floor():
		velocity.y = jump_velocity if Input.is_action_just_pressed("jump") else 0.0
	else:
		velocity.y -= fall_acceleration * delta

	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision3D = get_slide_collision(i)

		var other := col.get_collider()          # Node/Object, do čeho jsi narazil
		if other is PushBox:
			other.action(col.get_normal())
