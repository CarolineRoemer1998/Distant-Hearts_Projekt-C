extends Node2D

class_name TeleporterManager

@onready var flower_1: Teleporter = $Flower1
@onready var flower_2: Teleporter = $Flower2
#@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var undo_timer: Timer = $UndoTimer

var is_active := true

var on_flower_1 : Creature = null
var on_flower_2 : Creature = null

#var undo_timer_running := false

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_TELEPORTER_MANAGERS)
	Signals.teleporter_activated.connect(_handle_teleporter_activated)
	Signals.teleporter_deactivated.connect(_handle_teleporter_deactivated)


func get_info():
	return {
		"on_flower_1": on_flower_1,
		"on_flower_2": on_flower_2,
		"is_active": is_active
	}

func set_info(info : Dictionary):
	on_flower_1 = info.get("on_flower_1")
	on_flower_2 = info.get("on_flower_2")
	is_active = is_active

func _handle_teleporter_activated(_teleporter: Teleporter):
	if not (flower_1.is_activated and flower_2.is_activated):
		is_active = false
		Globals.is_teleporting = false
		return
	
	is_active = true
	
	if on_flower_1 != null and not on_flower_1.is_merging:#and not on_flower_1.just_teleported and on_flower_1.target_position != on_flower_1.global_position:
		teleport_to(self, on_flower_1)

	elif on_flower_2 != null and not on_flower_2.is_merging:# and not on_flower_2.just_teleported and on_flower_2.target_position != on_flower_2.global_position:
		teleport_to(self, on_flower_2)
	
	else:
		Globals.is_teleporting = false

func _handle_teleporter_deactivated(_teleporter: Teleporter):
	if not (flower_1.is_activated and flower_2.is_activated):
		is_active = false

func _on_flower_1_entered(body: Node2D) -> void:
	if body is Player and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		body.set_is_standing_on_teleporter(true)
		on_flower_1 = body.currently_possessed_creature
		
		if not is_active or on_flower_1.just_teleported:
			return
		
		var creature = body.currently_possessed_creature
		if flower_1.is_activated and flower_2.is_activated and not creature.just_teleported and not creature.is_merging:
			teleport_to(self, creature)
			
	if body is Creature and not body.is_teleporting:
		#body.set_is_standing_on_teleporter(true)
		on_flower_1 = body
		
		if not is_active or on_flower_1.just_teleported:
			return
		
		var creature = body
		if flower_1.is_activated and flower_2.is_activated and not creature.just_teleported and not creature.is_merging:
			teleport_to(self, creature)


func _on_flower_2_entered(body: Node2D) -> void:
	if body is Player and body.currently_possessed_creature and not body.currently_possessed_creature.is_teleporting:
		body.set_is_standing_on_teleporter(true)
		on_flower_2 = body.currently_possessed_creature
		
		if not is_active or on_flower_2.just_teleported:
			return
			
		var creature = body.currently_possessed_creature
		if flower_1.is_activated and flower_2.is_activated and not creature.just_teleported and not creature.is_merging:
			teleport_to(self, creature)
	elif body is Creature and not body.is_teleporting:
		#body.set_is_standing_on_teleporter(true)
		on_flower_2 = body
		
		if not is_active or on_flower_2.just_teleported:
			return
			
		var creature = body
		if flower_1.is_activated and flower_2.is_activated and not creature.just_teleported and not creature.is_merging:
			teleport_to(self, creature)

#func teleport_from(entered_teleporter: Teleporter):
	#if entered_teleporter == flower_1:
		#teleport_to(flower_2)
	#elif entered_teleporter == flower_2:
		#teleport_to(flower_1)

func teleport_to(teleporter_manager: TeleporterManager, body: Node2D):
	if not Globals.is_undo_timer_buffer_running:
		Signals.teleporter_entered.emit(teleporter_manager, body)
		flower_1.start_teleport()
		flower_2.start_teleport()


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
