extends StaticBody2D

signal redstone

@onready var animation_player = $AnimationPlayer
#@onready var is_server := multiplayer.is_server()
@onready var root := get_tree().root
@onready var world := root.get_node('world')

@export var open = false

func _on_entry_body_entered(body: Node2D) -> void:
	if multiplayer.is_server() and !open and world.enemies <= 0 and body.is_in_group('Player'):
		open = true
		open_animation.rpc()
		emit_signal('redstone')

@rpc("authority","call_local")
func open_animation():
	animation_player.play("open")
