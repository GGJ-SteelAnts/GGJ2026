extends Node3D
class_name Mask

enum Type { RED=0, GREEN=1, BLUE=2, NONE=3 }
@export var mask_ui: CompressedTexture2D
@export var type: Type = Type.RED
@export var materials_by_mode: Array[Material] = []
@onready var item: Node3D = $Pivot
@onready var mesh_instance: MeshInstance3D = $Pivot/MeshInstance3D
@onready var mesh_instance2: MeshInstance3D = $Pivot/MeshInstance3D2
@onready var mesh_instance3: MeshInstance3D = $Pivot/MeshInstance3D3

func _ready() -> void:
	var idx := int(type)
	if idx < 0 or idx >= materials_by_mode.size():
		return
	var mat := materials_by_mode[idx]
	if mat == null:
		return
	mesh_instance.material_override = mat
	mesh_instance2.material_override = mat
	mesh_instance3.material_override = mat
	

func active(player: Player) -> void:
	if player.activeMask != Mask.Type.NONE:
		var scene := preload("res://Assets/mask.tscn")
		var instance := scene.instantiate()
		instance.type = player.activeMask;
		instance.global_transform = player.global_transform
		get_tree().current_scene.add_child(instance)
	
	player.activeMask = type
	player.get_node('UI/CurrentMask').texture = mask_ui
	player.interactTarget = null
	queue_free()
	pass

func _physics_process(delta: float) -> void:
	item.rotate(Vector3(0,1,0), 0.02)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.interactTarget = self


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player and body.interactTarget == self:
		body.interactTarget = null
