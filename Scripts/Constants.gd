extends Node

# GENERAL
const GRID_SIZE := Vector2(64, 64)
const MOVE_SPEED := 500.0
const PLAYER_MOVE_SPEED := 500.0

# GROUPS
const GROUP_NAME_PLAYER := "Player"
const GROUP_NAME_CREATURE := "Creature"
const GROUP_NAME_DOORS := "Door"
const GROUP_NAME_BUTTONS := "Button"
const GROUP_NAME_STONES := "Stone"

# LAYER BITS
const LAYER_BIT_WALL_AND_PLAYER	:= 0
const LAYER_BIT_CREATURE 		:= 1
const LAYER_BIT_STONE 			:= 2
const LAYER_BIT_DOOR    		:= 3
const LAYER_BIT_ICE     		:= 5
const LAYER_BIT_LEVEL_WALL	 	:= 6

# FIELD POSITIONS
const FIELD_POSITION_RIGHT := Vector2(32,0)
const FIELD_POSITION_BOTTOM := Vector2(0,32)
const FIELD_POSITION_LEFT := Vector2(-32,0)
const FIELD_POSITION_TOP := Vector2(0,-32)

# SFX
const STEP_SOUND_PITCH_SCALES := [0.95, 0.96, 0.97, 0.98, 0.99, 1, 1.01, 1.02, 1.03, 1.04, 1.05]
const STEP_SOUND_VOLUME_CHANGE := [6.0, 6.5, 7.0, 7.5, 8.0]
