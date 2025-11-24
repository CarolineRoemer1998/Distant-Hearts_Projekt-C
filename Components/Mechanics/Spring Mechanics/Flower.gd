extends StaticBody2D

class_name Flower

@onready var flower: AnimatedSprite2D = $Flower
@onready var seed: Sprite2D = $Seed

func _ready() -> void:
	set_collision_layer_value(Constants.LAYER_BIT_FLOWER, true)
	

func grow():
	
	Signals.flower_grows.emit(self)
