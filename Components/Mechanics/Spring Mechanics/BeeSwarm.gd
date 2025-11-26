extends StaticBody2D

class_name BeeSwarm

@onready var timer_aggro_cooldown: Timer = $TimerAggroCooldown
@onready var visuals: Node2D = $Visuals

@export var bee_sprites : Array[SingleBee] = []
@export var animation_players : Array[AnimationPlayer] = []

const MODULATE_AGGRO := Color(1.096, 0.278, 0.278)
const MODULATE_NORMAL := Color(1.096, 1.096, 1.096)

var init_position := Vector2.ZERO
var target_position := Vector2.ZERO
var is_aggro := false

var bee_sprite_scale := 2.0
var flying_speed := 200.0
var anim_speed_normal := 1.0
var anim_speed_aggro := 8.0

var is_flying_to_new_position := false


func _ready() -> void:
	Signals.flower_grows.connect(fly_to_flower)
	Signals.bees_near_creature.connect(turn_red)
	Signals.bees_not_near_creature.connect(turn_normal)
	
	add_to_group(Constants.GROUP_NAME_BEES)
	init_position = global_position
	target_position = init_position

func _process(delta: float) -> void:
	if is_aggro:
		modulate = lerp(modulate, MODULATE_AGGRO, delta*4.0)
		for anim_player in animation_players:
			anim_player.speed_scale = lerp(anim_player.speed_scale, anim_speed_aggro, delta*10.0)
	else: 
		modulate = lerp(modulate, MODULATE_NORMAL, delta*2.0)
		for anim_player in animation_players:
			anim_player.speed_scale = lerp(anim_player.speed_scale, anim_speed_normal, delta*8.0)
	
	
	if is_flying_to_new_position:
		visuals.position = lerp(visuals.position, Vector2(-5,-32), delta*5.0)
		position = position.move_toward(target_position, flying_speed*delta)
		
		if abs(position - target_position)[0] < 0.01 and abs(position - target_position)[1] < 0.01:
			position = target_position
			is_flying_to_new_position = false
			reset_bee_sprite_direction()
			Signals.bees_stop_flying.emit()

# -----------------------------------------------------------
# State (e.g. for Undo)
# -----------------------------------------------------------
## Returns a Dictionary snapshot of the FlowerSeed state
## used for Undo/Redo (position + target position).
func get_info() -> Dictionary:
	return {
		#"global_position": global_position,
		"global_position": 				target_position,
		"is_flying_to_new_position": 	is_flying_to_new_position,
		"is_aggro": 					is_aggro
		#"current_state": current_state
	}

## Restores the FlowerSeed state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_flying_to_new_position = info.get("is_flying_to_new_position")
	is_aggro = info.get("is_aggro")



func fly_to_flower(flower: FlowerSeed):
	target_position = flower.global_position
	_change_direction_of_bee_sprites()
	is_flying_to_new_position = true
	Signals.bees_start_flying.emit()

func _change_direction_of_bee_sprites():
	# Look Left
	if (target_position-global_position)[0] < 0: 
		for bee in bee_sprites:
			bee.scale = Vector2(-bee_sprite_scale, bee_sprite_scale)
	# Look Right
	elif (target_position-global_position)[0] > 0: 
		for bee in bee_sprites:
			bee.scale = Vector2(bee_sprite_scale, bee_sprite_scale)

func reset_bee_sprite_direction():
	for bee in bee_sprites:
		bee.scale = bee.init_scale

func turn_red():
	is_aggro = true
	#modulate = MODULATE_AGGRO

func turn_normal():
	if timer_aggro_cooldown.time_left == 0:
		timer_aggro_cooldown.start()


func _on_timer_aggro_cooldown_timeout() -> void:
	is_aggro = false
