extends Node2D

@onready var leaf = preload(Constants.ANIMATED_SPRITE_CHERRY_BLOSSOM)

@export var amount_leaves := 40

func _ready() -> void:
	for i in amount_leaves:
		var new_leaf = leaf.instantiate()
		add_child(new_leaf)
