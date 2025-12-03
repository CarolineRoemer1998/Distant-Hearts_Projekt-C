extends StaticBody2D

class_name LilyPad

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var object_sprites_on_lily_pad : Array[Node2D] = []

## TODO: in _ready() direkt für WasserTile auf dem es ist sich selbst als "stone_in_water" (umbenennen) setzen
## TODO: Ändern wenn es untergeht

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


func _on_area_2d_body_exited(body: Node2D) -> void:
	for sprite in object_sprites_on_lily_pad:
		sprite.position[0] = 0.0
	object_sprites_on_lily_pad = []
