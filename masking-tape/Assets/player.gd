extends CharacterBody3D
class_name Player

@export var speed := 14.0
@export var fall_acceleration := 75.0
@export var jump_velocity := 18.0

@export var mouse_sensitivity := 0.002
@export var max_look_up := deg_to_rad(80.0)
@export var max_look_down := deg_to_rad(-80.0)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var interact_label: Label = $UI/Label
@onready var grid_switch: GridSwitch = get_tree().root.get_child(1)

var activeMask: Mask.Type = Mask.Type.NONE

var interactTarget = null

var pitch := 0.0

func _ready() -> void:
	interact_label.text = ""
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
		
	if event.is_action_pressed("interact") and interactTarget != null:
		interactTarget.active(self)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_grid"):
		grid_switch.grid_index = grid_switch.grid_index + 1
		if grid_switch.grid_index > (grid_switch.grids.size() -1):
			grid_switch.grid_index = 0
			grid_switch.set
		grid_switch.set_grid_enabled_only(grid_switch.grids[grid_switch.grid_index].name)
	
	if interactTarget != null:
		interact_label.text = "Press E to interact"
	else:
		interact_label.text = ""

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
		var other := col.get_collider()
		
		if other is PushBox:
			other.action(col.get_normal())

func attacked() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass
