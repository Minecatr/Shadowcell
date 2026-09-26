extends CharacterBody2D

var speed : int = 250
var friction : float = 0.1
var acceleration : float = 0.1
var firerate : float = 1.0
var speed_multiplier : float = 1.0
var money : int = 0

var level_position : Vector2
var input_dir: Vector2 = Vector2.ZERO
var dash_velocity:Vector2

var target : Vector2
var can_dash:bool = true

@export var selected_character : String
@export var selected_weapon : String

#@onready var camera := $Camera2D
@onready var weapon : Node
@onready var hand := $Body/Arms/RightArm/Hand
@onready var body := $Body
@onready var left_arm_sprite := body.get_node("Arms/LeftArm/Arm")
@onready var right_arm_sprite := body.get_node("Arms/RightArm/Arm")
@onready var healthbar := $HealthBar
@onready var target_indicator := $TargetIndicator
@onready var dash_timer: = $DashTimer

var using := false
var stunned := false
@export var can_use := true
@export var dead := false
#var mouse_position := Vector2.ZERO

@onready var is_client := multiplayer.get_unique_id() == name.to_int()

# ABILITY: you can only have 1, basically a superupgrade
# GROUP: 0-Not mutually Exclusive, X-Mutually exclusive to group X
# TYPE: 0-For all weapons, 1-For ranged weapons, 2-For melee weapons
const skillmap := {
	'Health' :     0,
	'Dodge' :      3,
	'Mobility' :   0,
	'Size' :       0,
	'Damage' :     0,
	'Swingspeed' : 0,
	'Pierce' :     1,
	'Critical Damage': 0,
	'Critical Chance': 0,
	'Greed': 0,
	#'Shattering' : {'Ability':'Explosive', 'Group':1},
	'Ricochet' :   1,
	'Multishot' :  0,
	'Firerate' :   0,
	'Stunning' :   3,
	'Knockback' :  3,
	'Velocity' :   0,
	#'Seeking' :    {'Ability':'',          'Group':0}
}

const special_abilities := [
	'Evitationis', #Dash X
	'Vampyris', # Siphon
	'Scuti', # Pulse Shield
	'Infernalis', # Inferno Ring
	'Ignis', # Fire
	'Fulguris', # Chain Lightning X
	'Spiritus', # Ghosting
	'Stercoris', # Caltrops
	'Glacieis', # Freezing
	'Radii', # Laser
	'Explosionum', # Explosive X
	'Venator', # Seeking
	'Myriada', # Barrage X
	'Vitalis', # 2nd chance
	'Potentiae', # damage X
	'Rapidus' #Blitzfire Spinjitsu X
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

var possible_skills:Array
var skill_options:Array
var ability_option:String
var skills := {}

const has_skills := true
var skill_selections := 0
var ability:Array[String]
var maximum_abilities:int = 1
var mouse_aim := true
@onready var aim_indicator = $AimIndicator

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
		#camera.enabled = true
	
	# SERVER
	if GLOBALS.is_server:
		GLOBALS.world.level_up.connect(level_complete)
		GLOBALS.world.next_level.connect(next_level)
		for skill in skillmap:
			skills.set(skill,0)
			if not skill in weapon.blacklisted_skills:
				possible_skills.append(skill)
		update_stats()

# ALL INPUTS ARE IN THIS, UNHANDLED INPUT (besides force quit in world)
func _process(_delta: float) -> void:
	# SERVER
	if Input.is_action_just_pressed("cheat"):
		level_complete(skill_selections+10)
		
	if using and can_use and not dead and not stunned:
		weapon.use(firerate)
		can_use = false
		
	# CLIENT
	if is_client:
		if Input.is_action_just_pressed('pause'):
			GLOBALS.world.toggle_pause()
		if GLOBALS.world.pause: 
			move.rpc_id(1,Vector2.ZERO)
			return
		if Input.is_action_just_pressed('option1'): GLOBALS.world.press(0)
		if Input.is_action_just_pressed('option2'): GLOBALS.world.press(1)
		if Input.is_action_just_pressed('option3'): GLOBALS.world.press(2)
		if target and position.distance_to(target) > 50:
			target_indicator.visible = true
			target_indicator.offset.x = clamp(position.distance_to(target)/2,100,500)
			target_indicator.rotation = global_position.angle_to_point(target)
		else:
			target_indicator.visible = false
			target = Vector2.ZERO
		# Mouse Aim
		var aim_vector = Input.get_vector('look_left','look_right','look_up','look_down')
		if aim_vector:
			body.rotation =aim_vector.angle()
			aim_indicator.position = 512*aim_vector
			aim_indicator.show()
			mouse_aim = false
		elif mouse_aim:
			body.look_at(get_global_mouse_position())
		else:
			aim_indicator.hide()
		aim.rpc(body.rotation)
		# Movement
		var current_input_dir = Input.get_vector('left','right','up','down')
		#if input_dir != current_input_dir:
		move.rpc_id(1,current_input_dir)

func _unhandled_input(event: InputEvent) -> void:
	if is_client and not GLOBALS.world.pause:
		# Use Weapon
		if event is InputEventMouseMotion:
			mouse_aim = true
			aim_indicator.hide()
		if Input.is_action_just_pressed('use'):
			use.rpc_id(1,true)
		if Input.is_action_just_released('use'):
			use.rpc_id(1,false)
		if Input.is_action_just_released('ability'):
			use_ability.rpc_id(1)

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
	if GLOBALS.is_server:
		using = i

@rpc('call_local', 'any_peer')
func use_ability():
	if GLOBALS.is_server:
		if ability.has('Evitationis') and can_dash:
			can_dash = false
			dash_timer.start()
			dash_velocity = input_dir.normalized()*1000

@rpc('call_local', 'authority')
func set_target(target_position):
	target = target_position
	target_indicator.visible = true

func _physics_process(delta: float) -> void:
	if input_dir.length() > 0 and not stunned:
		velocity = velocity.lerp(input_dir.normalized() * speed * speed_multiplier, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	if level_position:
		if (level_position-position).length() > 32:
			#$AnimationPlayer.stop()
			#can_use=false
			velocity = (level_position-position)*4
		else:
			level_position = Vector2.ZERO
			GLOBALS.world.activate_level()
	velocity += dash_velocity
	dash_velocity = lerp(dash_velocity,Vector2.ZERO,0.9)
	velocity *= delta * 60
	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if attack_animations.has(anim_name):
		can_use = true

@rpc("any_peer","call_local")
func upgrade(button: int):
	if multiplayer.get_remote_sender_id() == name.to_int() and GLOBALS.is_server:
		if skill_selections > 0:
			skill_selections -= 1
			
			if button == 2:
				healthbar.change_health(randi_range(5,healthbar.max_health-healthbar.health))
				ability_option = ''
				skill_options.clear()
				setup_skills()
				return
			elif ability_option and button == 1:
				ability.append(ability_option)
				ability_option = ''
				skill_options.clear()
				update_stats()
				setup_skills()
				return
			ability_option = ''
			var skill = skill_options[button]
			var new_skill_level = skills[skill]+1
			skills.set(skill,new_skill_level)
			if new_skill_level >= skill_max_level:
				possible_skills.erase(skill)
			
			# Remove Possible Skills
			#var erasedskills = []
			if skillmap[skill] != 0 or ability:
				for possible_skill in possible_skills:
					# EXCLUSIVITY
					if skill != possible_skill and skillmap[skill] != 0 and skillmap[skill] == skillmap[possible_skill]:
						possible_skills.erase(possible_skill)
				#for erased_skill in erasedskills:
					#possible_skills.erase(erased_skill)
			
			update_stats()
			if skill == 'Health':
				healthbar.change_max_health(50)
				healthbar.change_health(50)
			if skill == 'Dodge':
				healthbar.dodge_chance += 0.08
			
			skill_options.clear()
			setup_skills()

func setup_skills(random_ability:=''):
	if skill_selections > 0 and possible_skills.size() > 0 and skill_options.is_empty():
		var possible_button_skills := possible_skills.duplicate()
		var display_text := []
		for n in skill_options_count - (0 if random_ability == '' else 1):
			if possible_button_skills.size() > 0:
				var associated_skill : String = possible_button_skills.pick_random()
				possible_button_skills.erase(associated_skill)
				skill_options.append(associated_skill)
				var associated_skill_level = skills[associated_skill]
				display_text.append(associated_skill+' '+roman_numerals[associated_skill_level])
			else:
				display_text.append('')
		
		if random_ability != '':
			ability_option = random_ability
			display_text.append(random_ability)
		GLOBALS.world.queue_skills.rpc_id(name.to_int(),display_text,skill_selections,ability_option)

func level_complete(upgrades,abilities:=[]):
	if dead:
		if GLOBALS.is_server:
			healthbar.revive(0.5)
		return
	# healthbar.set_health(healthbar.health*1.5)
	skill_selections = upgrades
	setup_skills(abilities.pick_random() if abilities.size() > 0 and ability.size() < maximum_abilities else '')
	if GLOBALS.is_server:
		GLOBALS.world.update_skills_ui.rpc_id(name.to_int(),skill_selections)

func update_stats():
	firerate = ((skills['Swingspeed'] + skills['Firerate'])*firerate_effectiveness + 1.0) * weapon.firerate_multiplier * (2 if ability.has('Rapidus') else 1)
	speed_multiplier = (0.25*skills['Mobility']) + 1.0

func _on_pickup_range_area_entered(area: Area2D) -> void:
	if GLOBALS.is_server and not dead and area.is_in_group('Coin'):
		money += area.value
		area.queue_free()
		GLOBALS.world.rpc_id(name.to_int(), 'update_money_count', money)

func next_level():
	#var players : Array = GLOBALS.world.players
	#var spacing = 60
	#@warning_ignore("integer_division")
	# var final_offset = (players.size()-1)*(spacing/2) - spacing*players.find(self)
	# level_position = GLOBALS.world.level_position + Vector2(0,final_offset)
	level_position = position + Vector2(256,0).rotated(GLOBALS.world.level.rotation)
	# skill_selections = 0


func _on_dash_timer_timeout() -> void:
	can_dash = true
