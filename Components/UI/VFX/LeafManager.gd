extends Node2D

@onready var leaf = preload(Constants.ANIMATED_SPRITE_CHERRY_BLOSSOM)
@onready var level: Level = $"../../.."

@export var amount_leaves := 40

func _ready() -> void:
	if level.season == Constants.SEASON.Spring:
		leaf = preload(Constants.ANIMATED_SPRITE_CHERRY_BLOSSOM)
	if level.season == Constants.SEASON.Summer:
		leaf = preload(Constants.ANIMATED_SPRITE_POLLEN)
	if level.season == Constants.SEASON.Fall:
		leaf = preload(Constants.ANIMATED_SPRITE_FALL_LEAVES)
	if level.season == Constants.SEASON.Winter:
		leaf = preload(Constants.ANIMATED_SPRITE_SNOWFLAKE)
	for i in amount_leaves:
		var new_leaf = leaf.instantiate()
		add_child(new_leaf)
