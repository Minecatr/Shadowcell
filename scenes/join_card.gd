extends PanelContainer

var characters := [
	'default',
	'opalmoon',
	'shadow',
	'agent',
	'bloodvisor',
	'inverted',
	'robot',
	'stealth'
]
var weapons := [
	'shuriken',
	'katana',
	'pistol',
	'sai',
	'crystal-scepter',
	'bow',
	'rifle'
]

var character := 0
var weapon := 0

@onready var character_preview = $MarginContainer/VBoxContainer/Character/TextureRect
@onready var weapon_preview = $MarginContainer/VBoxContainer/Weapon/TextureRect
@onready var ready_button = $MarginContainer/VBoxContainer/Ready

@onready var root := get_tree().root
@onready var world := root.get_node('world')

func _on_character_left_pressed() -> void:
	character = wrapi(character-1,0,characters.size())
	set_character(characters[character])

func _on_character_right_pressed() -> void:
	character = wrapi(character+1,0,characters.size())
	set_character(characters[character])

func _on_weapon_left_pressed() -> void:
	weapon = wrapi(weapon-1,0,weapons.size())
	set_weapon(weapons[weapon])

func _on_weapon_right_pressed() -> void:
	weapon = wrapi(weapon+1,0,weapons.size())
	set_weapon(weapons[weapon])

func set_weapon(weapon_name):
	weapon_preview.texture = load("res://assets/sprites/weapons/"+weapon_name+".svg")

func set_character(character_name):
	character_preview.texture = load("res://assets/sprites/characters/"+character_name+"-body.svg")

func _on_ready_toggled(toggled_on: bool) -> void:
	ready_button.text = "Ready" if toggled_on else "Unready"
	world.character_select.hide()
	world.hud.show()
	world.player_ready.rpc_id(1,characters[character],weapons[weapon])
