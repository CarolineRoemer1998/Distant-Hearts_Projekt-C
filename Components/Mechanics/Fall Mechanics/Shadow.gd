extends StaticBody2D

class_name Shadow

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_SHADOW)
	Signals.player_move_finished.connect(delete_self)
	Signals.undo_executed.connect(delete_self)
	#appear()

func delete_self():
	await get_tree().create_timer(0.25).timeout
	var wind = get_tree().get_first_node_in_group(Constants.GROUP_NAME_WIND)
	if wind != null and wind.set_shadow_positions.has(global_position):
		disappear()
		queue_free()

func appear():
	animation_player.play("Appear")

func disappear():
	animation_player.play_backwards("Appear")
