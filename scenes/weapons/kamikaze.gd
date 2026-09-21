extends Node2D

@export var weapon_hit_group : String = 'Enemy'
const explosion := preload("res://scenes/explosion.tscn")

@onready var world := get_tree().root.get_node('world')
@onready var entities := world.get_node('Entities')

@onready var user := get_parent().get_parent().get_parent().get_parent().get_parent()

func use(_speed):
	var explosion_instance : Area2D= explosion.instantiate()
	explosion_instance.scale = Vector2.ONE*1.5
	explosion_instance.position = user.global_position
	explosion_instance.damage = 100
	explosion_instance.hit_group = weapon_hit_group
	entities.add_child(explosion_instance)
	user.get_node('HealthBar').die()
