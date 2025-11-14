extends Node2D

@onready var flower_1: TeleporterFlower = $Flower1
@onready var flower_2: TeleporterFlower = $Flower2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_active := true

func _on_flower_1_entered(body: Node2D) -> void:
	if flower_1.is_activated and flower_2.is_activated:
		if body is Player and is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
			teleport(flower_2)


func _on_flower_2_entered(body: Node2D) -> void:
	if flower_1.is_activated and flower_2.is_activated:
		if body is Player and is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
			teleport(flower_1)

func teleport(target_teleporter: TeleporterFlower):
	Signals.teleporter_entered.emit(target_teleporter.global_position)
	is_active = false
	flower_1.start_teleport()
	flower_2.start_teleport()
	audio_stream_player_2d.play()

func _on_flower_1_exited(body: Node2D) -> void:
	if body is Player and not is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		is_active = true

func _on_flower_2_exited(body: Node2D) -> void:
	if body is Player and not is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		is_active = true
