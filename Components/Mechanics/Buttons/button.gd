extends Node2D

class_name GameButton

signal activated
signal deactivated

enum BUTTON_TYPE {TOGGLE, STICKY, PRESSURE}

@export var type : BUTTON_TYPE = BUTTON_TYPE.STICKY
@export var start_active: bool = false

@onready var button_green: Sprite2D = $Button_GREEN
@onready var button_red: Sprite2D = $Button_RED
@onready var area: Area2D = $Area2D
@onready var audio_push_button: AudioStreamPlayer2D = $AudioPushButton
@onready var audio_leave: AudioStreamPlayer2D = $AudioLeave

var sprite_sticky_off := preload(Constants.SPRITE_PATH_STICKY_BUTTON_UNPRESSED)
var sprite_sticky_on := preload(Constants.SPRITE_PATH_STICKY_BUTTON_PRESSED)
var sprite_pressure_off := preload(Constants.SPRITE_PATH_PRESSURE_PLATE_UNPRESSED)
var sprite_pressure_on := preload(Constants.SPRITE_PATH_PRESSURE_PLATE_PRESSED)
var sprite_toggle_on := preload(Constants.SPRITE_PATH_TOGGLE_BUTTON_PRESSED)
var sprite_toggle_off := preload(Constants.SPRITE_PATH_TOGGLE_BUTTON_UNPRESSED)

var active: bool = false
var sticky_audio_played : bool = false
var door_is_permanently_opened : bool = false

func _ready() -> void:
	add_to_group(str(Constants.GROUP_NAME_BUTTONS))
	
	_set_button_sprites()
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)
	set_active(start_active)

func get_info() -> Dictionary:
	return {
		"active": active,
		"sticky_audio_played": sticky_audio_played,
		"door_is_permanently_opened": door_is_permanently_opened
	}

func set_info(info : Dictionary):
	active = info.get("active")
	sticky_audio_played = info.get("sticky_audio_played")
	door_is_permanently_opened = info.get("door_is_permanently_opened")
	
	set_active(active)

func _on_body_entered(_body: Node) -> void:
	if door_is_permanently_opened or not (_body.is_in_group(Constants.GROUP_NAME_CREATURE) or _body.is_in_group(Constants.GROUP_NAME_STONES)):
		return
	
	match type:
		BUTTON_TYPE.TOGGLE: 
			press_toggle_button()
		BUTTON_TYPE.STICKY: 
			press_sticky_button()
		BUTTON_TYPE.PRESSURE: 
			press_pressure_button()
	
func _on_body_exited(_body: Node) -> void:
	if Helper.check_if_collides(global_position, Constants.LAYER_BIT_CREATURE, get_world_2d()):
		return
	if door_is_permanently_opened:
		return
	
	# Optional: only deactivate if no bodies are left
	if type == BUTTON_TYPE.TOGGLE or type == BUTTON_TYPE.STICKY:
		return
		
	await get_tree().process_frame # small delay to update collision state
	if area.get_overlapping_bodies().is_empty():
		set_active(false)
		audio_leave.play()

func _update_button_color() -> void:
	button_green.visible = active
	button_red.visible = not active

func is_pressed() -> bool:
	return active

func set_active(value : bool):
	active = value
	if active:
		emit_signal("activated")
	else: 
		emit_signal("deactivated")
	_update_button_color()

func press_toggle_button():
	set_active(!active)
	if active:
		audio_push_button.play()
	else:
		audio_leave.play()

func press_sticky_button():
	set_active(true)
	if not sticky_audio_played:
		audio_push_button.play()
		sticky_audio_played = true

func press_pressure_button():
	if not active:
		set_active(true)
		audio_push_button.play()

func _set_button_sprites():
	match type:
		BUTTON_TYPE.TOGGLE:
			button_green.texture = sprite_toggle_on
			button_red.texture = sprite_toggle_off
		BUTTON_TYPE.STICKY:
			button_green.texture = sprite_sticky_on
			button_red.texture = sprite_sticky_off
		BUTTON_TYPE.PRESSURE:
			button_green.texture = sprite_pressure_on
			button_red.texture = sprite_pressure_off

func set_door_is_permanently_opened():
	door_is_permanently_opened = true
