extends Node

enum SEASON {Intro, Spring, Summer, Fall, Winter}

# GENERAL
const GRID_SIZE := Vector2(64, 64)
const MOVE_SPEED := 500.0
const PLAYER_MOVE_SPEED := 500.0
const TIMER_STEP := 0.125
const TIMER_STEP_AFTER_AVOIDING := 0.125

# DIRECTIONS
const UP = 			Vector2( 0,-1)
const UP_RIGHT = 	Vector2( 1,-1)
const RIGHT = 		Vector2( 1, 0)
const DOWN_RIGHT = 	Vector2( 1, 1)
const DOWN = 		Vector2( 0, 1)
const DOWN_LEFT = 	Vector2(-1, 1)
const LEFT = 		Vector2(-1, 0)
const UP_LEFT = 	Vector2(-1,-1)
const MIDDLE = 		Vector2( 0, 0)

# GROUPS
const GROUP_NAME_PLAYER := "Player"
const GROUP_NAME_CREATURE := "Creature"
const GROUP_NAME_MERGED_CREATURE := "MergedCreature"
const GROUP_NAME_DOORS := "Door"
const GROUP_NAME_BUTTONS := "Button"
const GROUP_NAME_PUSHABLES := "Pushable"
const GROUP_NAME_STONES := "Stone"
const GROUP_NAME_FLOWER_SEEDS := "FlowerSeed"
const GROUP_NAME_FLOWERS := "Flower"
const GROUP_NAME_BEES := "Bees"
const GROUP_NAME_TELEPORTERS := "Teleporter"
const GROUP_NAME_TELEPORTER_MANAGERS := "TeleporterManager"
const GROUP_NAME_WATER_TILE := "WaterTile"
const GROUP_NAME_LILY_PAD := "LilyPad"

# LAYER BITS
const LAYER_BIT_WALL_AND_PLAYER		:= 0
const LAYER_BIT_CREATURE 			:= 1
const LAYER_BIT_PUSHABLE 			:= 2
const LAYER_BIT_DOOR    			:= 3
const LAYER_BIT_BEES				:= 4
const LAYER_BIT_ICE     			:= 5
const LAYER_BIT_LEVEL_WALL	 		:= 6
const LAYER_BIT_TELEPORTER	 		:= 7
const LAYER_BIT_FLOWER				:= 8
const LAYER_BIT_SOIL				:= 9
const LAYER_BIT_BUTTONS				:= 10
const LAYER_BIT_STONES				:= 11
const LAYER_BIT_BEE_AREA			:= 12
const LAYER_BIT_WATER				:= 13
const LAYER_BIT_WATER_PLATFORM		:= 14
const LAYER_BIT_LILY_PAD			:= 15

const LAYER_MASK_BEES				:= (1 << Constants.LAYER_BIT_BEES)
const LAYER_MASK_BLOCKING_OBJECTS 	:= (1 << Constants.LAYER_BIT_PUSHABLE) | (1 << Constants.LAYER_BIT_DOOR) | (1 << Constants.LAYER_BIT_WALL_AND_PLAYER) | (1 << Constants.LAYER_BIT_CREATURE) | (1 << Constants.LAYER_BIT_LEVEL_WALL) | (1 << Constants.LAYER_BIT_SOIL)


# Y SORT
const Y_UI := 10
const Y_TELEPORTER_WOOSH := 9

# FIELD POSITIONS
const FIELD_POSITION_RIGHT := Vector2(32,0)
const FIELD_POSITION_BOTTOM := Vector2(0,32)
const FIELD_POSITION_LEFT := Vector2(-32,0)
const FIELD_POSITION_TOP := Vector2(0,-32)

# COLORS
const PLAYER_MODULATE_VISIBLE := 		Color(1.2, 1.2, 1.2, 0.6)
const PLAYER_MODULATE_INVISIBLE := 		Color(1, 1, 1, 0)

#const CREATURE_MODULATE_POSSESSED :=	Color(1.2, 1.2, 1.2)
const CREATURE_MODULATE_POSSESSED :=	Color(1.1, 1.1, 1.1)
const CREATURE_MODULATE_UNPOSSESSED :=	Color(1.1, 1.1, 1.1)

const TELEPORTER_MODULATE_INACTIVE :=	Color(0.969, 0.969, 0.969)
const TELEPORTER_MODULATE_ACTIVE :=		Color(1.551, 1.363, 1.54)

# LEVELS
const LEVELS = {
		 # INTRO
	1:   "res://Components/Levels/1 - Intro/LevelIntro1.tscn",
	2:   "res://Components/Levels/1 - Intro/LevelIntro2.tscn",
	3:   "res://Components/Levels/1 - Intro/LevelIntro3.tscn",
	4:   "res://Components/Levels/1 - Intro/LevelIntro4.tscn",
	5:   "res://Components/Levels/1 - Intro/LevelIntro5.tscn",
		 # SPRING
	6:   "res://Components/Levels/2 - Spring/LevelSpring1.tscn",
	7:   "res://Components/Levels/2 - Spring/LevelSpring2.tscn",
	8:   "res://Components/Levels/2 - Spring/LevelSpring3.tscn",
	9:   "res://Components/Levels/2 - Spring/LevelSpring4.tscn",
	10:  "res://Components/Levels/2 - Spring/LevelSpring5.tscn",
		 # SUMMER
	11:  "res://Components/Levels/3 - Summer/LevelSummer1.tscn",
	12:  "res://Components/Levels/3 - Summer/LevelSummer2.tscn",
	13:  "res://Components/Levels/3 - Summer/LevelSummer3.tscn",
	14:  "res://Components/Levels/3 - Summer/LevelSummer4.tscn",
	15:  "res://Components/Levels/3 - Summer/LevelSummer5.tscn",
		 # FALL
	16:  "res://Components/Levels/4 - Fall/LevelFall1.tscn",
	17:  "res://Components/Levels/4 - Fall/LevelFall2.tscn",
	18:  "res://Components/Levels/4 - Fall/LevelFall3.tscn",
	19:  "res://Components/Levels/4 - Fall/LevelFall4.tscn",
	20:  "res://Components/Levels/4 - Fall/LevelFall5.tscn",
		 # WINTER
	21:  "res://Components/Levels/5 - Winter/LevelWinter1.tscn",
	22:  "res://Components/Levels/5 - Winter/LevelWinter2.tscn",
	23:  "res://Components/Levels/5 - Winter/LevelWinter3.tscn",
	24:  "res://Components/Levels/5 - Winter/LevelWinter4.tscn",
	25: "res://Components/Levels/5 - Winter/LevelWinter5.tscn"
}

# MENUES
const PATH_CREDIT_SCENE := 		"res://Components/UI/Menues/credit_scene.tscn"
const PATH_FADE := 				"res://Components/UI/Menues/fade.tscn"
const PATH_GAME_COMPLETED := 	"res://Components/UI/Menues/game_completed.tscn"
const PATH_IN_GAME_SETTINGS := 	"res://Components/UI/Menues/InGameSettings.tscn"
const PATH_LEVEL_SELECT := 		"res://Components/UI/Menues/Level_Select.tscn"
const PATH_MAIN_MENU := 		"res://Components/UI/Menues/MainMenu.tscn"
const PATH_SETTINGS := 			"res://Components/UI/Menues/Settings.tscn"
const PATH_VOLUME_SLIDER := 	"res://Components/UI/Controls/VolumeSlider.tscn"
const PATH_WIN_SCREEN := 		"res://Components/UI/Menues/win_screen.tscn"

# SFX SETTINGS
const STEP_SOUND_PITCH_SCALES := [0.95, 0.96, 0.97, 0.98, 0.99, 1, 1.01, 1.02, 1.03, 1.04, 1.05]
const STEP_SOUND_VOLUME_CHANGE := [6.0, 6.5, 7.0, 7.5, 8.0]

# SFX PATHS
const SFX_PATH_STEP := 			"res://Sounds/SFX/step.mp3"
const SFX_POSSESS := 			"res://Sounds/SFX/possess.mp3"
const SFX_UNPOSSESS := 			"res://Sounds/SFX/unpossess.mp3"
const SFX_BUTTON_PRESSED := 	"res://Sounds/SFX/button_on.mp3"
const SFX_BUTTON_UNPRESSED := 	"res://Sounds/SFX/button_off.mp3"
const SFX_PUSH_MENU_BUTTON := 	"res://Sounds/SFX/button_menu_click.mp3"
#const SFX_TELEPORT :=			"res://Sounds/SFX/teleport_test/teleport-game-sound-effect-379236.mp3"
const SFX_TELEPORT :=			"res://Sounds/SFX/teleport_test/scifi-anime-whoosh-59-205276.mp3"
#const SFX_TELEPORT :=			"res://Sounds/SFX/teleport_test/scifi-anime-whoosh-52-205271.mp3"
#const SFX_TELEPORT :=			"res://Sounds/SFX/teleport-1.mp3"

# BGM PATHS
const BGM_PATH_TITLE_THEME := 	"res://Sounds/BGM/title-theme.mp3"
const BGM_PATH_WINTER_THEME := 	"res://Sounds/BGM/BGM-Winter.mp3"
const BGM_PATH_SUMMER_THEME := 	"res://Sounds/BGM/BGM-Summer.mp3"

# SPRITES
const SPRITE_PATH_DOOR_OPEN := 					"res://Assets/Doors/fence-gate-open.png"
const SPRITE_PATH_DOOR_CLOSED := 				"res://Assets/Doors/fence-gate-closed.png"
const SPRITE_PATH_ICE_FLOOR := 					"res://Assets/Winter Mechanics/Ice Floors/Ice-floor.png"
const SPRITE_PATH_STICKY_BUTTON_UNPRESSED := 	"res://Assets/Buttons/button_unpressed.png"
const SPRITE_PATH_STICKY_BUTTON_PRESSED := 		"res://Assets/Buttons/button_pressed.png"
const SPRITE_PATH_PRESSURE_PLATE_UNPRESSED := 	"res://Assets/Buttons/pressure_plate_off.png"
const SPRITE_PATH_PRESSURE_PLATE_PRESSED := 	"res://Assets/Buttons/pressure_plate_on.png"
const SPRITE_PATH_TOGGLE_BUTTON_UNPRESSED := 	"res://Assets/Buttons/toggle-button-purple.png"
const SPRITE_PATH_TOGGLE_BUTTON_PRESSED := 		"res://Assets/Buttons/toggle-button-orange.png"
const SPRITE_PATH_STONE_UNDER_WATER_SHEET :=	"res://Assets/Stones/stone-under-water.png"

const ANIMATED_SPRITE_CHERRY_BLOSSOM := "res://Components/UI/VFX/CherryBlossomSprite.tscn"

const trails := ["res://Assets/Particles/dot1.png", "res://Assets/Particles/dot2.png", "res://Assets/Particles/dot3.png"]
