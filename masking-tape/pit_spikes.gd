extends Node3D

func _on_danger_body_entered(body: Node3D) -> void:
	if body is Player:
		body.attacked()

func _on_boulder_body_entered(body: Node3D) -> void:
	if body is PushBox:
		body._moving = true
		var targrt = self.global_position
		targrt.y = body.global_position.y
		var t: Tween = create_tween()
		t.tween_property(body, "global_position", targrt, 0.5)
		t.finished.connect(func(): 
			var t2: Tween = create_tween()
			t2.tween_property(body, "global_position", self.global_position, 0.5)
		)
