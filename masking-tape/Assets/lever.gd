extends Node3D

@export var animation: StringName = "switch"
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

var anim: Animation
var switched: bool = false
var is_active: bool = false

func _ready() -> void:
	anim = animationPlayer.get_animation(animation)
	animationPlayer.current_animation = animation
	animationPlayer.seek(anim.length, true)

func active(player: Player) -> void:
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
		body.interactTarget = self

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player and body.interactTarget == self:
		body.interactTarget = null
