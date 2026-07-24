extends Control

@export_file("*.tscn") var main_game_scene: String = "res://World.tscn"
@onready var play_again_button: Button = $RestartButton 

func _ready() -> void:
	if play_again_button and not play_again_button.pressed.is_connected(_on_button_pressed):
		play_again_button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	var err := get_tree().change_scene_to_file(main_game_scene)
	if err != OK:
		print("Failed to load main scene: ", err)
