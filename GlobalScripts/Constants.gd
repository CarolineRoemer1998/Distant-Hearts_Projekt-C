extends Node

# GENERAL
const GRID_SIZE := Vector2(64, 64)
const MOVE_SPEED := 500.0
const PLAYER_MOVE_SPEED := 500.0

# GROUPS
const GROUP_NAME_PLAYER := "Player"
const GROUP_NAME_CREATURE := "Creature"
const GROUP_NAME_MERGED_CREATURE := "MergedCreature"
const GROUP_NAME_DOORS := "Door"
const GROUP_NAME_BUTTONS := "Button"
const GROUP_NAME_STONES := "Stone"

# LAYER BITS
const LAYER_BIT_WALL_AND_PLAYER		:= 0
const LAYER_BIT_CREATURE 			:= 1
const LAYER_BIT_STONE 				:= 2
const LAYER_BIT_DOOR    			:= 3
const LAYER_BIT_ICE     			:= 5
const LAYER_BIT_LEVEL_WALL	 		:= 6
const LAYER_MASK_BLOCKING_OBJECTS 	:= (1 << Constants.LAYER_BIT_STONE) | (1 << Constants.LAYER_BIT_DOOR) | (1 << Constants.LAYER_BIT_WALL_AND_PLAYER) | (1 << Constants.LAYER_BIT_CREATURE)

# FIELD POSITIONS
const FIELD_POSITION_RIGHT := Vector2(32,0)
const FIELD_POSITION_BOTTOM := Vector2(0,32)
const FIELD_POSITION_LEFT := Vector2(-32,0)
const FIELD_POSITION_TOP := Vector2(0,-32)

# COLORS
const PLAYER_MODULATE_VISIBLE := Color(1, 1, 1, 0.8)
const PLAYER_MODULATE_INVISIBLE := Color(1, 1, 1, 0)

# LEVELS
const LEVELS = {
	1:  "res://Components/Levels/Scenes/Level1.tscn",
	2:  "res://Components/Levels/Scenes/Level2.tscn",
	3:  "res://Components/Levels/Scenes/Level3.tscn",
	4:  "res://Components/Levels/Scenes/Level4.tscn",
	5:  "res://Components/Levels/Scenes/Level5.tscn",
	6:  "res://Components/Levels/Scenes/Level6.tscn",
	7:  "res://Components/Levels/Scenes/Level7.tscn",
	8:  "res://Components/Levels/Scenes/Level8.tscn",
	9:  "res://Components/Levels/Scenes/Level9.tscn",
	10: "res://Components/Levels/Scenes/Level10.tscn"
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
const SFX_POSSESS := 			""
const SFX_UNPOSSESS := 			""
const SFX_BUTTON_PRESSED := 	""
const SFX_BUTTON_UNPRESSED := 	""
const SFX_PUSH_MENU_BUTTON := 	"res://Sounds/SFX/push_menu_button.mp3"

# BGM PATHS
const BGM_PATH_TITLE_THEME := 	"res://Sounds/BGM/title-track.mp3"
const BGM_PATH_WINTER_THEME := 	"res://Sounds/BGM/BGM-Winter.mp3"
const BGM_PATH_SUMMER_THEME := 	"res://Sounds/BGM/BGM-Summer.mp3"

# SPRITES
const SPRITE_PATH_DOOR_OPEN := 					"res://Assets/Doors/fence-gate-open.png"
const SPRITE_PATH_DOOR_CLOSED := 				"res://Assets/Doors/fence-gate-closed.png"
const SPRITE_PATH_ICE_FLOOR := 					"res://Assets/Winter Mechanics/Ice Floors/Ice-floor.png"
const SPRITE_PATH_STICKY_BUTTON_UNPRESSED := 	"res://Sprites/button_unpressed.png"
const SPRITE_PATH_STICKY_BUTTON_PRESSED := 		"res://Sprites/button_pressed.png"
const SPRITE_PATH_PRESSURE_PLATE_UNPRESSED := 	"res://Sprites/pressure_plate_off.png"
const SPRITE_PATH_PRESSURE_PLATE_PRESSED := 	"res://Sprites/pressure_plate_on.png"
const SPRITE_PATH_TOGGLE_BUTTON_UNPRESSED := 	"res://Sprites/toggle-button-purple.png"
const SPRITE_PATH_TOGGLE_BUTTON_PRESSED := 		"res://Sprites/toggle-button-orange.png"
