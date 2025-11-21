extends Node2D

class_name Flower

func _ready() -> void:
	$Area2D.set_collision_layer_value(Constants.LAYER_BIT_FLOWER, true)
	Signals.flower_grows.emit(self)
