extends StaticBody2D
class_name Shadow

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_SHADOW)
	appear()

func appear() -> void:
	animation_player.play("Appear")

func disappear_and_free() -> void:
	animation_player.play_backwards("Appear")
	await animation_player.animation_finished
	queue_free()
