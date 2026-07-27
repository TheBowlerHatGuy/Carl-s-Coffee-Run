extends Control

@onready var restart_button: Button = $RestartButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	# Hide ourselves on game start
	hide()
	
	# Connect button signals
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

# Call this function when the player dies
func trigger_death_screen() -> void:
	show()
	# Optional: Pause game background processes while menu is open
	# get_tree().paused = true 

func _on_restart_pressed() -> void:
	# Unpause if you paused the tree
	get_tree().paused = false 
	# Reload current level scene
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	# Quits game executable (or returns to main menu)
	get_tree().quit()
