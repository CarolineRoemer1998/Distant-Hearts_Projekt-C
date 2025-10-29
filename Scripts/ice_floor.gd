extends Node2D

class_name IceFloor
@export var texture: Texture2D = preload("res://Sprites/IceFloor/Ice-floor.png")

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.texture = texture
