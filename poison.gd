extends Timer

var damage = 5
var total_hits = 5
@onready var entity = get_parent()
@onready var healthbar = entity.get_node('healthbar')
var armor_pierce = true
var color = Color(0.502, 0.549, 0.314, 1.0)

func _ready() -> void:
	entity.modulate = color

func _on_timeout() -> void:
	healthbar.change_health(-damage,armor_pierce)
	total_hits -= 1
	if total_hits <= 0:
		queue_free()
