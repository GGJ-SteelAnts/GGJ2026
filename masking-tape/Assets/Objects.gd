extends CharacterBody3D
class_name PushBox

enum Mode { GRABBABLE, PUSH_ONLY }
@export var mode: Mode = Mode.GRABBABLE

@export var fall_acceleration := 75.0
@export var push_step: float = 1.0 
@export var push_time: float = 0.50
@export var push_cooldown: float = 0.15

var _entered: bool = false
var _tween: Tween = null
var _moving: bool = false

func action(push_dir: Vector3) -> void:
	match mode:
		Mode.GRABBABLE:
			print("Grabbable")
		Mode.PUSH_ONLY:
			if _moving:
				return
			var motion := -push_dir.normalized() * push_step

			if test_move(global_transform, motion) and _entered:
				return
				
			var target : Vector3 = global_position + motion

			_moving = true
			_tween = create_tween()
			_tween.tween_property(self, "global_position", target, push_time)
			_tween.tween_interval(push_cooldown)
			_tween.finished.connect(func(): 
				_moving = false
				_tween = null
			)

func _physics_process(delta: float) -> void:
	move_and_slide()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is not Player and body != self:
		_entered = true
		if _tween:
			_tween.kill()
			_tween = null
		_moving = false


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is not Player and body != self:
		_entered = false
