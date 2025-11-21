extends Node2D

class_name Flower

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.set_collision_layer_value(Constants.LAYER_BIT_FLOWER, true)
	Signals.flower_grows.emit(self)
