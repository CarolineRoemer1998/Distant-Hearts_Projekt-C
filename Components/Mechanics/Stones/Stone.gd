extends PushableObject

class_name Stone

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
	return {
		"global_position": global_position,
		"target_position": target_position
	}

## Restores the stone state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_moving = false
	is_sliding = false
	
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO

func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, true)

func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_PUSHABLE+1, false)
