extends CharacterBody2D

const TILE_SIZE = 64
const ARRIVE_DISTANCE = 10.0
const MASS = 1.0

@export var speed := 10000
@export var damage := 10
@export var armor_pierce := false
@export var target_range := 64
@onready var is_server := multiplayer.is_server()
@onready var root := get_tree().root
@onready var world := root.get_node('world')
@onready var tilemap : TileMapDual = world.get_node('Map')
@export var target = false

@onready var cooldown_timer := $AttackCooldown
@onready var body := $Body
@onready var animation_player := $AnimationPlayer

var pathfinding_grid := AStarGrid2D.new()
var path_to_player := []
var go_to_pos = false
var can_attack := true

func _ready() -> void:
	if is_server:
		world.enemies += 1
		
		pathfinding_grid.region = tilemap.get_used_rect()
		pathfinding_grid.cell_size = Vector2(TILE_SIZE,TILE_SIZE)
		pathfinding_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		pathfinding_grid.update()
		
		for cell in tilemap.get_used_cells():
			pathfinding_grid.set_point_solid(cell, true)
		
		set_target()
		#move_ai()

func _physics_process(delta: float) -> void:
	if is_server and target:
		if not target.dead:
			body.look_at(target.global_position)
			if position.distance_to(target.global_position) > target_range:
				if path_to_player.size() > 1:
					var arrived_to_next_point = move_to(go_to_pos, delta)
					if arrived_to_next_point:
						path_to_player.remove_at(0)
						go_to_pos = path_to_player[0] + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
				else:
					set_target()
			elif can_attack:
				can_attack = false
				cooldown_timer.start()
				animate.rpc('swing')
				target.get_node('HealthBar').change_health(-damage,armor_pierce)
		else:
			set_target()

@rpc("authority","call_local")
func animate(animation):
	animation_player.play(animation)

func move_to(local_position, delta):
	var desired_velocity = (local_position - position).normalized() * speed * delta
	var steering = (desired_velocity - velocity)
	velocity += steering / MASS
	move_and_slide()
	#rotation = velocity.angle()
	return position.distance_to(local_position) < ARRIVE_DISTANCE
		#var target_dir = to_local(nav_agent.get_next_path_position()).normalized()
		#velocity = target_dir * speed * delta
		#move_and_slide()

func set_target():
	if is_server and world.players.size() > 0:
		for player in world.players:
			if not player.dead:
				var target_distance = global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < global_position.distance_to(target.global_position):
					target = player
		if target:
			path_to_player = pathfinding_grid.get_point_path(global_position / TILE_SIZE, target.global_position / TILE_SIZE)
			if path_to_player.size() > 1:
				go_to_pos = path_to_player[1] + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)

func _on_timer_timeout() -> void:
	if is_server:
		set_target()


func _on_attack_cooldown_timeout() -> void:
	can_attack = true
