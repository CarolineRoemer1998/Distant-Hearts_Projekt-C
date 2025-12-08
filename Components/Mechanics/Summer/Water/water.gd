extends Node2D

class_name Water

@onready var water_light: Node2D = $WaterLight
@onready var water_dark: Node2D = $WaterDark
@onready var timer: Timer = $Timer

@onready var grass_floor: TileMapLayer = $grass_floor

@onready var water_light_2: Sprite2D = $WaterLight/Water_light_2
@onready var water_light_3: Sprite2D = $WaterLight/Water_light_3
@onready var water_light_4: Sprite2D = $WaterLight/Water_light_4

@onready var water_dark_2: Sprite2D = $WaterDark/Water_dark_2
@onready var water_dark_3: Sprite2D = $WaterDark/Water_dark_3
@onready var water_dark_4: Sprite2D = $WaterDark/Water_dark_4

var init_position = Vector2(704,0)
var last_position = Vector2(0,0)

var water_light_speed = 15
var water_dark_speed_slow = 10
var water_dark_speed_fast = 20

var float_up := true

func _ready() -> void:
	grass_floor.visible = true
	water_light_2.visible = true
	water_light_3.visible = true
	water_light_4.visible = true
	water_dark_2.visible = true
	water_light_3.visible = true
	water_light_4.visible = true
	
	water_light.position = init_position
	water_dark.position = init_position
	timer.start()

func _process(delta: float) -> void:
	water_light.position[0] += -water_light_speed*delta
	
	if float_up:
		water_light.position[1] += -5*delta
		water_dark.position[0] += -water_dark_speed_slow*delta
		#water_dark.position += Vector2(-water_dark_speed_slow*delta,5*delta)
	else:
		water_light.position[1] += 5*delta
		water_dark.position[0] += -water_dark_speed_slow*delta
		#water_dark.position += Vector2(-water_dark_speed_fast*delta,-5*delta)
	
	if water_light.position[0] <= last_position[0]:
		water_light.position[0] = init_position[0]
		
	if water_dark.position[0] <= last_position[0]:
		water_dark.position[0] = init_position[0]


func _on_timer_timeout() -> void:
	float_up = !float_up
	timer.start()
