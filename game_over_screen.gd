extends Control

@export_file("*.tscn") var main_game_scene: String = "res://game.tscn"

@onready var restart_button: Button = $Button 

func _ready() -> void:
	# Make button work even if game state is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if restart_button:
		# Unbind first to avoid duplicate connection errors, then connect
		if restart_button.pressed.is_connected(_on_restart_button_pressed):
			restart_button.pressed.disconnect(_on_restart_button_pressed)
		restart_button.pressed.connect(_on_restart_button_pressed)
	else:
		push_error("Could not find Button node! Check your scene tree node name.")

func _on_restart_button_pressed() -> void:
	print("Restart button clicked! Reloading main game...")
	
	# Unpause in case tree was paused
	get_tree().paused = false
	
	var err: Error = get_tree().change_scene_to_file(main_game_scene)
	if err != OK:
		print("Failed to change scene! Error code: ", err)
		print("Check if main_game_scene path is correct: ", main_game_scene)
