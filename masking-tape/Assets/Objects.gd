extends CharacterBody3D
class_name PushBox

enum Mode { GRABBABLE, PUSH_ONLY }
@export var mode: Mode = Mode.GRABBABLE

@export var push_step: float = 1.0 
@export var push_time: float = 0.50
@export var push_cooldown: float = 0.15

var _tween: Tween = null
var _moving: bool = false

func action(push_dir: Vector3) -> void:
	match mode:
		Mode.GRABBABLE:
			print("Grabbable")
		Mode.PUSH_ONLY:
			if _moving:
				return
			var target : Vector3 = global_position - (push_dir * push_step)

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

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other := col.get_collider()

		if other is PushBox:
			if _tween:
				_tween.kill()
				_tween = null
			_moving = false
			
