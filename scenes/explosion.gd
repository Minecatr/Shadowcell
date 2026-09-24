extends Area2D

@onready var animation_player = $AnimationPlayer
@export var hit_group := 'Player'
@export var damage := 50
@export var sound := preload("res://assets/sounds/explode.wav")
const sound_node : PackedScene = preload("res://scenes/sound.tscn")

func _ready() -> void:
	animation_player.play("explode")
	var sound_instance := sound_node.instantiate()
	sound_instance.stream = sound
	sound_instance.position = global_position
	GLOBALS.entities.add_child(sound_instance)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if GLOBALS.is_server:
		if body.is_in_group(hit_group):
			body.get_node('HealthBar').change_health(-damage,1.0)
