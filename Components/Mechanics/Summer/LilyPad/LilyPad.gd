extends StaticBody2D

class_name LilyPad

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var object_sprites_on_lily_pad : Array[Node2D] = []
var has_sunk := false

## TODO: Ändern wenn es untergeht

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_LILY_PAD)
	Signals.set_lily_pad_on_water_tile.emit(self)

func get_info() -> Dictionary:
	return {
		"object_sprites_on_lily_pad": object_sprites_on_lily_pad,
		"has_sunk": has_sunk
	}

func set_info(info: Dictionary):
	object_sprites_on_lily_pad = info.get("object_sprites_on_lily_pad")
	if has_sunk and not info.get("has_sunk"):
		unsink()

func _on_animated_sprite_2d_frame_changed() -> void:
	if object_sprites_on_lily_pad.size() > 0:
		match animated_sprite_2d.frame:
			0:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = 0.0
			1:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = 2.0
			2:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = -0.0
			3:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = -2.0
			4:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = -4.0
			5:
				for sprite in object_sprites_on_lily_pad:
					sprite.position[0] = -2.0

func sink():
	animated_sprite_2d.visible = false
	for col in range(24):
		set_collision_layer_value(col, false)
	has_sunk = true

func unsink():
	animated_sprite_2d.visible = true
	set_collision_layer_value(Constants.LAYER_BIT_LILY_PAD+1, true)
	has_sunk = false
	print("UNSINK!")

func _on_area_2d_body_exited(body: Node2D) -> void:
	for sprite in object_sprites_on_lily_pad:
		sprite.position[0] = 0.0
	object_sprites_on_lily_pad = []
