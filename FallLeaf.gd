extends AnimatedSprite2D

class_name FallLeaf

var color_variations = [
	Color(1.0, 0.659, 0.36, 1.0), 
	Color(1.0, 0.583, 0.294, 1.0), 
	Color(1.0, 0.43, 0.42, 1.0), 
	Color(1.0, 0.436, 0.376, 1.0), 
	Color(1.177, 1.129, 0.599, 1.0),
	Color(1.119, 0.823, 0.0, 1.0)
]

var rnd = RandomNumberGenerator.new()
var init_falling_speed := 50
var falling_speed := 50

var min_x := 	32
var max_x := 	1344
var min_y := 	-736
var max_y := 	608

var subtract_x := 672*4
var subtract_y := -672*4

var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

func _ready() -> void:
	set_new_starting_pos(true)

func _process(delta: float) -> void:
	position = position.move_toward(end_pos, falling_speed * delta)
	if position[1] > 736:
		set_new_starting_pos(false)

func set_new_starting_pos(is_first: bool):
	modulate = color_variations[rnd.randi_range(0,5)]
	speed_scale = 1 + rnd.randf_range(-0.05, 0.05)
	frame = rnd.randi_range(0,3)
	falling_speed = init_falling_speed+rnd.randi_range(-25,25)
	start_pos = get_new_start_pos()
	if not is_first:
		while start_pos[0] <= 672 and start_pos[1] >= -32:
			start_pos = get_new_start_pos()
	position = start_pos
	end_pos = start_pos + Vector2(start_pos[0]-subtract_x,start_pos[1]-subtract_y)

func get_new_start_pos() -> Vector2:
	return Vector2(rnd.randi_range(min_x,max_x), rnd.randi_range(min_y,max_y))
