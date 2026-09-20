extends StaticBody2D

signal redstone

@onready var animation_player = $AnimationPlayer

#@onready var is_server := multiplayer.is_server()
@onready var root := get_tree().root
@onready var world := root.get_node('world')

@export var open = false
@export var win_upgrades = 1

var players_entered := []

func _on_entry_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		if open: return
		if not body.is_in_group('Player'): return
		if world.enemies > 0: return
		players_entered.append(body)
		if players_entered.size() >= world.players.size():
			open = true
			open_animation.rpc()
			emit_signal('redstone')
			world.start_level(self)
		else:
			for wplayer in world.players:
				if not players_entered.has(wplayer):
					wplayer.set_target.rpc_id(wplayer.name.to_int(),global_position)

func _on_entry_body_exited(body: Node2D) -> void:
	if multiplayer.is_server():
		if open: return
		if not body.is_in_group('Player'): return
		players_entered.erase(body)

@rpc("authority","call_local")
func open_animation():
	animation_player.play("open")

func close():
	close_animation.rpc()

@rpc("authority","call_local")
func close_animation():
	animation_player.play_backwards("open")
