extends WorldEnvironment

func _ready() -> void:
	Signals.level_loaded.connect(set_glow_according_to_season)

func set_glow_according_to_season(season: Constants.SEASON):
	match season:
		Constants.SEASON.Intro:
			set_glow_according_to_season_spring()
		Constants.SEASON.Spring:
			set_glow_according_to_season_spring()
		Constants.SEASON.Summer:
			set_glow_according_to_season_spring()
		Constants.SEASON.Fall:
			set_glow_according_to_season_spring()
		Constants.SEASON.Winter:
			set_glow_according_to_season_winter()

func set_glow_according_to_season_spring():
	environment.glow_enabled = true
	environment.glow_normalized = true
	environment.glow_intensity = 2.0
	environment.glow_strength = 1.1
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 0.8
	environment.glow_hdr_scale = 1.0
	
	#environment.glow_enabled = true
	#environment.glow_normalized = false
	#environment.glow_intensity = 1.5
	#environment.glow_strength = 1.0
	#environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	#environment.glow_hdr_threshold = 0.6
	#environment.glow_hdr_scale = 2.0

func set_glow_according_to_season_winter():
	environment.glow_enabled = true
	environment.glow_normalized = true
	environment.glow_intensity = 3.0
	environment.glow_strength = 1.1
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 1.0
	environment.glow_hdr_scale = 1.0
