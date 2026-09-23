extends Path2D

@onready var root := get_tree().root
@onready var world := root.get_node('world')

@export var target = false
@export var speed = 200
@onready var is_server := multiplayer.is_server()

@onready var head = $SnakeBody

var parts = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var m = 80
	
	for child in get_children():
		if child.is_class('PathFollow2D'):
			parts.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		
	if target:
		if head.global_position.distance_to(target.position) < 10: return
		head.look_at(target.position)
		head.translate((target.position - head.global_position).normalized()*speed*delta)
		trail()
	else:
		head.rotate(0.01)
		head.translate(Vector2(speed*delta,0).rotated(head.rotation))
		trail()
func trail():
	var last_point = curve.get_point_position(0)
	if last_point.distance_to(head.position) > 1:
		curve.add_point(head.position,Vector2.ZERO,Vector2.ZERO,0)
		if curve.get_baked_length() > parts.size()*80:
			curve.remove_point(curve.point_count-1)

	#var last = get_child(get_child_count()-3)
	#last.progress = curve.get_baked_length()-80
	#if last.progress >= curve.get_baked_length()-80:
		#last.progress -= speed*delta
		#return
	#last.progress -= speed*delta
	
	#for i in parts.size():
		#if i < parts.size()-1
		#parts[i].progress = parts[i+1]


func set_target():
	if (is_server or not multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED )and world.players.size() > 0:
		target = null
		for player in world.players:
			if not player.dead:
				var target_distance = global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < global_position.distance_to(target.global_position):
					target = player


func _on_timer_timeout() -> void:
	set_target()
