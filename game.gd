extends Node2D

@export_file("*.tscn") var victory_scene_path: String = "res://victory_screen.tscn"

@onready var survival_timer: Timer = $SurvivalTimer

func _ready() -> void:
	get_tree().paused = false
	
	if survival_timer:
		survival_timer.wait_time = 90.0 
		survival_timer.timeout.connect(_on_survival_timer_timeout)
		survival_timer.start()
	else:
		push_error("Game.gd Error: Could not find 'SurvivalTimer' node!")

func _on_survival_timer_timeout() -> void:
	print("VICTORY! Player survived!")
	var err := get_tree().change_scene_to_file(victory_scene_path)
	if err != OK:
		push_error("Could not load victory scene at: ", victory_scene_path)
