extends StaticBody2D

class_name PileOfLeaves

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var rustling_leaf_particles: PackedScene
@onready var audio_rustling: AudioStreamPlayer2D = $AudioRustling

@export var top_layer_of_leaves: Array[Node2D]
@export var bottom_layer_of_leaves: Array[Node2D]

var is_active := true
var hidden_button : GameButton = null
var hidden_stone : Stone = null

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
		for leaf in top_layer_of_leaves:
			leaf.z_index -= 3
		animation_player.play("RESET")
	is_active = info.get("is_active")
	

func fly_away(list_of_blown_objects: Dictionary, _blow_direction: Vector2, _wind_particles: GPUParticles2D):
	if is_active:
		for obj in list_of_blown_objects:
			if list_of_blown_objects[obj]["Object"].name == name:
				if hidden_button != null:
					hidden_button.reveal()
				if hidden_stone != null:
					hidden_stone.reveal()
					Signals.stone_revealed.emit(global_position, _blow_direction)
					
				audio_rustling.play()
				is_active = false
				for leaf in top_layer_of_leaves:
					leaf.z_index += 3
					
				match _blow_direction:
					Vector2.UP:
						animation_player.play("FlyAway_Up")
					Vector2.DOWN:
						animation_player.play("FlyAway_Down")
					Vector2.LEFT:
						animation_player.play("FlyAway_Left")
					Vector2.RIGHT:
						animation_player.play("FlyAway_Right")
	


func _on_creature_detector_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body is Creature or body is PushableObject:
		var leaf_particles : GPUParticles2D = rustling_leaf_particles.instantiate() as GPUParticles2D
		$ParticleSlot.add_child(leaf_particles)
		leaf_particles.emitting = true
		#rustling_leaf_particles.emitting = false
		animation_player.speed_scale = 1
		animation_player.play("Rustle")
		audio_rustling.play()
		#rustling_leaf_particles.emitting = true

func change_animation_speed():
	if not is_active:
		return
	var new_speed_scale = animation_player.speed_scale + RandomNumberGenerator.new().randf_range(-0.2, 0.2)
	if new_speed_scale > 1.2: new_speed_scale = 1.2
	if new_speed_scale < 0.5: new_speed_scale = 0.5
	animation_player.speed_scale = new_speed_scale

func play_idle_animation():
	if not is_active:
		return
	animation_player.play("Idle")
