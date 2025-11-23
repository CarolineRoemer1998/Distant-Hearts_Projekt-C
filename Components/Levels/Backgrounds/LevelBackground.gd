extends Node2D

func _ready() -> void:
	Signals.level_loaded.connect(set_modulate_according_to_season)

func set_modulate_according_to_season(season: Constants.SEASON):
	match season:
		Constants.SEASON.Intro:
			set_modulate_according_to_season_intro()
		Constants.SEASON.Spring:
			set_modulate_according_to_season_spring()
		Constants.SEASON.Summer:
			set_modulate_according_to_season_summer()
		Constants.SEASON.Fall:
			set_modulate_according_to_season_fall()
		Constants.SEASON.Winter:
			set_modulate_according_to_season_winter()

func set_modulate_according_to_season_intro():
	pass

func set_modulate_according_to_season_spring():
	pass

func set_modulate_according_to_season_summer():
	pass

func set_modulate_according_to_season_fall():
	pass

func set_modulate_according_to_season_winter():
	modulate = Color(1.0, 1.0, 1.0)
