extends CharacterBody2D

const MASS = 1.0

@export var speed := 10000
@export var target_range := 64
@onready var is_server := multiplayer.is_server()
@onready var root := get_tree().root
@onready var world := root.get_node('world')
#@onready var tilemap : TileMapDual = world.get_node('Map')
@export var target = false
@export var use_speed := 1.0

@onready var nav_timer := $Timer
@onready var body := $Body
@onready var animation_player := $AnimationPlayer
@onready var weapon := $Body/Arms/RightArm/Hand.get_child(0)

const has_skills := false
@export var flee := 0

#@export var equip_animation :='character_animations/equip-sword'
#@export var animation :='character_animations/sweep'

var knockback := Vector2.ZERO
var desired_velocity := Vector2.ZERO

#var pathfinding_grid := AStarGrid2D.new()
#var path_to_player := []
var go_to_pos = false
var can_use := true
var stunned := false

func _ready() -> void:
	weapon.weapon_hit_group = 'Player'
	#animation_player.play(equip_animation)
	if is_server:
		world.level_activated.connect(activate)
		world.change_enemies(1)
		
		#pathfinding_grid.region = tilemap.get_used_rect()
		#pathfinding_grid.cell_size = Vector2(TILE_SIZE,TILE_SIZE)
		#pathfinding_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		#pathfinding_grid.update()
		#
		#for cell in tilemap.get_used_cells():
			#pathfinding_grid.set_point_solid(cell, true)
		
		#set_target()
		#move_ai()

func _physics_process(delta: float) -> void:
	if not is_server: return
	if target:
		if not target.dead:
			body.look_at(target.global_position)
			var distance = position.distance_to(target.global_position)
			desired_velocity = Vector2.ZERO
			if not stunned:
				if distance < flee:
					desired_velocity = (target.position - position).normalized() * -speed 
				if distance > target_range:
					desired_velocity = (target.position - position).normalized() * speed
				elif can_use:
					can_use = false
					weapon.use(1)
					#animate.rpc(animation)
					#target.get_node('HealthBar').change_health(-damage,armor_pierce)
			velocity = (lerp(velocity, desired_velocity, MASS)+knockback*1000) * delta
			knockback = Vector2(lerp((knockback.length()),0.0,0.2),0).rotated(knockback.angle())
			move_and_slide()
		else:
			set_target()
	#else:
		#body.rotate(0.1)

#@rpc("authority","call_local")
#func animate(animation):
	#animation_player.play(animation)

#func move_to(local_position, delta):
#
	##rotation = velocity.angle()
	#return position.distance_to(local_position) < ARRIVE_DISTANCE
		##var target_dir = to_local(nav_agent.get_next_path_position()).normalized()
		##velocity = target_dir * speed * delta
		##move_and_slide()

func set_target():
	if is_server and world.players.size() > 0:
		target = null
		for player in world.players:
			if not player.dead:
				var target_distance = global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < global_position.distance_to(target.global_position):
					target = player
		#if target:
			#path_to_player = pathfinding_grid.get_point_path(global_position / TILE_SIZE, target.global_position / TILE_SIZE)
			#if path_to_player.size() > 1:
				#go_to_pos = path_to_player[1] + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)

func _on_timer_timeout() -> void:
	if is_server:
		set_target()

func activate():
	set_target()
	nav_timer.start()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	can_use = true

@rpc('authority','call_local')
func remove_armor():
	if body.get_class() == 'AnimatedSprite2D':
		body.frame = 1
