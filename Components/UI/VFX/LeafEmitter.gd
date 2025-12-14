extends Node2D

class_name LeafEmitter

@onready var spring_particles: Node2D = $Spring
@onready var summer_particles: Node2D = $Summer
@onready var fall_particles: Node2D = $Fall
@onready var winter_particles: Node2D = $Winter

func _ready() -> void:
	spring_particles.visible = false
	summer_particles.visible = false
	fall_particles.visible = false
	winter_particles.visible = false
	
	Signals.level_loaded.connect(set_leaves_according_to_season)


func set_leaves_according_to_season(season: Constants.SEASON):
	match season:
		Constants.SEASON.Spring:
			spring_particles.visible = true
		Constants.SEASON.Summer:
			summer_particles.visible = true
		Constants.SEASON.Fall:
			fall_particles.visible = true
		Constants.SEASON.Winter:
			winter_particles.visible = true
