extends Node

@export var grids: Array[Node]

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
			
