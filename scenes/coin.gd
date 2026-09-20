extends Area2D

var value : int = 1
var violence : int = 100
var velocity : Vector2 = Vector2.ZERO
var resistance : float = 0.1

func _ready() -> void:
	velocity = Vector2(violence,0).rotated(randf_range(-PI,PI))

func _physics_process(delta: float) -> void:
	translate(velocity*delta)
	velocity = lerp(velocity,Vector2.ZERO,resistance)
