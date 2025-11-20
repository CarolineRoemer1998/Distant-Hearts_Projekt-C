extends Node2D

class_name BeeSwarm

@export var bee_sprites : Array[SingleBee] = []
var bee_sprite_scale := 2.0

var is_flying_to_new_position := false
var target_position := Vector2.ZERO
var flying_speed := 100.0

func _ready() -> void:
	Signals.flower_grows.connect(fly_to_flower)

func _process(delta: float) -> void:
	if is_flying_to_new_position:
		position = position.move_toward(target_position, flying_speed*delta)
	
	if abs(position - target_position)[0] < 0.1 and abs(position - target_position)[1] < 0.1:
		position = target_position
		reset_bee_sprite_direction()

func fly_to_flower(flower: Flower):
	target_position = flower.global_position
	_change_direction_of_bee_sprites()
	is_flying_to_new_position = true

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

func _on_bee_area_body_entered(player: Node2D) -> void:
	pass
	#if player is Player and player.currently_possessed_creature != null:
		#player.direction = -player.direction
		#player.set_is_moving(true)
		#player.step_timer.start(Constants.TIMER_STEP*2)
		#StateSaver.remove_last_state()
		#StateSaver.remove_last_state()
