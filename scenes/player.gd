extends CharacterBody2D

var speed : int = 250
var friction : float = 0.1
var acceleration : float = 0.1
var firerate : float = 1.0
var speed_multiplier : float = 1.0
var money : int = 0

var level_position : Vector2
var input_dir: Vector2 = Vector2.ZERO

var target : Vector2

@export var selected_character : String
@export var selected_weapon : String

@onready var root := get_tree().root
@onready var world := root.get_node('world')
@onready var camera := $Camera2D
@onready var weapon : Node
@onready var hand := $Body/Arms/RightArm/Hand
@onready var body := $Body
@onready var left_arm_sprite := body.get_node("Arms/LeftArm/Arm")
@onready var right_arm_sprite := body.get_node("Arms/RightArm/Arm")
@onready var healthbar := $HealthBar
@onready var target_indicator := $TargetIndicator

var pause := false
var using := false
var stunned := false
@export var can_use := true
@export var dead := false
#var mouse_position := Vector2.ZERO

@onready var is_server := multiplayer.is_server()
@onready var is_client := multiplayer.get_unique_id() == name.to_int()

# ABILITY: you can only have 1, basically a superupgrade
# GROUP: 0-Not mutually Exclusive, X-Mutually exclusive to group X
# TYPE: 0-For all weapons, 1-For ranged weapons, 2-For melee weapons
const skillmap := {
	'Health' :     {'Ability':'2nd Chance','Group':0},
	'Dodge' :      {'Ability':'',          'Group':3},
	'Mobility' :   {'Ability':'',          'Group':0},
	'Size' :       {'Ability':'',          'Group':0},
	'Damage' :     {'Ability':'Deadly',    'Group':0},
	'Swingspeed' : {'Ability':'Spinjitsu', 'Group':0},
	'Pierce' :     {'Ability':'',          'Group':1},
	#'Shattering' : {'Ability':'Explosive', 'Group':1},
	'Ricochet' :   {'Ability':'',          'Group':1},
	'Multishot' :  {'Ability':'Barrage',   'Group':0},
	'Firerate' :   {'Ability':'Blitzfire', 'Group':0},
	'Stunning' :   {'Ability':'',          'Group':3},
	'Knockback' :  {'Ability':'',          'Group':3},
	'Velocity' :   {'Ability':'',          'Group':0},
	'Seeking' :    {'Ability':'',          'Group':0}
}

const special_abilities := [
	'Dash',
	'Vampire',
	'Pulse Shield',
	'Inferno Ring',
	'Ghosting',
	'Chain Lightning',
	'Caltrops',
	'Criticals',
	'Freezing',
	'Laser Beam',
	'Explosive'
]

const firerate_effectiveness := 0.5
const skill_max_level := 10
const roman_numerals := [
	'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
	'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
	'XXI', 'XXII', 'XXIII', 'XXIV', 'XXV', 'XXVI', 'XXVII', 'XXVIII', 'XXIX', 'XXX',
	'XXXI', 'XXXII', 'XXXIII', 'XXXIV', 'XXXV', 'XXXVI', 'XXXVII', 'XXXVIII', 'XXXIX', 'XL',
	'XLI', 'XLII', 'XLIII', 'XLIV', 'XLV', 'XLVI', 'XLVII', 'XLVIII', 'XLIX', 'L'
]
const skill_options_count := 2

var possible_skills := []
var skill_options := []
var skills := {}
const has_skills := true
var skill_selections := 0
var ability := ''

const attack_animations := [
	'character_animations/spin',
	'character_animations/stab',
	'character_animations/sweep',
	'character_animations/spin',
	'character_animations/throw',
	'character_animations/use-bow'
]

func _ready() -> void:
	# BOTH
	var weapon_instance = load("res://scenes/weapons/"+selected_weapon+".tscn").instantiate()
	hand.add_child(weapon_instance)
	weapon = weapon_instance
	body.texture = load("res://assets/sprites/characters/"+selected_character+"-body.svg")
	right_arm_sprite.texture = load("res://assets/sprites/characters/"+selected_character+"-arm.svg")
	left_arm_sprite.texture = load("res://assets/sprites/characters/"+selected_character+"-arm.svg")
	
	# CLIENT
	if is_client:
		z_index = 1
		camera.enabled = true
	
	# SERVER
	if is_server:
		world.level_up.connect(level_complete)
		world.next_level.connect(next_level)
		for skill in skillmap:
			skills.set(skill,0)
			if not skill in weapon.blacklisted_skills:
				possible_skills.append(skill)
		update_stats()

func _process(_delta: float) -> void:
	# SERVER
	if Input.is_action_just_pressed("cheat"):
		level_complete(skill_selections+1)
		
	if using and can_use and not dead and not stunned:
		weapon.use(firerate)
		can_use = false
		
	# CLIENT
	if is_client:
		if target and position.distance_to(target) > 50:
			target_indicator.visible = true
			target_indicator.offset.x = clamp(position.distance_to(target)/2,100,500)
			target_indicator.rotation = global_position.angle_to_point(target)
		else:
			target_indicator.visible = false
			target = Vector2.ZERO
		if Input.is_action_just_pressed('pause'):
			world.toggle_pause()
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

@rpc('call_local', 'authority')
func set_target(target_position):
	target = target_position
	target_indicator.visible = true
	print(name)
	print(target)

func _physics_process(delta: float) -> void:
	if input_dir.length() > 0 and not stunned:
		velocity = velocity.lerp(input_dir.normalized() * speed * speed_multiplier, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	if level_position:
		if (level_position-position).length() > 32:
			can_use = false
			velocity = (level_position-position)*4
		else:
			level_position = Vector2.ZERO
			world.activate_level()
	velocity *= delta * 60
	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if attack_animations.has(anim_name):
		can_use = true

@rpc("any_peer","call_local")
func upgrade(button: int):
	if multiplayer.get_remote_sender_id() == name.to_int() and is_server:
		if skill_selections > 0:
			skill_selections -= 1
			
			if button == 2:
				healthbar.change_health(randi_range(5,healthbar.max_health-healthbar.health))
				skill_options.clear()
				setup_skills()
				return
			
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
			if skill == 'Dodge':
				healthbar.dodge_chance += 0.05
			
			skill_options.clear()
			setup_skills()

func setup_skills():
	if skill_selections > 0 and possible_skills.size() > 0 and skill_options.is_empty():
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
		world.queue_skills.rpc_id(name.to_int(),display_text,skill_selections)

func level_complete(upgrades):
	if dead:
		if is_server:
			healthbar.revive(0.5)
		return
	# healthbar.set_health(healthbar.health*1.5)
	skill_selections = upgrades
	setup_skills()
	if is_server:
		world.update_skills_ui.rpc_id(name.to_int(),skill_selections)

func update_stats():
	firerate = ((skills['Swingspeed'] + skills['Firerate'])*firerate_effectiveness + 1.0) * weapon.firerate_multiplier * (2 if ability == 'Blitzfire' else 1) * (2 if ability == 'Spinjitsu' else 1)
	speed_multiplier = (0.25*skills['Mobility']) + 1.0

func _on_pickup_range_area_entered(area: Area2D) -> void:
	if is_server and not dead and area.is_in_group('Coin'):
		money += area.value
		area.queue_free()
		world.rpc_id(name.to_int(), 'update_money_count', money)

func next_level():
	var players : Array = world.players
	var spacing = 60
	@warning_ignore("integer_division")
	var final_offset = (players.size()-1)*(spacing/2) - spacing*players.find(self)
	level_position = world.level_position + Vector2(0,final_offset)
	# skill_selections = 0
