extends Node2D

@export var projectile : PackedScene = preload("res://scenes/projectile.tscn")
@export var sound : AudioStreamWAV = preload("res://assets/sounds/shoot.wav")
var sound_node : PackedScene = preload("res://scenes/sound.tscn")

@onready var world := get_tree().root.get_node('world')

func fire(count:int,hit_group:String,bounces:int,drag:float,damage:int,pierce:int,spread:float,spacing:int,speed:int,size:float,sprite,length:int):
	for p in count:
		var spread_rad : float = deg_to_rad(spread)
		var offset : float = (count - 1.0)/2.0
		var spacing_rad : float = deg_to_rad(spacing)
		var projectile_instance : RayCast2D = projectile.instantiate()
		projectile_instance.hit_group = hit_group # What group projectile does damage too (change to array in future)
		projectile_instance.bounces = bounces # How many times projectile can bounce before being destroyed
		projectile_instance.drag = drag # Drag coefficient of projectile
		projectile_instance.damage = damage # Damage of projectile
		projectile_instance.pierce = pierce # How much non-map a projectile can go through
		projectile_instance.armor_pierce = false # Will projectile ignore armor
		projectile_instance.position = global_position
		projectile_instance.scale = Vector2(size,size)
		projectile_instance.rotation = global_rotation + randf_range(-spread_rad,spread_rad) + ((p-offset)*spacing_rad) 
		projectile_instance.speed = speed #+ player.velocity
		projectile_instance.sprite_name = sprite
		projectile_instance.target_position.x = length
		world.add_child(projectile_instance,true)
	play_sound.rpc()

@rpc("authority","call_local")
func play_sound():
	var sound_instance := sound_node.instantiate()
	sound_instance.stream = sound
	sound_instance.position = global_position
	world.add_child(sound_instance)
