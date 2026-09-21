extends RayCast2D

@export var sprite_name := 'bullet'
@onready var sprite_node := $Sprite
@onready var trail := $Trail2D
@export var speed : int = 0
var bounces : int = 3
var damage : int = 3
var pierce : int = 0
var drag : float = 0.99
var hit_group : String = 'Player'
var armor_pierce : float = 0.0
var pierced : Array = []
var knockback : int = 0
var stun := 0.0
@export var rotation_speed : float = 0

@export var sound : AudioStreamWAV = preload("res://assets/sounds/bounce.wav")
var sound_node : PackedScene = preload("res://scenes/sound.tscn")

func _ready() -> void:
	sprite_node.texture = load("res://assets/sprites/weapons/"+sprite_name+".svg")
	#trail.width = scale.x * 10
	target_position.x = sprite_node.texture.get_width()/2
	sprite_node.position.x = target_position.x/2
	armor_pierce = clamp(pierce/10.0,0.0,1.0)
	#trail.position.x = target_position.x/2

func _physics_process(delta: float) -> void:
	translate(Vector2(speed*delta,0).rotated(rotation))
	sprite_node.rotate((rotation_speed*speed*delta*0.1))
	if multiplayer.is_server():
		if speed < 100:
			queue_free()
		if is_colliding():
			var collider := get_collider()
			if not pierced.has(collider):
				if collider.is_in_group(hit_group):
					collider.get_node('HealthBar').change_health(-damage,armor_pierce)
					if stun > 0:
						collider.get_node('Stun').stun(stun,armor_pierce)
					if knockback:
						collider.knockback += Vector2(-knockback,0).rotated(get_collision_normal().angle())
				if pierce > 0 and collider.is_in_group('Object'):
					pierce -= 1
					pierced.append(collider)
			if bounces > 0 and (pierce <= 0 or collider.is_in_group('Map')) and get_collision_normal() != Vector2.ZERO:
				play_sound.rpc()
				bounces -= 1
				#velocity = velocity.bounce(get_collision_normal())
				position = get_collision_point()
				rotation = Vector2(1,0).rotated(rotation).bounce(get_collision_normal()).angle()
				translate(Vector2(10,0).rotated(rotation))
				#translate(velocity*delta)
			elif not pierced.has(collider):
				queue_free()
	speed = round(speed*drag)
	if speed > 1000:
		scale.x = scale.y*speed/1000

@rpc("authority","call_local")
func play_sound():
	var sound_instance : AudioStreamPlayer2D= sound_node.instantiate()
	sound_instance.stream = sound
	sound_instance.volume_db = -15
	sound_instance.position = global_position
	get_parent().add_child(sound_instance)
	#rotate(get_angle_to(Vector2(0,0))/20)dtdtdrtf
	#velocity = Vector2(velocity.length(),0).rotated(rotation)
	#if abs(position.x) < 20 and abs(position.y) < 20:
		#queue_free()
