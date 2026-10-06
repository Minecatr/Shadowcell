extends Area2D

var effects:Dictionary
var damage:int
var hit_enemies:Array
var dying:bool = false
var chains:int = 12

@onready var collision_shape = $CollisionShape2D

func _on_timer_timeout() -> void:
	dying = true
	queue_free()


func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	if GLOBALS.is_server and not dying and body.is_in_group('Enemy') and not hit_enemies.has(body) and chains > 0:
		hit_enemies.append(body)
		body.get_node('HealthBar').change_health(damage,effects)
		make_line.rpc(get_child(local_shape_index+1).position,body.global_position-global_position)
		var new_shape: = CollisionShape2D.new()
		new_shape.shape = collision_shape.shape
		new_shape.position = (body.global_position-global_position)
		call_deferred("add_child",new_shape)
		chains -= 1

@rpc("authority","call_local")
func make_line(one,two):
	var line: = Line2D.new()
	line.add_point(one)
	line.add_point(two)
	line.width = 4
	line.default_color = Color('76faff')
	line.z_index = 1
	call_deferred("add_child",line)
