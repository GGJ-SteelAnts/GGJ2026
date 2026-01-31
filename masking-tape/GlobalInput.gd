extends Node

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().current_scene.name == "Menu":
			get_tree().quit()
		else:
			get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
