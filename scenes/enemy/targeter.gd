extends Timer

@export var attachment:Node = get_parent()
@export var target:Node

func set_target():
	if GLOBALS.is_server and GLOBALS.world.players.size() > 0:
		target = null
		for player in GLOBALS.world.players:
			if not player.dead:
				var target_distance = attachment.global_position.distance_to(player.global_position)
				if not target or target.dead or target_distance < attachment.global_position.distance_to(target.global_position):
					target = player

func _on_timeout() -> void:
	set_target()
