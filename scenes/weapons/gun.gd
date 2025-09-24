extends Node2D

@export var projectile_speed : int = 1000
@export var projectile_count : int = 1
@export var projectile_spread : float = 0.0
@export var projectile_spacing : float = 30.0
@export var projectile_bounces : int = 1
@export var projectile_drag : float = 0.99
@export var projectile_pierce : int = 0
@export var projectile_damage : int = 3
@export var equip_animation : String = 'equip1'
@export var blacklisted_skills : Array[String] = ['Swingspeed']
@export var firerate_multiplier : int = 2
@export var sprite := 'res://assets/projectiles/bullet.svg'
@export var high_speed_sprite := 'res://assets/projectiles/bullet.svg'
@export var length := 40
@export var high_speed_length := 40

@onready var user := get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var animation_player := $AnimationPlayer
@onready var projectile_spawner := $ProjectileSpawner

func use(speed):
	effects.rpc(speed)
	projectile_spawner.fire(
		projectile_count+user.skills['Multishot']+(5 if user.ability == 'Barrage' else 0),
		'Enemy',
		projectile_bounces+user.skills['Ricochet'],
		projectile_drag,
		projectile_damage+user.skills['Damage']+(1 if user.ability == 'Deadly' else 0),
		projectile_pierce+user.skills['Pierce'],
		projectile_spread,
		projectile_spacing*(0.5 if user.ability == 'Barrage' else 1.0),
		projectile_speed+(user.skills['Velocity']*333),
		1.0+(float(user.skills['Size'])*0.5),
		(sprite if user.skills['Velocity'] < 2 else high_speed_sprite),
		(length if user.skills['Velocity'] < 2 else high_speed_length)
		)

@rpc("authority","call_local")
func effects(speed):
	animation_player.speed_scale = speed
	animation_player.play("fire")
