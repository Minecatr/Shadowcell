extends Node

@export var projectile : PackedScene = preload("res://scenes/projectile.tscn")
@export var sound : AudioStreamWAV = preload("res://assets/sounds/shoot.wav")
var sound_node : PackedScene = preload("res://scenes/sound.tscn")

var projectile_hit_group : String = 'Enemy'
@export var projectile_speed : int = 1000
@export var projectile_count : int = 1
@export var projectile_spread : float = 0.0
@export var projectile_spacing : float = 15.0
@export var projectile_bounces : int = 0
@export var projectile_drag : float = 0.99
@export var projectile_pierce : int = 0
@export var projectile_damage : int = 3
@export var projectile_rotation_speed : float = 0
@export var projectile_knockback : int = 0
@export var projectile_stun : int = 0

@export var sprite := 'bullet'

@onready var world := get_tree().root.get_node('world')
@onready var entities := world.get_node('Entities')

var spread_rad : float = deg_to_rad(projectile_spread)

func fire(spawn_position: Vector2, spawn_rotation: float, user : Node = null):
	var true_projectile_count = projectile_count + ((user.skills['Multishot']+(5 if user.ability == 'Barrage' else 0)) if user.has_skills else 0)
	var offset : float = (true_projectile_count - 1.0)/2.0
	var spacing_rad : float = deg_to_rad(projectile_spacing) * (0.5 if user.has_skills and user.ability == 'Barrage' else 1.0)
	for p in true_projectile_count:
		var projectile_instance : RayCast2D = projectile.instantiate()
		
		projectile_instance.position = spawn_position
		projectile_instance.rotation = spawn_rotation + randf_range(-spread_rad,spread_rad) + ((p-offset)*spacing_rad) 

		projectile_instance.hit_group = projectile_hit_group # What group projectile does damage too (change to array in future)
		projectile_instance.bounces = projectile_bounces + (user.skills['Ricochet'] if user.has_skills else 0) # How many times projectile can bounce before being destroyed
		projectile_instance.stun = projectile_stun + (user.skills['Stunning'] if user.has_skills else 0)
		projectile_instance.drag = projectile_drag # Drag coefficient of projectile
		projectile_instance.damage = projectile_damage * ((1+user.skills['Damage']+(1 if user.ability == 'Deadly' else 0)) if user.has_skills else 1)# Damage of projectile
		projectile_instance.pierce = projectile_pierce + (user.skills['Pierce'] if user.has_skills else 0) # How much non-map a projectile can go through
		var projectile_scale = 1+0.5*float(user.skills['Size']) if user.has_skills else 1.0
		projectile_instance.speed = projectile_speed + (user.skills['Velocity']*333 if user.has_skills else 0) #+ player.velocity NO RELATIVIYT SO UNREALISTICU!
		projectile_instance.scale = Vector2(projectile_scale * (projectile_instance.speed/1000 if projectile_instance.speed > 1000 else 1),projectile_scale)
		projectile_instance.sprite_name = sprite # if not user or user.skills['Velocity'] < 2 else high_speed_sprite
		#projectile_instance.target_position.x = length if not user or user.skills['Velocity'] < 2 else high_speed_length
		projectile_instance.rotation_speed = projectile_rotation_speed
		projectile_instance.knockback = projectile_knockback + (user.skills['Knockback']*25 if user.has_skills else 0)
		entities.add_child(projectile_instance,true)
	play_sound.rpc()

@rpc("authority","call_local")
func play_sound():
	var sound_instance := sound_node.instantiate()
	sound_instance.stream = sound
	sound_instance.position = get_parent().global_position
	entities.add_child(sound_instance)

#@onready var curves_data:BulletCurvesData2D = preload("res://curves_data.tres")

#@export var sprite : CompressedTexture2D = preload("res://assets/sprites/weapons/bullet.svg")
#var bullets_data:DirectionalBulletsData2D

#func _ready() -> void:
	#bullets_data = DirectionalBulletsData2D.new()
	#bullets_data.textures = [sprite]
	#
	#bullets_data.texture_size = Vector2(sprite.get_width(),sprite.get_height())
	#bullets_data.max_life_time = 5.0
	#
	#bullets_data.collision_shape_size = bullets_data.texture_size
	#
	#bullets_data.set_collision_layer_from_array([])
	#bullets_data.set_collision_mask_from_array([1,2])
	#bullets_data.monitorable = true
	
#@rpc("authority","call_local")
#func fire(spawn_position: Vector2, spawn_rotation: float, user_skills : Dictionary = {}, user_ability: String = ''):
	#var true_projectile_count = projectile_count + ((user_skills['Multishot']+(5 if user_ability == 'Barrage' else 0)) if user_skills else 0)
	#var offset : float = (true_projectile_count - 1.0)/2.0
	#var spacing_rad : float = deg_to_rad(projectile_spacing) * (0.5 if user_ability and user_ability == 'Barrage' else 1.0)
	#
	#var speed : BulletSpeedData2D = BulletSpeedData2D.new()
	##speed.acceleration = projectile_drag
	#speed.speed = projectile_speed + (user_skills['Velocity']*333 if user_skills else 0)
	#speed.max_speed = 2*speed.speed
	#
	#var rotational := BulletRotationData2D.new()
	#rotational.rotation_speed = projectile_rotation_speed
	#rotational.max_rotation_speed = rotational.rotation_speed*2
	#
	#bullets_data.transforms = []
	#bullets_data.all_bullet_speed_data = []
	#bullets_data.all_bullet_rotation_data = []
	#
	#var damage_data = DamageData.new()
	#damage_data.damage = projectile_damage * ((1+user_skills['Damage']+(1 if user_ability == 'Deadly' else 0)) if user_skills else 1)
	#damage_data.hit_group = projectile_hit_group
	#damage_data.bounces = projectile_bounces + (user_skills['Ricochet'] if user_skills else 0)
	#damage_data.knockback = projectile_knockback + (user_skills['Knockback']*500 if user_skills else 0)
#
	#bullets_data.bullet_max_collision_count = 1+damage_data.bounces+projectile_pierce + (user_skills['Pierce'] if user_skills else 0)
	#bullets_data.bullets_custom_data = damage_data
	#for p in true_projectile_count:
		#bullets_data.all_bullet_rotation_data.append(rotational)
		#bullets_data.all_bullet_speed_data.append(speed)
		#bullets_data.transforms.append(Transform2D(
		#spawn_rotation + randf_range(-spread_rad,spread_rad) + ((p-offset)*spacing_rad),
		#Vector2.ONE*0.5*(1+0.5*float(user_skills['Size']) if user_skills else 1.0),
		#0.0,
		#spawn_position
		#))
	#
	#if user_skills and user_skills['Ricochet'] > 0:
		#var bullets_multi:DirectionalBullets2D = GLOBALS.BULLET_FACTORY.spawn_controllable_directional_bullets(bullets_data)
		##curves_data.movement_speed_curve.set_point_value(0,speed.speed)
		##bullets_multi.shared_bullet_curves_data = curves_data
		#bullets_multi.homing_take_control_of_texture_rotation = false
		#bullets_multi.homing_smoothing = 5
		#bullets_multi.homing_update_interval = 0.2
		#bullets_multi.homing_distance_before_reached = 15
		#for entity in entities.get_children():
			#if entity.is_in_group(projectile_hit_group):
				#bullets_multi.shared_homing_deque_push_back_node2d_target(entity)
		#bullets_multi.shared_homing_deque_auto_pop_after_target_reached = true
	#else:
		#GLOBALS.BULLET_FACTORY.spawn_directional_bullets(bullets_data)
	#var sound_instance := sound_node.instantiate()
	#sound_instance.stream = sound
	#sound_instance.position = get_parent().global_position
	#entities.add_child(sound_instance)
