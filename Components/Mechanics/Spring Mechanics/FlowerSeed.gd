extends PushableObject

class_name FlowerSeed

@onready var flower: AnimatedSprite2D = $SpriteFlower
@onready var flower_seed: Sprite2D = $SpriteSeed
@onready var pollen: GPUParticles2D = $Pollen
@onready var collider: CollisionShape2D = $CollisionShape2D


func _ready():
	super._ready()
	add_to_group(str(Constants.GROUP_NAME_STONES))
	enable_collision_layer()

func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, true)

func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)

func grow():
	remove_from_group(Constants.GROUP_NAME_STONES)
	add_to_group(str(Constants.GROUP_NAME_FLOWER_SEED))
	for i in range(1, 20):
		set_collision_layer_value(i, false)
	set_collision_layer_value(Constants.LAYER_BIT_FLOWER+1, true)
	flower_seed.visible = false
	flower.visible = true
	pollen.visible = true
	Signals.flower_grows.emit(self)
