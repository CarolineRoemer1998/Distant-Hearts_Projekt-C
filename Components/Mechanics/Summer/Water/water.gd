extends Node2D

@onready var water_light: Node2D = $WaterLight
@onready var water_dark: Node2D = $WaterDark
@onready var timer: Timer = $Timer

var init_position = Vector2(704,0)
var last_position = Vector2(0,0)

var water_light_speed = 15
var water_dark_speed_slow = 10
var water_dark_speed_fast = 20

var float_up := true

func _ready() -> void:
	water_light.position = init_position
	water_dark.position = init_position
	timer.start()

func _process(delta: float) -> void:
	water_light.position[0] += -water_light_speed*delta
	
	if water_light.position[0] <= last_position[0]:
		water_light.position[0] = init_position[0]
	
	if float_up:
		water_light.position[1] += -water_dark_speed_slow*delta
		water_dark.position += Vector2(-water_dark_speed_slow*delta,-water_dark_speed_slow*delta)
		
		
		#water_light.position[1] = lerp(0.0, 500.5, delta*10)
		#water_dark.position[1] = lerp(0.0, 500.5, delta*10)
		#water_dark.position[1] += 0.9999
		#water_dark.scale = lerp(water_dark.scale, Vector2(1.005, 1.005), delta)
		#water_light.scale = lerp(water_light.scale, Vector2(1.005, 1.005), delta)
		#water_dark.scale *= 1+(delta*0.005)
		
	else:
		water_light.position[1] += water_dark_speed_slow*delta
		water_dark.position += Vector2(-water_dark_speed_fast*delta,water_dark_speed_slow*delta)
		
		
		#water_light.position[1] = lerp(0.0, -0.5, delta*0.5)
		#water_dark.position[1] = lerp(0.0, -0.5, delta*0.5)
		#water_light.scale = lerp(water_dark.scale,Vector2(0.995, 0.995), delta)
		#water_dark.scale = lerp(water_light.scale, Vector2(0.995, 0.995), delta)
		#water_dark.scale *= 1-(delta*0.005)
	
	if water_dark.position[0] <= last_position[0]:
		water_dark.position[0] = init_position[0]


func _on_timer_timeout() -> void:
	float_up = !float_up
	timer.start()
