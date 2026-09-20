extends Node2D

@export var equip_animation : String = 'equip1'
@export var use_animation : String = ''
@export var blacklisted_skills : Array[String] = ['Swingspeed','Ricochet']
@export var firerate_multiplier : int = 2
@export var barrel_length := 25
@export var hit_group := 'Enemy'
@export var double_animations := false

@onready var user := get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var user_animation_player := user.get_node('AnimationPlayer')
@onready var animation_player := $AnimationPlayer
@onready var projectile_spawner := $ProjectileSpawner

func _ready() -> void:
	projectile_spawner.projectile_hit_group = hit_group
	if equip_animation:
		user_animation_player.play(equip_animation)

func use(speed):
	effects.rpc(speed)
	projectile_spawner.fire(
		user.get_node('Body').global_position+Vector2(barrel_length,0).rotated(user.get_node('Body').global_rotation),
		user.get_node('Body').global_rotation,
		user
		)

@rpc("authority","call_local")
func effects(speed):
	if use_animation:
		user_animation_player.speed_scale = speed
		user_animation_player.play(use_animation)
		if double_animations:
			animation_player.speed_scale = speed
			animation_player.play("fire")
	else:
		animation_player.speed_scale = speed
		animation_player.play("fire")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if multiplayer.is_server() and anim_name == 'fire' and not double_animations:
		user.can_use = true
