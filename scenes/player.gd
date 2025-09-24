extends CharacterBody2D

var speed : int = 250
var friction : float = 0.1
var acceleration : float = 0.1
var firerate : float = 1.0
var speed_multiplier : float = 1.0

var input_dir: Vector2 = Vector2.ZERO

@onready var root := get_tree().root
@onready var world := root.get_node('world')
@onready var camera := $Camera2D
@onready var animation_player := $AnimationPlayer
@onready var weapon := $Body/Arms/RightArm/Hand.get_child(0)
@onready var equip_animation = weapon.equip_animation
@onready var timer := $UseCooldownTimer
@onready var body := $Body
@onready var healthbar := $HealthBar

var pause := false
var using := false
var can_use := true
@export var dead := false
#var mouse_position := Vector2.ZERO

@onready var is_server := multiplayer.is_server()
@onready var is_client := multiplayer.get_unique_id() == name.to_int()

# ABILITY: you can only have 1, basically a superupgrade
# GROUP: 0-Not mutually Exclusive, X-Mutually exclusive to group X
# TYPE: 0-For all weapons, 1-For ranged weapons, 2-For melee weapons
const skillmap := {
	'Armor' :      {'Ability':'Pulse Shield', 'Group':0},
	'Health' :     {'Ability':'Vampire',      'Group':0},
	'Mobility' :   {'Ability':'Dash',         'Group':0},
	'Size' :       {'Ability':'Inferno Ring', 'Group':0},
	'Damage' :     {'Ability':'Deadly',       'Group':0},
	'Swingspeed' : {'Ability':'Spinjitsu',    'Group':0},
	'Velocity' :   {'Ability':'',             'Group':0},
	'Pierce' :     {'Ability':'Ghosting',     'Group':1},
	'Shattering' : {'Ability':'Explosive',    'Group':1},
	'Ricochet' :   {'Ability':'Caltrops',     'Group':1},
	'Multishot' :  {'Ability':'Barrage',      'Group':2},
	'Seeking' :    {'Ability':'Magnet',       'Group':2},
	'Firerate' :   {'Ability':'Blitzfire',    'Group':2},
	'Stunning' :   {'Ability':'Poisoning',    'Group':3},
	'Knockback' :  {'Ability':'Taser',        'Group':3},
	'Dodge' :      {'Ability':'Last Chance',  'Group':3}
}

const skill_max_level := 3
const roman_numerals := [
	'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
	'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
	'XXI', 'XXII', 'XXIII', 'XXIV', 'XXV', 'XXVI', 'XXVII', 'XXVIII', 'XXIX', 'XXX',
	'XXXI', 'XXXII', 'XXXIII', 'XXXIV', 'XXXV', 'XXXVI', 'XXXVII', 'XXXVIII', 'XXXIX', 'XL',
	'XLI', 'XLII', 'XLIII', 'XLIV', 'XLV', 'XLVI', 'XLVII', 'XLVIII', 'XLIX', 'L'
]
const skill_options_count := 3

var possible_skills := []
var skill_options := []
var skills := {}
var skillcount := 0
var ability := ''

func _ready() -> void:
	animation_player.play(equip_animation)
	# CLIENT
	if is_client:
		z_index = 1
		camera.enabled = true
	
	# SERVER
	if is_server:
		world.level_up.connect(level_up)
		for skill in skillmap:
			skills.set(skill,0)
			if not skill in weapon.blacklisted_skills:
				possible_skills.append(skill)
		update_stats()

func _process(_delta: float) -> void:
	# SERVER
	if Input.is_action_pressed("cheat"):
		world.change_experience(1)
	if using and can_use and not dead:
		weapon.use(firerate)
		can_use = false
		timer.wait_time = 1.0/firerate
		timer.start()
		
	# CLIENT
	if is_client:
		if Input.is_action_just_pressed('pause'):
			pause = not pause
		if not pause:
			# Mouse Aim
			body.look_at(get_global_mouse_position())
			aim.rpc(body.rotation)
			
			# Movement
			var current_input_dir = Input.get_vector('left','right','up','down')
			#if input_dir != current_input_dir:
			move.rpc_id(1,current_input_dir)

func _unhandled_input(_event: InputEvent) -> void:
	if is_client and not pause:
		# Use Weapon
		if Input.is_action_just_pressed('use'):
			use.rpc_id(1,true)
		if Input.is_action_just_released('use'):
			use.rpc_id(1,false)

@rpc('any_peer','call_local')
func aim(angle):
	if multiplayer.get_remote_sender_id() == name.to_int():
		body.rotation = angle

@rpc('call_local', 'any_peer')
func move(client_input_dir):
	if multiplayer.get_remote_sender_id() == name.to_int():
		input_dir = client_input_dir

@rpc('call_local', 'any_peer')
func use(i):
	if is_server:
		using = i

func _physics_process(delta: float) -> void:
	if input_dir.length() > 0:
		velocity = velocity.lerp(input_dir.normalized() * speed * speed_multiplier, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	velocity *= delta * 60
	move_and_slide()

func _on_use_cooldown_timer_timeout() -> void:
	can_use = true

@rpc("any_peer","call_local")
func upgrade(button: int):
	if multiplayer.get_remote_sender_id() == name.to_int() and is_server:
		if world.experience_level > skillcount:
			skillcount += 1
			
			var skill = skill_options[button]
			var skill_level = skills[skill]
			if skill_level < skill_max_level:
				skills.set(skill,skill_level+1)
			else:
				ability = skillmap[skill]['Ability']
			
			# Remove Possible Skills
			var erasedskills = []
			if skillmap[skill]['Group'] != 0 or ability:
				for possible_skill in possible_skills:
					# ONLY 1 ABILITY
					if skills[possible_skill] == skill_max_level:
						if ability or skillmap[possible_skill]['Ability'] == '':
							erasedskills.append(possible_skill)
					# EXCLUSIVITY
					if skill != possible_skill and skillmap[skill]['Group'] != 0 and skillmap[skill]['Group'] == skillmap[possible_skill]['Group']:
						erasedskills.append(possible_skill)
				for erased_skill in erasedskills:
					possible_skills.erase(erased_skill)
			
			update_stats()
			if skill == 'Health':
				healthbar.change_max_health(50)
				healthbar.change_health(50,false)
			
			skill_options.clear()
			setup_skills()

func setup_skills():
	if world.experience_level > skillcount and possible_skills.size() > 0 and skill_options.is_empty():
		var possible_button_skills := possible_skills.duplicate()
		var display_text := []
		for n in skill_options_count:
			if possible_button_skills.size() > 0:
				var associated_skill : String = possible_button_skills.pick_random()
				possible_button_skills.erase(associated_skill)
				skill_options.append(associated_skill)
				var associated_skill_level = skills[associated_skill]
				if associated_skill_level < skill_max_level:
					display_text.append(associated_skill+' '+roman_numerals[associated_skill_level])
				else:
					display_text.append(skillmap[associated_skill]['Ability'])
			else:
				display_text.append('')
		world.queue_skills.rpc_id(name.to_int(),display_text)

func level_up():
	healthbar.reset_health()
	setup_skills()

func update_stats():
	firerate = (skills['Swingspeed'] + skills['Firerate'] + 1.0) * weapon.firerate_multiplier * (2 if ability == 'Blitzfire' else 1)
	speed_multiplier = (0.5*skills['Mobility']) + 1.0
