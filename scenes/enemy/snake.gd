extends Path2D

@export var speed = 5000
@onready var head = $Head
@onready var tongue = head.get_node('SnakeTongue')
@onready var targeter = $Targeter
@onready var attack_timer = $AttackTimer

var segments:Array[PathFollow2D]
var can_attack: = true

const tail_texture = preload("res://assets/sprites/characters/snake-tail.svg")
const segment_node = preload("res://scenes/enemy/snake_segment.tscn")
const segment_count = 19
const segment_spacing = 80
const damage = 100

@onready var alive_segments = segment_count
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		GLOBALS.world.change_enemies(1)
		for n in segment_count:
			var segment_instance:PathFollow2D = segment_node.instantiate()
			segment_instance.progress = segment_spacing * (segment_count-n)
			if n == 0:
				segment_instance.get_node('Sprite').frame = 1
				segment_instance.get_node('Hit/HealthBar').dodge_chance = 0.0
			add_child(segment_instance,true)
			segments.append(segment_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if targeter.target:
		if head.global_position.distance_to(targeter.target.position) < 64:
			head.velocity = Vector2.ZERO
			if can_attack:
				tongue.show()
				targeter.target.get_node('HealthBar').change_health(-damage)
				can_attack = false
				attack_timer.start()
		else:
			head.rotation = lerp_angle(head.rotation, (targeter.target.position-head.global_position).angle(),0.05)
			head.velocity = Vector2(speed*delta,0).rotated(head.rotation)
	else:
		head.rotate(0.01)
		head.velocity = Vector2(speed*delta,0).rotated(head.rotation)
	head.move_and_slide()
	var last_point = curve.get_point_position(0)
	if last_point.distance_to(head.position) > 1:
		curve.add_point(head.position,Vector2.ZERO,Vector2.ZERO,0)
		if curve.get_baked_length() > segment_count*segment_spacing:
			curve.remove_point(curve.point_count-1)


func _on_attack_timer_timeout() -> void:
	can_attack = true
	tongue.hide()
