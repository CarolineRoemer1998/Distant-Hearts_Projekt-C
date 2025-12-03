extends PushableObject

class_name Stone

@onready var sprite_stone: Sprite2D = $SpriteStone
@onready var animated_sprite_platform: AnimatedSprite2D = $AnimatedSpritePlatform

const MODULATE_INIT := Color(1.0, 1.0, 1.0)
const MODULATE_UNDER_WATER := Color(0.775, 1.288, 1.416)

var is_in_water := false

## Initializes the stone when the scene starts:
## adds it to the stone group, enables collision and snaps to the grid.
func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_STONES))
	enable_collision_layer()

# -----------------------------------------------------------
# State (e.g. for Undo)
# -----------------------------------------------------------
## Returns a Dictionary snapshot of the stone state
## used for Undo/Redo (position + target position).
func get_info() -> Dictionary:
	var info = {}
	info["global_position"] = global_position.snapped(Constants.GRID_SIZE / 2)
	info["target_position"] = target_position.snapped(Constants.GRID_SIZE / 2)
	info["is_in_water"] = is_in_water
	if not is_in_water:
		info["position"] = Vector2(0.0, 0.0)
	else:
		info["position"] = Vector2(0.0, 18.0)
	return info
	#info["global_position"] = global_position.snapped(Constants.GRID_SIZE / 2)
	#return {
		#"global_position": global_position.snapped(Constants.GRID_SIZE / 2),
		#"target_position": target_position.snapped(Constants.GRID_SIZE / 2),
		#"position": position.snapped(Vector2(18.0,18.0)),
		#"is_in_water": is_in_water
	#}

## Restores the stone state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_moving = false
	is_sliding = false
	
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO
	
	if is_in_water != info.get("is_in_water"):
		sprite_stone.position = info.get("position")
		animated_sprite_platform.position = info.get("position")
	
	is_in_water = info.get("is_in_water")
	if not is_in_water and sprite_stone.modulate == MODULATE_UNDER_WATER:
		turn_from_platform_back_into_stone()

func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, true)
	set_collision_layer_value(Constants.LAYER_BIT_STONES+1, true)

func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, false)
	set_collision_layer_value(Constants.LAYER_BIT_STONES+1, false)

func turn_into_platform_in_water():
	if is_in_water:
		sprite_stone.modulate = MODULATE_UNDER_WATER
		animated_sprite_platform.visible = true
		z_index -= 2
		disable_collision_layer()
		set_collision_layer_value(Constants.LAYER_BIT_WATER_PLATFORM+1, true)

func turn_from_platform_back_into_stone():
	sprite_stone.modulate = MODULATE_INIT
	animated_sprite_platform.visible = false
	z_index += 2
	enable_collision_layer()
	set_collision_layer_value(Constants.LAYER_BIT_WATER_PLATFORM+1, false)

func _process(delta):
	super._process(delta)
	if is_in_water:
		if roundf(sprite_stone.position[1]*100)/100 < 18:
			sprite_stone.position[1] = lerp(sprite_stone.position[1], 18.0, delta*25)
			animated_sprite_platform.position[1] = lerp(animated_sprite_platform.position[1], 18.0, delta*25)
		else:
			sprite_stone.position[1] = 18
			animated_sprite_platform.position[1] = 18
	elif not is_in_water:
		if round(sprite_stone.position[1]*100)/100 > 0:
			sprite_stone.position[1] = lerp(sprite_stone.position[1], 0.0, delta*25)
			animated_sprite_platform.position[1] = lerp(animated_sprite_platform.position[1], 0.0, delta*25)
		else:
			sprite_stone.position[1] = 0
			animated_sprite_platform.position[1] = 0
