extends StaticBody2D

@warning_ignore("unused_signal")
signal redstone

@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D

@export var open = false
@export var win_upgrades = 1
@export var level_node: = self
@export var win_abilities:Array[String]

var players_entered := []

func _on_entry_body_entered(body: Node2D) -> void:
	if GLOBALS.is_server:
		if open: return
		if not body.is_in_group('Player'): return
		if GLOBALS.world.enemies > 0: return
		players_entered.append(body)
		if players_entered.size() >= GLOBALS.world.players.size():
			open = true
			open_animation.rpc()
			level_node.emit_signal('redstone')
			GLOBALS.world.start_level(self)
		else:
			for player in GLOBALS.world.players:
				if not players_entered.has(player):
					player.set_target.rpc_id(player.name.to_int(),global_position)

func _on_entry_body_exited(body: Node2D) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or multiplayer.is_server():
		if open: return
		if not body.is_in_group('Player'): return
		players_entered.erase(body)

@rpc("authority","call_local")
func open_animation():
	collision_shape.set_deferred("one_way_collision", true)
	animation_player.play("open")

func close():
	close_animation.rpc()

@rpc("authority","call_local")
func close_animation():
	collision_shape.set_deferred("one_way_collision", false)
	animation_player.play_backwards("open")
