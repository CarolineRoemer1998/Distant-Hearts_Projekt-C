extends Control

@onready var back: Button = $Back

var used_controller = false

func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("Player_Down") or Input.is_action_just_pressed("Player_Up") or Input.is_action_just_pressed("Player_Left") or Input.is_action_just_pressed("Player_Right") )and not used_controller:
		back.grab_focus()
		used_controller = true


func _on_exit_pressed() -> void:
	SceneSwitcher.switch_scene(Constants.PATH_MAIN_MENU)

# ----------------- INTRO -----------------

func _on_level_intro_1_pressed() -> void:
	SceneSwitcher.switch_to_level(1)

func _on_level_intro_2_pressed() -> void:
	SceneSwitcher.switch_to_level(2)

func _on_level_intro_3_pressed() -> void:
	SceneSwitcher.switch_to_level(3)

func _on_level_intro_4_pressed() -> void:
	SceneSwitcher.switch_to_level(4)

func _on_level_intro_5_pressed() -> void:
	SceneSwitcher.switch_to_level(5)

# ----------------- SPRING -----------------

func _on_level_spring_1_pressed() -> void:
	SceneSwitcher.switch_to_level(6)

func _on_level_spring_2_pressed() -> void:
	SceneSwitcher.switch_to_level(7)

func _on_level_spring_3_pressed() -> void:
	SceneSwitcher.switch_to_level(8)

func _on_level_spring_4_pressed() -> void:
	SceneSwitcher.switch_to_level(9)

func _on_level_spring_5_pressed() -> void:
	SceneSwitcher.switch_to_level(10)

func _on_level_spring_6_pressed() -> void:
	SceneSwitcher.switch_to_level(11)

# ----------------- SUMMER -----------------

func _on_level_summer_1_pressed() -> void:
	SceneSwitcher.switch_to_level(12)

func _on_level_summer_2_pressed() -> void:
	SceneSwitcher.switch_to_level(13)

func _on_level_summer_3_pressed() -> void:
	SceneSwitcher.switch_to_level(14)

func _on_level_summer_4_pressed() -> void:
	SceneSwitcher.switch_to_level(15)

func _on_level_summer_5_pressed() -> void:
	SceneSwitcher.switch_to_level(16)

func _on_level_summer_6_pressed() -> void:
	SceneSwitcher.switch_to_level(17)

# ----------------- FALL -----------------

func _on_level_fall_1_pressed() -> void:
	SceneSwitcher.switch_to_level(18)

func _on_level_fall_2_pressed() -> void:
	SceneSwitcher.switch_to_level(19)

func _on_level_fall_3_pressed() -> void:
	SceneSwitcher.switch_to_level(20)

func _on_level_fall_4_pressed() -> void:
	SceneSwitcher.switch_to_level(21)

func _on_level_fall_5_pressed() -> void:
	SceneSwitcher.switch_to_level(22)

func _on_level_fall_6_pressed() -> void:
	SceneSwitcher.switch_to_level(23)

# ----------------- WINTER -----------------

func _on_level_winter_1_pressed() -> void:
	SceneSwitcher.switch_to_level(24)

func _on_level_winter_2_pressed() -> void:
	SceneSwitcher.switch_to_level(25)

func _on_level_winter_3_pressed() -> void:
	SceneSwitcher.switch_to_level(26)

func _on_level_winter_4_pressed() -> void:
	SceneSwitcher.switch_to_level(27)

func _on_level_winter_5_pressed() -> void:
	SceneSwitcher.switch_to_level(28)
