extends StaticBody2D

class_name PileOfLeaves

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_active := true

func _ready() -> void:
	set_collision_layer_value(Constants.LAYER_BIT_PILE_OF_LEAVES+1, true)
	add_to_group(Constants.GROUP_NAME_PILE_OF_LEAVES)
	Signals.wind_blows.connect(fly_away)

func get_info():
	return {
		"is_active": is_active
	}

func set_info(info : Dictionary):
	if not is_active and info.get("is_active") == true:
		animation_player.play("RESET")
	is_active = info.get("is_active")
	

func fly_away(list_of_blown_objects: Dictionary, _blow_direction: Vector2, _wind_particles: GPUParticles2D):
	if is_active:
		for obj in list_of_blown_objects:
			if list_of_blown_objects[obj]["Object"].name == name:
				match Wind.blow_direction:
					Vector2.UP:
						animation_player.play("FlyAway_Up")
						is_active = false
					Vector2.DOWN:
						animation_player.play("FlyAway_Down")
						is_active = false
					Vector2.LEFT:
						animation_player.play("FlyAway_Left")
						is_active = false
					Vector2.RIGHT:
						animation_player.play("FlyAway_Right")
						is_active = false
	
