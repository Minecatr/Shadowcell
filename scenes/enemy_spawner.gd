extends Node2D

@export var enemy := preload('res://scenes/enemy.tscn')
@onready var parent := get_parent()
@onready var root := get_tree().root
@onready var world := root.get_node('world')
@onready var is_server := multiplayer.is_server()

func _ready() -> void:
	if is_server:
		parent.redstone.connect(activate)

func activate():
	if is_server:
		var enemy_instance = enemy.instantiate()
		enemy_instance.position = global_position
		world.call_deferred('add_child',enemy_instance,true)
