extends Node2D

@onready var flower_1: TeleporterFlower = $Flower1
@onready var flower_2: TeleporterFlower = $Flower2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_active := true

func _on_flower_1_entered(body: Node2D) -> void:
	print("Starting")
	if body is Player and is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		Signals.teleporter_entered.emit(flower_2.global_position, flower_1)
		is_active = false
		flower_1.start_teleport()
		flower_2.start_teleport()
		audio_stream_player_2d.play()


func _on_flower_2_entered(body: Node2D) -> void:
	if body is Player and is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		Signals.teleporter_entered.emit(flower_1.global_position, flower_2)
		is_active = false
		flower_1.start_teleport()
		flower_2.start_teleport()
		audio_stream_player_2d.play()


func _on_flower_1_exited(body: Node2D) -> void:
	if body is Player and not is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		print("Exited 1")
		is_active = true

func _on_flower_2_exited(body: Node2D) -> void:
	if body is Player and not is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		print("Exited 2")
		is_active = true
