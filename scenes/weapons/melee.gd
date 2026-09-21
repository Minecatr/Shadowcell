extends Node2D

@export var weapon_hit_group : String = 'Enemy'
@export var weapon_damage : int = 3
@export var weapon_knockback : int = 0
var armor_pierce := 0.0


@export var blacklisted_skills : Array[String] = ['Firerate','Multishot','Pierce','Seeking','Ricochet','Velocity','Shattering']
@export var firerate_multiplier : int = 2

@export var equip_animation : String = 'equip2'
@export var use_animation : String = 'swing'

@onready var user := get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var user_animation_player := user.get_node('AnimationPlayer')

@onready var animation_player := $AnimationPlayer

var hit : Array = []

func _ready() -> void:
	if equip_animation:
		user_animation_player.play(equip_animation)

#func _process(_delta: float) -> void:
	#scale = Vector2.ONE*(1+(float(user.skills['Size'])*0.5))

func use(speed):
	hit = []
	scale = Vector2.ONE*(1+(float(user.skills['Size'])*0.25) if user.has_skills else 1.0)
	if use_animation:
		if user.has_skills and user.ability == 'Spinjitsu':
			effects.rpc('spin',5,1)
		else:
			effects.rpc(use_animation,speed,speed)

@rpc("authority","call_local")
func effects(user_animation, speed, user_speed := 0):
	animation_player.speed_scale = speed
	user_animation_player.speed_scale = user_speed
	animation_player.play("use")
	user_animation_player.play(user_animation)
	#else:
		#animation_player.speed_scale = speed
		#animation_player.play("fire")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if multiplayer.is_server() and body.is_in_group(weapon_hit_group) and !hit.has(body):
		hit.append(body)
		var stun = 0+(0.1*user.skills['Stunning'] if user.has_skills else 0)
		if stun > 0:
			body.get_node('Stun').stun(stun,armor_pierce)
		var knockback = weapon_knockback+(user.skills['Knockback']*25 if user.has_skills else 0)
		if knockback:
			body.knockback += Vector2(knockback,0).rotated(user.body.rotation) #.rotated(rotation)
		body.get_node('HealthBar').change_health(-weapon_damage*((1+user.skills['Damage']+(1 if user.ability == 'Deadly' else 0)) if user.has_skills else 1),armor_pierce)
