extends Control

@onready var back: Button = $VBoxContainer/Back
@onready var fullscreen: CheckButton = $VBoxContainer/Fullscreen


var used_controller = false

func _ready() -> void:
	if OS.has_feature("web"):
			fullscreen.visible = false		
	fullscreen.set_pressed_no_signal(Globals.fullscreen)	
	
func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("Player_Down") or Input.is_action_just_pressed("Player_Up") or Input.is_action_just_pressed("Player_Left") or Input.is_action_just_pressed("Player_Right") )and not used_controller:
		back.grab_focus()
		used_controller = true

func _on_back_pressed() -> void:
	SceneSwitcher.return_from_scene()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	print(toggled_on)
	if !toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Globals.fullscreen = false
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Globals.fullscreen = true
