extends GPUParticles2D

class_name WindParticle

var scale_up_down := 			Vector3( 704,  64, 1 )
var scale_left_and_right := 	Vector3(  64, 704, 1 )

var gravity_up := 		Vector3(    0, -100, 0 )
var gravity_down := 	Vector3(    0,  100, 0 )
var gravity_left := 	Vector3( -100,    0, 0 )
var gravity_right := 	Vector3(  100,    0, 0 )

var position_wind_direction_up := 		Vector2(352, 704+64)
var position_wind_direction_down := 	Vector2(352,   0-64)
var position_wind_direction_left := 	Vector2(  0-64, 352)
var position_wind_direction_right := 	Vector2(704+64, 352)

func _ready():
	process_material.set_sub_emitter_amount_at_collision(500)

func set_scale_gravity_and_position(direction: Vector2):
	match direction:
		Vector2.UP:
			process_material.emission_shape_scale 	= scale_up_down
			process_material.gravity 				= gravity_up
			global_position 						= position_wind_direction_up
		Vector2.DOWN:
			process_material.emission_shape_scale 	= scale_up_down
			process_material.gravity 				= gravity_down
			global_position 						= position_wind_direction_down
		Vector2.LEFT:
			process_material.emission_shape_scale 	= scale_left_and_right
			process_material.gravity 				= gravity_left
			global_position 						= position_wind_direction_right
		Vector2.RIGHT:
			process_material.emission_shape_scale 	= scale_left_and_right
			process_material.gravity 				= gravity_right
			global_position 						= position_wind_direction_left
