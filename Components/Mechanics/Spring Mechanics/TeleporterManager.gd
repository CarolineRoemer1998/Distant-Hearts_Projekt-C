extends Node2D

class_name TeleporterManager

@onready var flower_1: Teleporter = $Flower1
@onready var flower_2: Teleporter = $Flower2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_active := true

var on_flower_1 : Node2D = null
var on_flower_2 : Node2D = null

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_TELEPORTER_MANAGER)
	Signals.teleporter_activated.connect(_handle_teleporter_activated)

func _handle_teleporter_activated(_teleporter: Teleporter):
	if flower_1.is_activated and flower_2.is_activated:
		if on_flower_1 != null and not on_flower_1.just_teleported and not on_flower_1.is_merging:
			print(on_flower_1.name)
			teleport_to(flower_2)
		if on_flower_2 != null and not on_flower_2.just_teleported and not on_flower_2.is_merging:
			print(on_flower_2.name)
			teleport_to(flower_1)

func _on_flower_1_entered(body: Node2D) -> void:
	if is_active and body is Player and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		body.currently_possessed_creature.standing_on_teleporter = flower_1
		body.set_is_standing_on_teleporter(true)
		on_flower_1 = body.currently_possessed_creature
		if flower_1.is_activated and flower_2.is_activated and not body.currently_possessed_creature.just_teleported and not body.currently_possessed_creature.is_merging:
			teleport_to(flower_2)


func _on_flower_2_entered(body: Node2D) -> void:
	if body is Player and is_active and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		body.currently_possessed_creature.standing_on_teleporter = flower_2
		body.set_is_standing_on_teleporter(true)
		on_flower_2 = body.currently_possessed_creature
		if flower_1.is_activated and flower_2.is_activated and not body.currently_possessed_creature.just_teleported and not body.currently_possessed_creature.is_merging:
			teleport_to(flower_1)


func teleport_from(entered_teleporter: Teleporter):
	if entered_teleporter == flower_1 and entered_teleporter != flower_2:
		teleport_to(flower_2)
	elif entered_teleporter == flower_2 and entered_teleporter != flower_1:
		teleport_to(flower_1)

func teleport_to(target_teleporter: Teleporter):
	Signals.teleporter_entered.emit(target_teleporter)
	flower_1.start_teleport()
	flower_2.start_teleport()
	audio_stream_player_2d.play()

func _on_flower_1_exited(body: Node2D) -> void:
	if body is Player:
		body.set_is_standing_on_teleporter(false)
		if body.currently_possessed_creature:
			on_flower_1 = null

func _on_flower_2_exited(body: Node2D) -> void:
	if body is Player:
		body.set_is_standing_on_teleporter(false)
		if body.currently_possessed_creature:
			on_flower_2 = null
