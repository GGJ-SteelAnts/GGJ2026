extends Node3D

@export var animation: StringName = "activate"
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

var anim: Animation
var switched: bool = false
var is_active: bool = false

func _ready() -> void:
	anim = animationPlayer.get_animation(animation)

func activate(switched: bool) -> void:
	if switched == true:
		return
	
	animationPlayer.play(animation)
	self.switched = true;

func _process(delta: float) -> void:
	if animationPlayer.current_animation_position == 0 or animationPlayer.current_animation_position == anim.length:
		is_active = false
	else:
		is_active = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		activate(switched)


func _on_area_3d_body_entered_spikes(body: Node3D) -> void:
	if body is Player and is_active:
		body.attacked()
