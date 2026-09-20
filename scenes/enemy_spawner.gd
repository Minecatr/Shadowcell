extends Node2D

@export var enemy := preload('res://scenes/enemy/sunchain.tscn')
@onready var parent := get_parent()
@onready var root := get_tree().root
@onready var world := root.get_node('world')
@onready var entities := world.get_node('Entities')

func _ready() -> void:
	parent.redstone.connect(activate)

func activate():
	if multiplayer.is_server():
		var enemy_instance = enemy.instantiate()
		enemy_instance.position = global_position
		entities.call_deferred('add_child',enemy_instance,true)
