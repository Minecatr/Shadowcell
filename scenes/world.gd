extends Node

signal level_up
signal next_level
signal level_activated

var settings := false
var pause := false

@onready var main_menu = $CanvasLayer/MainMenu
@onready var hud = $CanvasLayer/HUD
@onready var game_over_screen = $CanvasLayer/HUD/GameOverScreen
@onready var character_select = $CanvasLayer/CharacterSelect
@onready var address_entry = $CanvasLayer/MainMenu/VBoxContainer/Server/AddressEntry

@onready var possible_skills_ui = $"CanvasLayer/HUD/Possible Skills"
@onready var possible_skills_text = possible_skills_ui.get_node('Possible Skills Text')
@onready var possible_skills_buttons = possible_skills_ui.get_node('Possible Skills Buttons')
#@onready var experience_bar = $CanvasLayer/HUD/ExperienceBar
#@onready var experience_level_text = $CanvasLayer/HUD/ExperienceLevel
@onready var money_text = $CanvasLayer/HUD/Money

@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var resume_button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/Resume
@onready var entities = $Entities

#var experience = 0
#var required_experience = 3

var level
var level_position := Vector2.ZERO
@export var camera_anchor := Vector2.ZERO
var enemies = 0
#@onready var upnp_toggle = $CanvasLayer/MainMenu/VBoxContainer/UpnpToggle
#@onready var port_entry = $CanvasLayer/MainMenu/VBoxContainer/Server/PortEntry

const PLAYER = preload("res://scenes/player.tscn")
var enet_peer = ENetMultiplayerPeer.new()
var reparent_queue : Array
var players : Array
var unready_players : Array
@onready var camera := $Camera2D

func _ready() -> void:
	main_menu.visible = true

func _process(delta: float) -> void:
	camera.position = lerp(camera.position, camera_anchor, 4*delta)

func _unhandled_input(_event):
	#if Input.is_action_just_pressed("pause") and settings:
		#settings = false
		#$CanvasLayer/Settings.hide()
		#$CanvasLayer/MainMenu.show()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	#if Input.is_action_just_pressed("fullscreen"):
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_host_button_pressed():
	main_menu.hide()
	character_select.show()
	
	enet_peer.create_server(2888)#port_entry.value)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	#if upnp_toggle.button_pressed:
		#upnp_setup()
	#update_experiencebar_max()
	#update_experiencebar_value()

func _on_join_button_pressed():
	main_menu.hide()
	character_select.show()
	
	enet_peer.create_client(address_entry.text, 2888)#port_entry.value)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_disconnected.connect(try_disconnect)

@rpc("any_peer","call_local")
func player_ready(character: String, weapon: String):
	var peer_id = multiplayer.get_remote_sender_id()
	if not unready_players.has(peer_id): return
	var player := PLAYER.instantiate()
	player.name = str(peer_id)
	player.selected_weapon = weapon
	player.selected_character = character
	player.position = Vector2(randf(),randf()) + level_position
	entities.add_child(player)
	unready_players.erase(peer_id)
	players.append(player)
	if level and enemies <= 0:
		player.skill_selections = level.win_upgrades
	player.setup_skills()

func add_player(peer_id):
	unready_players.append(peer_id)

func remove_player(peer_id):
	var player := entities.get_node_or_null(str(peer_id))
	if player:
		players.erase(player)
		player.queue_free()

#func upnp_setup():
	#var upnp = UPNP.new()
	#
	#var discover_result = upnp.discover()
	#assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)
#
	#assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
#
	#var map_result = upnp.add_port_mapping(port_entry.value)
	#assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	#
	#print("Success! Join Address: %s" % upnp.query_external_address())
	#
		

#func _on_settings_button_pressed() -> void:
	#settings = true
	#$CanvasLayer/MainMenu.hide()
	#$CanvasLayer/Settings.show()

## MONEY

@rpc('authority','call_local')
func update_money_count(new_money):
	money_text.text = '$'+str(new_money)


## EXPERIENCE

#func update_experiencebar_max() -> void:
	#experience_bar.max_value = required_experience
#
#func update_experiencebar_value() -> void:
	#experience_bar.value = experience

#func set_experience(new_experience):
	#experience = clamp(new_experience,0,required_experience)
	#var dif = new_experience-experience
	#if experience == required_experience:
		#experience_level += 1
		##experience_level_text.text = str(experience_level)
		#experience = 0
		#required_experience += 1
		#emit_signal('level_up')
		##update_experiencebar_max()
	##update_experiencebar_value()
	#if dif != 0:
		#change_experience(dif)

#func change_experience(amount):
	#set_experience(experience+amount)

func start_level(door):
	level = door
	var anchor = level.get_node('CameraAnchor')
	if anchor: camera_anchor=anchor.global_position
	level_position=level.position+Vector2(128,0).rotated(level.rotation)
	emit_signal('next_level')

func activate_level():
	level.close()
	#for player in players:
		#player.can_use = true
	#	var animation_player : AnimationPlayer = player.get_node('AnimationPlayer')
	#	if animation_player.is_animation_active() and not animation_player.is_playing(): animation_player.play()
	emit_signal('level_activated')

func change_enemies(amount):
	enemies += amount
	if enemies <= 0:
		emit_signal('level_up',level.win_upgrades)

@rpc("authority","call_local")
func update_skills_ui(skill_selections):
	possible_skills_text.text = 'Choose a skill'
	if skill_selections > 1:
		possible_skills_text.text += ' ('+str(skill_selections-1)+')'

@rpc("authority","call_local")
func queue_skills(display_text,skill_selections):
	possible_skills_buttons.get_child(0).text = display_text[0]
	possible_skills_buttons.get_child(1).text = '???'
	if not display_text[0]: possible_skills_buttons.get_child(0).hide()
	if not display_text[1]: possible_skills_buttons.get_child(1).hide()

	#for button in possible_skills_buttons.get_children():
		#button.text = display_text[button.get_index()]
		#if button.text == '':
			#button.hide()
		#else:
			#button.show()
	update_skills_ui(skill_selections)
	possible_skills_ui.show()
	

func press(button):
	possible_skills_ui.hide()
	entities.get_node(str(multiplayer.get_unique_id())).upgrade.rpc_id(1,button)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_resume_pressed() -> void:
	toggle_pause()

func toggle_pause():
	pause = not pause
	pause_menu.visible = pause
	entities.get_node_or_null(str(multiplayer.get_unique_id())).pause = pause

func try_disconnect(peer_id) -> void:
	if peer_id == 1:
		enet_peer.close()
		get_tree().reload_current_scene()

func _on_disconnect_pressed() -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		enet_peer.close()
	get_tree().reload_current_scene()
	#get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
	level_position = Vector2.ZERO
	camera_anchor = Vector2.ZERO
	for entity in entities.get_children():
		entity.queue_free()
	players.clear()
	level = null
	for node in $Level.get_children():
		if node.is_class('StaticBody2D'):
			node.open = false
			node.players_entered = []
	enemies = 0
	add_player(multiplayer.get_unique_id())
	for peer in multiplayer.get_peers():
		add_player(peer)
	restart_effects.rpc()
@rpc("authority","call_local")
func restart_effects():
	main_menu.hide()
	hud.hide()
	game_over_screen.hide()
	character_select.show()
		#player.position = level_position
		#player.healthbar.revive(1.0)
		#player.skill_selections = 0
		#player.ability = ''
		#player.skills = {}
		#for skill in player.skillmap:
			#player.skills.set(skill,0)
			#if not skill in player.weapon.blacklisted_skills:
				#player.possible_skills.append(skill)
		#var player_name = player.name
		#player.queue_free()
		#add_player(player_name)
	#main_menu.hide()
	#character_select.show()
	#if multiplayer.get_peers():
		#for peer in multiplayer.get_peers():
			#add_player(peer)
	#else:
		#add_player(multiplayer.get_unique_id())

func check_dead():
	var game_over = true
	for player in players:
		if not player.dead: game_over = false
	if game_over:
		game_over_screen.show()


#func _on_bullet_factory_2d_body_entered(hit_target_body: Object, multimesh_bullets_instance: MultiMeshBullets2D, _bullet_index: int, bullets_custom_data: Resource, bullet_global_transform: Transform2D) -> void:
	#if multiplayer.is_server():
		#var damage_data:DamageData = bullets_custom_data as DamageData
		#if damage_data != null:
			#if hit_target_body.is_in_group(damage_data.hit_group):
				#hit_target_body.get_node('HealthBar').change_health(-damage_data.damage,false)
				#if damage_data.knockback > 0:
					#hit_target_body.knockback += Vector2(-damage_data.knockback,0).rotated((bullet_global_transform.get_origin()-hit_target_body.global_position).normalized().angle())
			#elif hit_target_body.is_in_group('Map') and damage_data.bounces == 0:
				#multimesh_bullets_instance.queue_free()
				#
