extends StaticBody3D

@export var animation: StringName = "activate"
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

var anim: Animation
var switched: bool = false
var is_active: bool = false

func _ready() -> void:
	anim = animationPlayer.get_animation(animation)

func activate(switched: bool) -> void:
	if switched == false:
		animationPlayer.play_backwards(animation)
		switched = true;
	else:
		animationPlayer.play(animation)
		switched = false;

func _process(delta: float) -> void:
	if animationPlayer.current_animation_position == 0:
		is_active = true
	elif animationPlayer.current_animation_position == anim.length:
		is_active = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		activate(true)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		activate(false)


func _on_area_3d_body_entered_spikes(body: Node3D) -> void:
	if body is Player:
		body.attacked()

func _on_area_3d_body_exited_spikes(body: Node3D) -> void:
	if body is Player:
		body.attacked()
