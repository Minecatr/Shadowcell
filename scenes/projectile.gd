extends RayCast2D

@export var sprite_name := 'res://assets/projectiles/bullet.svg'
@onready var sprite_node := $Sprite
@export var speed : int = 0
var bounces : int = 3
var damage : int = 3
var pierce : int = 0
var drag : float = 0.99
var hit_group : String = 'Player'
var armor_pierce : bool = false
var pierced : Array = []

func _ready() -> void:
	sprite_node.texture = load(sprite_name)
	sprite_node.position.x = target_position.x/2

func _physics_process(delta: float) -> void:
	translate(Vector2(speed*delta,0).rotated(rotation))
	if multiplayer.is_server():
		if speed < 100:
			queue_free()
		if is_colliding():
			var collider := get_collider()
			if collider.is_in_group(hit_group):
				collider.get_node('HealthBar').change_health(-damage,armor_pierce)
			if pierce > 0 and collider.is_in_group('Object'):
				if not pierced.has(collider):
					pierce -= 1
					pierced.append(collider)
			if bounces > 0 and get_collision_normal() != Vector2.ZERO:
				bounces -= 1
				#velocity = velocity.bounce(get_collision_normal())
				position = get_collision_point()
				rotation = Vector2(1,0).rotated(rotation).bounce(get_collision_normal()).angle()
				translate(Vector2(10,0).rotated(rotation))
				#translate(velocity*delta)
			elif not pierced.has(collider):
				queue_free()
	speed *= drag

	#rotate(get_angle_to(Vector2(0,0))/20)dtdtdrtf
	#velocity = Vector2(velocity.length(),0).rotated(rotation)
	#if abs(position.x) < 20 and abs(position.y) < 20:
		#queue_free()
