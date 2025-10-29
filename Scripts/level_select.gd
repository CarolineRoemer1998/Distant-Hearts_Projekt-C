extends Control

@onready var back: Button = $VBoxContainer/Back

var used_controller = false

func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("Player_Down") or Input.is_action_just_pressed("Player_Up") or Input.is_action_just_pressed("Player_Left") or Input.is_action_just_pressed("Player_Right") )and not used_controller:
		back.grab_focus()
		used_controller = true


func _on_exit_pressed() -> void:
	SceneSwitcher.switch_scene("res://Scenes/Menu/MainMenu.tscn")


func _on_level_1_pressed() -> void:
	SceneSwitcher.switch_to_level(1)


func _on_level_2_pressed() -> void:
	SceneSwitcher.switch_to_level(2)


func _on_level_3_pressed() -> void:
	SceneSwitcher.switch_to_level(3)


func _on_level_4_pressed() -> void:
	SceneSwitcher.switch_to_level(4)


func _on_level_5_pressed() -> void:
	SceneSwitcher.switch_to_level(5)


func _on_level_6_pressed() -> void:
	SceneSwitcher.switch_to_level(6)


func _on_level_7_pressed() -> void:
	SceneSwitcher.switch_to_level(7)


func _on_level_8_pressed() -> void:
	SceneSwitcher.switch_to_level(8)


func _on_level_9_pressed() -> void:
	SceneSwitcher.switch_to_level(9)


func _on_level_10_pressed() -> void:
	SceneSwitcher.switch_to_level(10)
