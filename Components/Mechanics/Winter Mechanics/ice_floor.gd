extends Node2D

class_name IceFloor

@export var texture: Texture2D = preload(Constants.SPRITE_PATH_ICE_FLOOR)

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.texture = texture
