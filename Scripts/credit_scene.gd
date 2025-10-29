extends Control

@onready var back: Button = $VBoxContainer2/Back
var used_controller = false

func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("Player_Down") or Input.is_action_just_pressed("Player_Up") or Input.is_action_just_pressed("Player_Left") or Input.is_action_just_pressed("Player_Right") )and not used_controller:
		back.grab_focus()
		used_controller = true
		
func _on_exit_pressed() -> void:
	SceneSwitcher.switch_scene("res://Scenes/Menu/MainMenu.tscn")
