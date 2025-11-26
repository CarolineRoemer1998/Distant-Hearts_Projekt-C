extends PushableObject

class_name FlowerSeed

enum STATE {
	Seed, Flower
}

@onready var sprite_flower: AnimatedSprite2D = $Flower
@onready var sprite_seed: Sprite2D = $Seed
@onready var pollen: GPUParticles2D = $Pollen
@onready var collider: CollisionShape2D = $CollisionShape2D

var current_state := STATE.Seed

func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_PUSHABLES))
	add_to_group(str(Constants.GROUP_NAME_FLOWER_SEEDS))
	enable_collision_layer()

# -----------------------------------------------------------
# State (e.g. for Undo)
# -----------------------------------------------------------
## Returns a Dictionary snapshot of the FlowerSeed state
## used for Undo/Redo (position + target position).
func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"target_position": target_position,
		"current_state": current_state
	}

## Restores the FlowerSeed state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_moving = false
	is_sliding = false
	
	var turns_back_into_seed = current_state == STATE.Flower and info.get("current_state") == STATE.Seed
	current_state = info.get("current_state")
	if turns_back_into_seed:
		turn_back_into_seed()
		# TODO: Play Animation for turning into Seed
	
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO

func enable_collision_layer():
	if is_in_group(Constants.GROUP_NAME_PUSHABLES):
		set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, true)
	if is_in_group(Constants.GROUP_NAME_FLOWERS):
		set_collision_layer_value(Constants.LAYER_BIT_FLOWER+1, true)

func disable_collision_layer():
	if is_in_group(Constants.GROUP_NAME_PUSHABLES):
		set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, false)
	if is_in_group(Constants.GROUP_NAME_FLOWERS):
		set_collision_layer_value(Constants.LAYER_BIT_FLOWER+1, false)

func turn_back_into_seed():
	remove_from_group(str(Constants.GROUP_NAME_FLOWERS))
	for i in range(1, 20):
		set_collision_layer_value(i, false)
	set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, true)
	sprite_seed.visible = true
	sprite_flower.visible = false
	pollen.visible = false

func grow():
	current_state = STATE.Flower
	add_to_group(str(Constants.GROUP_NAME_FLOWERS))
	for i in range(1, 20):
		set_collision_layer_value(i, false)
	set_collision_layer_value(Constants.LAYER_BIT_FLOWER+1, true)
	sprite_seed.visible = false
	sprite_flower.visible = true
	pollen.visible = true
	Signals.flower_grows.emit(self)
