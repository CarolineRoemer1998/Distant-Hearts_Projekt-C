extends AnimatedSprite2D

class_name SingleBee

@export var init_scale := Vector2(2.0,2.0)

func _ready() -> void:
	scale = init_scale
