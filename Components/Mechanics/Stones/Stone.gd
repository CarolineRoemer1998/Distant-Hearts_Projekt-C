extends PushableObject

class_name Stone

@onready var sprite_stone: Sprite2D = $SpriteStone
@onready var animated_sprite_platform: AnimatedSprite2D = $AnimatedSpritePlatform
@onready var splash_animated_sprites: AnimatedSprite2D = $SplashAnimatedSprites
@onready var sound_stone_in_water: AudioStreamPlayer2D = $SoundStoneInWater
@onready var sound_water: AudioStreamPlayer2D = $SoundWater
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const MODULATE_INIT := Color(1.0, 1.0, 1.0)
const MODULATE_UNDER_WATER := Color(0.775, 1.288, 1.416)

var is_in_water := false

var is_hidden := false
var object_hiding_under : PileOfLeaves = null


## Initializes the stone when the scene starts:
## adds it to the stone group, enables collision and snaps to the grid.
func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_STONES))
	check_is_hidden()
	#enable_collision_layer()

func _set_target_position(val: Vector2):
	if not is_hidden:
		super(val)
	else:
		return

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
	info["is_hidden"] = is_hidden
	info["object_hiding_under"] = object_hiding_under
	if not is_in_water:
		info["position"] = Vector2(0.0, 0.0)
	else:
		info["position"] = Vector2(0.0, 18.0)
	return info

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
		sprite_stone.position[1] = info.get("position")[1]
		animated_sprite_platform.position[1] = info.get("position")[1]
		splash_animated_sprites.visible = false
	
	is_in_water = info.get("is_in_water")
	if not is_in_water and sprite_stone.modulate == MODULATE_UNDER_WATER:
		turn_from_platform_back_into_stone()
	
	if info.get("is_hidden") == true and is_hidden == false:
		hide_self(info.get("object_hiding_under"))
	#check_is_hidden()

func check_is_hidden():
	var result_pile_of_leaves = Helper.get_collision_on_tile(global_position, (1 << Constants.LAYER_BIT_PILE_OF_LEAVES), get_world_2d())
	if not result_pile_of_leaves.is_empty() and result_pile_of_leaves[0].collider.is_active:
		hide_self(result_pile_of_leaves[0].collider)
	else:
		object_hiding_under = null
		enable_collision_layer()

func hide_self(pile_of_leaves: PileOfLeaves):
	pile_of_leaves.hidden_stone = self
	is_hidden = true
	visible = false
	object_hiding_under = pile_of_leaves
	disable_collision_layer()

func reveal():
	visible = true
	is_hidden = false
	animation_player.play("Reveal")
	enable_collision_layer()
	
	await get_tree().process_frame

	#var bodies := area.get_overlapping_bodies()
	#for body in bodies:
		#if body != null and (body.is_in_group(Constants.GROUP_NAME_CREATURE) or body.is_in_group(Constants.GROUP_NAME_STONES)):
			#_on_body_entered(body) # nutzt deine vorhandene Logik (Typen, Sounds, Guards)
			#break


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
		var rnd : Array = [0,1,2,3,4,5,6,7,8,9,10,11,12]
		rnd.shuffle()
		animated_sprite_platform.frame = rnd[0]
		animated_sprite_platform.play("default")
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
	if is_hidden:
		return
		
	super._process(delta)
	if is_in_water:
		if roundf(sprite_stone.position[1]*100)/100 < 18:
			sprite_stone.position[1] = lerp(sprite_stone.position[1], 18.0, delta*25)
			animated_sprite_platform.position[1] = lerp(animated_sprite_platform.position[1], 18.0, delta*25)
			if roundf(sprite_stone.position[1]*100)/100 > 9 and not splash_animated_sprites.visible:
				splash_animated_sprites.visible = true
				splash_animated_sprites.play("Splash")
				sound_stone_in_water.play()
				sound_water.play()
		elif animated_sprite_platform.position[1] != 18:
			sprite_stone.position[1] = 18
			animated_sprite_platform.position[1] = 18
	elif not is_in_water:
		if round(sprite_stone.position[1]*100)/100 > 0:
			sprite_stone.position[1] = lerp(sprite_stone.position[1], 0.0, delta*25)
			animated_sprite_platform.position[1] = lerp(animated_sprite_platform.position[1], 0.0, delta*25)
		else:
			sprite_stone.position[1] = 0
			animated_sprite_platform.position[1] = 0
