extends Stone

class_name FlowerSeed

@onready var flower: AnimatedSprite2D = $Flower
@onready var flower_seed: Sprite2D = $Seed
@onready var pollen: GPUParticles2D = $Pollen

func _ready():
	super._ready()
	#add_to_group(str(Constants.GROUP_NAME_STONES))
	#set_collision_layer_value(Constants.LAYER_BIT_STONE, true)
	#target_position = position.snapped(Constants.GRID_SIZE / 2)
	#position = target_position
	#print(get_groups())

func grow():
	remove_from_group(Constants.GROUP_NAME_STONES)
	add_to_group(str(Constants.GROUP_NAME_FLOWER_SEED))
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)
	set_collision_layer_value(Constants.LAYER_BIT_FLOWER, true)
	flower_seed.visible = false
	flower.visible = true
	pollen.visible = true
	Signals.flower_grows.emit(self)
