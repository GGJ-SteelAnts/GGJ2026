extends CharacterBody3D
class_name PushBox

enum Mode { GRABBABLE, PUSH_ONLY }
@export var mode: Mode = Mode.GRABBABLE

func action(push_dir: Vector3) -> void:
	match mode:
		Mode.GRABBABLE:
			print("Grabbable")
		Mode.PUSH_ONLY:
			global_position -= push_dir

func _can_move(move_direction: Vector3) -> void:
	pass
