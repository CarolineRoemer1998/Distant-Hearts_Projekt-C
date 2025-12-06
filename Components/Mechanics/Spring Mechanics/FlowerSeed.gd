extends PushableObject

class_name FlowerSeed

enum STATE {
	Seed, Flower
}

@onready var sprite_flower: AnimatedSprite2D = $Flower
@onready var sprite_seed: Sprite2D = $Seed
@onready var pollen: GPUParticles2D = $Pollen
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var twinkle = $Twinkle

var current_state := STATE.Seed

func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_PUSHABLES))
	add_to_group(str(Constants.GROUP_NAME_FLOWER_SEEDS))
	enable_collision_layer()
	layer_mask_obstacles = (1 << Constants.LAYER_BIT_PUSHABLE) | (1 << Constants.LAYER_BIT_DOOR) | (1 << Constants.LAYER_BIT_WALL_AND_PLAYER) | (1 << Constants.LAYER_BIT_CREATURE) | (1 << Constants.LAYER_BIT_LEVEL_WALL)

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

func turn_back_into_seed():
	current_state = STATE.Seed
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
	animation_player.play("Flower_Grow")
	#twinkle.emitting = true
	pollen.visible = true
	var nearest_bee_swarm : BeeSwarm = get_nearest_bee_swarm()
	Signals.flower_grows.emit(self, nearest_bee_swarm)

func get_nearest_bee_swarm() -> BeeSwarm:
	var bee_swarms = get_tree().get_nodes_in_group(Constants.GROUP_NAME_BEES) as Array[BeeSwarm]
	
	var nearest_bee : BeeSwarm = bee_swarms[0]
	var nearest_distance = Helper.get_distance_between_two_vectors(global_position, nearest_bee.global_position)
	
	for bee_swarm in bee_swarms:
		var next_distance = Helper.get_distance_between_two_vectors(global_position, bee_swarm.global_position)
		if next_distance < nearest_distance:
			nearest_bee = bee_swarm
			nearest_distance = next_distance
	
	return nearest_bee


func emit_twinkle():
	twinkle.emitting = true

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
