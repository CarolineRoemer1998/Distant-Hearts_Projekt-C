extends PushableObject

class_name Stone

## Initializes the stone when the scene starts:
## adds it to the stone group, enables collision and snaps to the grid.
func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_STONES))
	enable_collision_layer()


func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, true)

func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)
