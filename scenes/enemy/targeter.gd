extends Timer

@onready var root := get_tree().root
@onready var world := root.get_node('world')
@export var attachment:Node = get_parent()
@export var target:Node

func set_target():
	if (multiplayer.is_server() or not multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED )and world.players.size() > 0:
		target = null
		for player in world.players:
			if not player.dead:
				var target_distance = attachment.global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < attachment.global_position.distance_to(target.global_position):
					target = player

func _on_timeout() -> void:
	set_target()
