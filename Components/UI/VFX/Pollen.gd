extends Sprite2D

class_name Pollen

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var rnd = RandomNumberGenerator.new()
var init_falling_speed := 35
var falling_speed := 35

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
	animation_player.speed_scale = rnd.randf_range(0.5,1.5)
	animation_player.seek(rnd.randi_range(0, 5))
	falling_speed = init_falling_speed+rnd.randi_range(-10,10)
	start_pos = get_new_start_pos()
	if not is_first:
		while start_pos[0] <= 672 and start_pos[1] >= -32:
			start_pos = get_new_start_pos()
	position = start_pos
	end_pos = start_pos + Vector2(start_pos[0]-subtract_x,start_pos[1]-subtract_y)

func get_new_start_pos() -> Vector2:
	return Vector2(rnd.randi_range(min_x,max_x), rnd.randi_range(min_y,max_y))
