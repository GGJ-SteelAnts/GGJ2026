extends CharacterBody3D

@export var speed: float = 14.0
@export var fall_acceleration: float = 75.0
@export var jump_velocity: float = 18.0

@export var mouse_sensitivity: float = 0.002
@export var max_look_up: float = deg_to_rad(80)
@export var max_look_down: float = deg_to_rad(-80)

@export var push_speed: float = 4.0       
@export var push_accel: float = 18.0      
@export var max_push_mass: float = 80.0

@export var grab_distance: float = 1.1
@export var grab_lerp: float = 25.0
@export var grab_move_speed: float = 6.0

@onready var grab_ray: RayCast3D = $GrabRay
@onready var camera_pivot: Node3D = $CameraPivot

var grab_block_dir: Vector3 = Vector3.ZERO
var grabbed_box: PushBox = null
var pitch: float = 0.0
var target_velocity: Vector3 = Vector3.ZERO

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

func _physics_process(delta: float) -> void:
	var input_dir: Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1.0
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1.0

	input_dir = input_dir.normalized()

	var direction: Vector3 = (global_transform.basis * input_dir)
	direction.y = 0.0
	if direction.length() > 0.0:
		direction = direction.normalized()

	var current_speed: float = speed
	if grabbed_box != null:
		current_speed = min(speed, grab_move_speed)

	target_velocity.x = direction.x * current_speed
	target_velocity.z = direction.z * current_speed

	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
	else:
		if Input.is_action_just_pressed("jump"):
			target_velocity.y = jump_velocity
		else:
			target_velocity.y = 0.0
	
	if grabbed_box != null:
		if not _update_grabbed_box(delta):
			var block_dir: Vector3 = grab_block_dir
			block_dir.y = 0.0

			if block_dir.length() < 0.001:
				block_dir = grabbed_box.global_position - global_position
				block_dir.y = 0.0

			if block_dir.length() > 0.001:
				block_dir = block_dir.normalized()

				var move_h: Vector3 = Vector3(target_velocity.x, 0.0, target_velocity.z)

				var amount := move_h.dot(block_dir)
				if amount > 0.0:
					move_h -= block_dir * amount
					target_velocity.x = move_h.x
					target_velocity.z = move_h.z
	
	velocity = target_velocity
	move_and_slide()

func _try_grab() -> void:
	if grabbed_box != null:
		return

	grab_ray.force_raycast_update()
	if not grab_ray.is_colliding():
		return

	var c := grab_ray.get_collider()
	if c is PushBox:
		grabbed_box = c as PushBox
		grabbed_box.grabbed = true

func _release_grab() -> void:
	if grabbed_box == null:
		return
	grabbed_box.grabbed = false
	grabbed_box = null

func _update_grabbed_box(delta: float) -> bool:
	if grabbed_box == null:
		return true

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		return true
	forward = forward.normalized()

	var desired_pos: Vector3 = global_position + forward * grab_distance
	desired_pos.y = grabbed_box.global_position.y

	var new_pos: Vector3 = grabbed_box.global_position.lerp(desired_pos, min(1.0, grab_lerp * delta))

	grab_block_dir = new_pos - grabbed_box.global_position
	grab_block_dir.y = 0.0

	if grabbed_box.can_occupy_at(new_pos, [self]):
		grabbed_box.global_position = new_pos
		grab_block_dir = Vector3.ZERO
		return true

	return false
