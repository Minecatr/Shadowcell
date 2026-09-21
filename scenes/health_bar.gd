extends TextureProgressBar

@export var max_health : int = 100
@export var max_armor : int = 0
@export var type : String = 'Enemy'
@export var dodge_chance := 0.0

@export var kill_coins_max : int = 1
@export var kill_coins_min : int = 1

var kill_coins := 0

@onready var health : int = max_health
@onready var armor : int = max_armor 

@onready var parent = get_parent()
@onready var world := get_tree().root.get_node('world')
@onready var entities := world.get_node('Entities')

var coin := preload('res://scenes/coin.tscn')

var dying = false

@export var dodge_sound : AudioStreamWAV = preload("res://assets/sounds/dodge.wav")
@export var armor_sound : AudioStreamWAV = preload("res://assets/sounds/armor-hit.wav")
@export var hit_sound : AudioStreamWAV = preload("res://assets/sounds/enemy-hit.wav")

var sound_node : PackedScene = preload("res://scenes/sound.tscn")

# SERVER
func _ready() -> void:
	update_healthbar_max()
	update_healthbar_value()
	kill_coins = randi_range(kill_coins_min,kill_coins_max)

func update_healthbar_max() -> void:
	max_value = max_health

func update_healthbar_value() -> void:
	value = health

func set_health(new_health):
	health = clamp(new_health,0,max_health)
	if health == max_health:
		hide()
	elif health <= 0 and not dying:
		die()
	else:
		show()
		update_healthbar_value()

func change_health(amount, pierce_armor:=0.0):
	if dodge_chance > 0 and amount < 0 and randf() < dodge_chance: 
		play_sound.rpc(dodge_sound)
		return
	if armor > 0:
		armor -= 1
		if pierce_armor > 0:
			set_health(health+amount*pierce_armor)
		play_sound.rpc(armor_sound)
		if armor <= 0:
			parent.remove_armor.rpc()
		return
	if amount < 0:
		play_sound(hit_sound)
	set_health(health+amount)

func change_max_health(amount):
	max_health += amount
	update_healthbar_max()

func reset_health():
	set_health(max_health)

func die():
	if type == 'Enemy':
		dying = true
		for c in kill_coins:
			var coin_instance = coin.instantiate()
			coin_instance.position = global_position
			entities.call_deferred('add_child',coin_instance,true)
		
		#world.change_experience(kill_experience)
		
		world.change_enemies(-1)
		parent.queue_free()
	elif type == 'Player':
		hide()
		parent.dead = true
		parent.set_collision_layer_value(1,false)
		parent.set_collision_mask_value(1,false)
		parent.modulate = Color(1,1,1,0.5)
		parent.get_node('Body/Arms').hide()
		world.check_dead()

func revive(chunk):
	show()
	set_health(max_health*chunk)
	parent.dead = false
	parent.set_collision_layer_value(1,true)
	parent.set_collision_mask_value(1,true)
	parent.modulate = Color.WHITE
	parent.get_node('Body/Arms').show()

@rpc("authority","call_local")
func play_sound(sound):
	var sound_instance : AudioStreamPlayer2D= sound_node.instantiate()
	sound_instance.stream = sound
	sound_instance.position = parent.global_position
	entities.add_child(sound_instance)
