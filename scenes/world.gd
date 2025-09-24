extends Node

signal level_up

var settings := false

@onready var main_menu = $CanvasLayer/MainMenu
@onready var hud = $CanvasLayer/HUD
@onready var address_entry = $CanvasLayer/MainMenu/VBoxContainer/Server/AddressEntry
@onready var spawn_pos = $Spawn.global_position

@onready var possible_skills_ui = $"CanvasLayer/HUD/Possible Skills"
@onready var possible_skills_text = $"CanvasLayer/HUD/Possible Skills Text"
@onready var experience_bar = $CanvasLayer/HUD/ExperienceBar
@onready var experience_level_text = $CanvasLayer/HUD/ExperienceLevel
var experience = 0
var required_experience = 3
var enemies = 0
@export var experience_level = 0
#@onready var upnp_toggle = $CanvasLayer/MainMenu/VBoxContainer/UpnpToggle
#@onready var port_entry = $CanvasLayer/MainMenu/VBoxContainer/Server/PortEntry

const PLAYER = preload("res://scenes/player.tscn")
var enet_peer = ENetMultiplayerPeer.new()
var reparent_queue : Array
var players : Array

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
	hud.show()
	
	enet_peer.create_server(2888)#port_entry.value)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	#if upnp_toggle.button_pressed:
		#upnp_setup()
	update_experiencebar_max()
	update_experiencebar_value()

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(address_entry.text, 2888)#port_entry.value)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player := PLAYER.instantiate()
	player.name = str(peer_id)
	player.position = Vector2(randf(),randf()) + spawn_pos
	add_child(player)
	players.append(player)
	player.setup_skills()

func remove_player(peer_id):
	var player := get_node_or_null(str(peer_id))
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


## EXPERIENCE

func update_experiencebar_max() -> void:
	experience_bar.max_value = required_experience

func update_experiencebar_value() -> void:
	experience_bar.value = experience

func set_experience(new_experience):
	experience = clamp(new_experience,0,required_experience)
	var dif = new_experience-experience
	if experience == required_experience:
		experience_level += 1
		experience_level_text.text = str(experience_level)
		experience = 0
		required_experience += 1
		emit_signal('level_up')
		update_experiencebar_max()
	update_experiencebar_value()
	if dif != 0:
		change_experience(dif)

func change_experience(amount):
	set_experience(experience+amount)

@rpc("authority","call_local")
func queue_skills(display_text):
	for button in possible_skills_ui.get_children():
		button.text = display_text[button.get_index()]
		if button.text == '':
			button.hide()
		else:
			button.show()
	possible_skills_ui.show()
	possible_skills_text.show()

func press(button):
	possible_skills_ui.hide()
	possible_skills_text.hide()
	get_node(str(multiplayer.get_unique_id())).upgrade.rpc_id(1,button)

func _on_skill_1_pressed() -> void:
	press(0)

func _on_skill_2_pressed() -> void:
	press(1)

func _on_skill_3_pressed() -> void:
	press(2)
