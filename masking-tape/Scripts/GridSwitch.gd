extends Node
class_name GridSwitch

var grid_index: int = 0
@export var grids: Array[Node]
@export var default_grid_name: String = "GridMap_a"

@export var active_layer: int = 1
@export var active_mask: int = 1
@export var inactive_layer: int = 2
@export var inactive_mask: int = 2

func _ready() -> void:
	if default_grid_name != "":
		set_grid_enabled_only(default_grid_name)
	await get_tree().process_frame
	if default_grid_name != "":
		set_grid_enabled_only(default_grid_name)

func set_grid_enabled_only(grid_name: String) -> void:
	for grid in grids:
		_set_grid_active(grid, grid.name == grid_name)

func _set_grid_active(grid: Node, enabled: bool) -> void:
	if grid is CanvasItem:
		(grid as CanvasItem).visible = enabled
	elif grid is Node3D:
		(grid as Node3D).visible = enabled

	var layer := active_layer if enabled else inactive_layer
	var mask  := active_mask  if enabled else inactive_mask
	_apply_collision_layers_recursive(grid, layer, mask)

func _apply_collision_layers_recursive(node: Node, layer_bits: int, mask_bits: int) -> void:
	if node is GridMap:
		var gm := node as GridMap
		gm.collision_layer = layer_bits
		gm.collision_mask  = mask_bits

	if node is CollisionObject3D:
		var co := node as CollisionObject3D
		co.collision_layer = layer_bits
		co.collision_mask  = mask_bits

	for c in node.get_children():
		_apply_collision_layers_recursive(c, layer_bits, mask_bits)
