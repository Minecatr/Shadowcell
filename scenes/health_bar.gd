extends TextureProgressBar

@export var max_health : int = 100
@export var max_armor : int = 0
@export var type : String = 'Enemy'

@export var kill_experience : int = 1

@onready var health : int = max_health
@onready var armor : int = max_armor 

@onready var parent = get_parent()
@onready var world := get_tree().root.get_node('world')

# SERVER
func _ready() -> void:
	update_healthbar_max()
	update_healthbar_value()

func update_healthbar_max() -> void:
	max_value = max_health

func update_healthbar_value() -> void:
	value = health

func set_health(new_health):
	health = clamp(new_health,0,max_health)
	if health == max_health:
		hide()
	elif health <= 0:
		die()
	else:
		show()
		update_healthbar_value()

func change_health(amount, _pierce_armor):
	set_health(health+amount)

func change_max_health(amount):
	max_health += amount
	update_healthbar_max()

func reset_health():
	set_health(max_health)

func die():
	if type == 'Enemy':
		world.change_experience(kill_experience)
		world.enemies -= 1
		parent.queue_free()
	elif type == 'Player':
		hide()
		parent.dead = true
		parent.set_collision_layer_value(1,false)
		parent.set_collision_mask_value(1,false)
		parent.modulate = Color(1,1,1,0.5)
		parent.get_node('Body/Arms').hide()

func revive():
	show()
	reset_health()
	parent.dead = false
	parent.set_collision_layer_value(1,true)
	parent.set_collision_mask_value(1,true)
	parent.modulate = Color.WHITE
	parent.get_node('Body/Arms').show()
