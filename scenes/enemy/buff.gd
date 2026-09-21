extends CharacterBody2D

const MASS = 1.0

@export var speed := 10000
@export var damage := 10
@export var armor_pierce := false
@export var target_range := 64
@onready var is_server := multiplayer.is_server()
@onready var root := get_tree().root
@onready var world := root.get_node('world')
@export var target = false
@export var use_speed := 1.0

@onready var nav_timer := $Timer
@onready var body := $Body
@onready var animation_player := $AnimationPlayer

const has_skills := false
@export var flee := 0

var knockback := Vector2.ZERO
var desired_velocity := Vector2.ZERO

var go_to_pos = false
var can_use := true
var stunned := false
var charging := false

func _ready() -> void:
	animation_player.play('character_animations/punch')
	if is_server:
		world.level_activated.connect(activate)
		world.change_enemies(use_speed)

func _physics_process(delta: float) -> void:
	if not is_server: return
	if target:
		if not target.dead:
			if not charging: 
				body.look_at(target.global_position)
				desired_velocity = Vector2.ZERO
			var distance = position.distance_to(target.global_position)
			if not stunned:
				if distance < flee and not charging:
					desired_velocity = -(target.position - position).normalized()
				if distance > target_range:
					if not charging:
						desired_velocity = (target.position - position).normalized() 
				elif can_use:
					can_use = false
					animation_player.play('character_animations/punch')
					target.get_node('HealthBar').change_health(-damage)
			velocity = (lerp(velocity, desired_velocity * speed, MASS)+knockback*1000) * delta
			knockback = Vector2(lerp((knockback.length()),0.0,0.2),0).rotated(knockback.angle())
			move_and_slide()
		else:
			set_target()

func set_target():
	if is_server and world.players.size() > 0:
		target = null
		for player in world.players:
			if not player.dead:
				var target_distance = global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < global_position.distance_to(target.global_position):
					target = player

func _on_timer_timeout() -> void:
	if is_server:
		set_target()

func activate():
	set_target()
	nav_timer.start()
	$ChargeTimer.start()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	can_use = true

func _on_charge_timer_timeout() -> void:
	speed *= 5
	charging = true
	stunned = false
	$ChargeDuration.start()


func _on_charge_duration_timeout() -> void:
	speed /= 5
	charging = false
