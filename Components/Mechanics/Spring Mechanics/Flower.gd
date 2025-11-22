extends StaticBody2D

class_name Flower


func _ready() -> void:
	set_collision_layer_value(Constants.LAYER_BIT_FLOWER, true)
	Signals.flower_grows.emit(self)
