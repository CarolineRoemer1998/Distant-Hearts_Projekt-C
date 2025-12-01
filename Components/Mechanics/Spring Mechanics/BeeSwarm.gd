extends StaticBody2D

class_name BeeSwarm

@onready var timer_aggro_cooldown: Timer = $TimerAggroCooldown
@onready var visuals: Node2D = $Visuals

@export var bee_sprites : Array[SingleBee] = []
@export var animation_players : Array[AnimationPlayer] = []

@onready var area_check_for_creatures: Area2D = $AreaCheckForCreatures

const MODULATE_AGGRO := Color(1.096, 0.278, 0.278)
const MODULATE_NORMAL := Color(1.096, 1.096, 1.096)

var init_position := Vector2.ZERO
var target_position := Vector2.ZERO
var is_aggro := false

var bee_sprite_scale := 2.0
var flying_speed := 300.0
var anim_speed_normal := 1.0
var anim_speed_aggro := 8.0

var is_flying_to_new_position := false
var reached_flower_last_step := false
var position_before_flower := Vector2.ZERO
var target_flower : FlowerSeed = null

@onready var audio_buzzing: AudioStreamPlayer2D = $AudioBuzzing
var buzz_volume_init := 0.0
var buzz_volume_aggro := 5.0
var buzz_pitch_init := 1.0
var buzz_pitch_aggro := 1.25

func _ready() -> void:
	Signals.flower_grows.connect(fly_to_flower)
	Signals.bees_near_creature.connect(turn_red)
	Signals.bees_not_near_creature.connect(turn_normal)
	
	add_to_group(Constants.GROUP_NAME_BEES)
	init_position = global_position
	target_position = init_position
	position_before_flower = init_position

func _process(delta: float) -> void:
	check_creature_is_close()
	if is_aggro:
		modulate = lerp(modulate, MODULATE_AGGRO, delta*4.0)
		audio_buzzing.pitch_scale = lerp(audio_buzzing.pitch_scale, buzz_pitch_aggro, delta*25.0)
		audio_buzzing.volume_db = lerp(audio_buzzing.volume_db, buzz_volume_aggro, delta*25.0)
		for anim_player in animation_players:
			anim_player.speed_scale = lerp(anim_player.speed_scale, anim_speed_aggro, delta*10.0)
	else: 
		modulate = lerp(modulate, MODULATE_NORMAL, delta*2.0)
		audio_buzzing.pitch_scale = lerp(audio_buzzing.pitch_scale, buzz_pitch_init, delta*2.0)
		audio_buzzing.volume_db = lerp(audio_buzzing.volume_db, buzz_volume_init, delta*2.0)
		for anim_player in animation_players:
			anim_player.speed_scale = lerp(anim_player.speed_scale, anim_speed_normal, delta*8.0)
	
	
	if is_flying_to_new_position:
		visuals.position = lerp(visuals.position, Vector2(0,-16), delta*5.0)
		audio_buzzing.pitch_scale = lerp(audio_buzzing.pitch_scale, buzz_pitch_aggro, delta*25.0)
		audio_buzzing.volume_db = lerp(audio_buzzing.volume_db, buzz_volume_aggro, delta*25.0)
		position = position.move_toward(target_position, flying_speed*delta)
		
		if abs(position - target_position)[0] < 0.01 and abs(position - target_position)[1] < 0.01:
			position = target_position
			is_flying_to_new_position = false
			reached_flower_last_step = true
			reset_bee_sprite_direction()
			Signals.bees_stop_flying.emit()
	elif audio_buzzing.pitch_scale != buzz_pitch_init or audio_buzzing.volume_db != buzz_volume_init:
		audio_buzzing.pitch_scale = lerp(audio_buzzing.pitch_scale, buzz_pitch_init, delta*5.0)
		audio_buzzing.volume_db = lerp(audio_buzzing.volume_db, buzz_volume_init, delta*5.0)
# -----------------------------------------------------------
# State (e.g. for Undo)
# -----------------------------------------------------------
## Returns a Dictionary snapshot of the FlowerSeed state
## used for Undo/Redo (position + target position).
func get_info() -> Dictionary:
	var save_dict = {}
	save_dict["global_position"] = target_position
	save_dict["is_flying_to_new_position"] = is_flying_to_new_position
	save_dict["is_aggro"] = is_aggro
	save_dict["target_flower"] = target_flower
	
	return save_dict

## Restores the FlowerSeed state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_flying_to_new_position = info.get("is_flying_to_new_position")
	is_aggro = info.get("is_aggro")

func fly_to_flower(flower: FlowerSeed):
	target_flower = flower
	target_position = flower.target_position
	_change_direction_of_bee_sprites()
	position_before_flower = global_position
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

func turn_normal():
	if timer_aggro_cooldown.time_left == 0:
		timer_aggro_cooldown.start()

func _on_timer_aggro_cooldown_timeout() -> void:
	is_aggro = false

func check_creature_is_close() -> void:
	for creature in area_check_for_creatures.get_overlapping_bodies():
		if creature is Creature:
			if not is_aggro and creature.is_possessed:
				creature.tremble()
				Signals.bees_near_creature.emit(creature)
			turn_red()
			return
	turn_normal()
