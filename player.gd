extends CharacterBody2D
# Health bar sync
@export var health_bar: HBoxContainer
# Assign TileMapLayer
@export var tile_map: TileMapLayer 

# HP System
@export var max_health: int = 5
var current_health: int = 5

const SPEED: float = 300.0 # How fast the character glides between tiles

var target_position: Vector2
var is_moving: bool = false

# Hold delay settings
@export var hold_delay: float = 0.5 
var hold_time: float = 0.0
var has_tapped: bool = false
var last_input_dir: Vector2i = Vector2i.ZERO

func _ready() -> void:
	current_health = max_health # Reset health on spawn
	
	# Automatically add player to "Player" group so the turret can detect it
	if not is_in_group("Player"):
		add_to_group("Player")

	if not tile_map:
		tile_map = get_tree().get_first_node_in_group("map") as TileMapLayer
		if not tile_map:
			tile_map = get_parent().find_child("*TileMapLayer*", true, false) as TileMapLayer
			
	snap_to_grid()

func _physics_process(delta: float) -> void:
	if is_moving:
		global_position = global_position.move_toward(target_position, SPEED * delta)
		if global_position == target_position:
			is_moving = false
			
	get_input(delta)

# --- DAMAGE AND DEATH LOGIC ---
func take_damage(amount: int = 1) -> void:
	current_health -= amount
	print("OUCH! Player hit! Remaining health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("PLAYER DIED!")
	
	# A: Go to Game Over screen
	var error = get_tree().change_scene_to_file("res://game_over_screen.tscn")
	
	# B: Fallback if the Game Over scene file isn't found
	if error != OK:
		push_warning("Could not find res://game_over_screen.tscn! Reloading level instead.")
		get_tree().reload_current_scene()

func get_input(delta: float) -> void:
	var input_dir := Vector2i.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_dir = Vector2i.RIGHT
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2i.LEFT
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2i.DOWN
	elif Input.is_action_pressed("ui_up"):
		input_dir = Vector2i.UP

	if input_dir != Vector2i.ZERO:
		if input_dir != last_input_dir:
			hold_time = 0.1
			has_tapped = false
			last_input_dir = input_dir

		if not has_tapped and not is_moving:
			has_tapped = true
			set_next_tile_target(input_dir)
			return

		hold_time += delta

		if hold_time >= hold_delay and not is_moving:
			set_next_tile_target(input_dir)
			
	else:
		hold_time = 0.0
		has_tapped = false
		last_input_dir = algorithm_reset()

func algorithm_reset() -> Vector2i:
	return Vector2i.ZERO

func set_next_tile_target(dir: Vector2i) -> void:
	if not tile_map:
		push_warning("TileMap node is not assigned in the Inspector!")
		return
		
	var current_local_pos: Vector2 = tile_map.to_local(global_position)
	var current_map_cell: Vector2i = tile_map.local_to_map(current_local_pos)
	var target_map_cell: Vector2i = current_map_cell + dir
	
	if is_tile_blocked(target_map_cell):
		return
	
	var target_local_pos: Vector2 = tile_map.map_to_local(target_map_cell)
	target_position = tile_map.to_global(target_local_pos)
	is_moving = true

func is_tile_blocked(cell: Vector2i) -> bool:
	var tile_data: TileData = tile_map.get_cell_tile_data(cell)
	if tile_data and tile_data.get_collision_polygons_count(0) > 0:
		return true
	return false

func snap_to_grid() -> void:
	if not tile_map:
		return
		
	var current_local_pos: Vector2 = tile_map.to_local(global_position)
	var current_map_cell: Vector2i = tile_map.local_to_map(current_local_pos)
	var target_local_pos: Vector2 = tile_map.map_to_local(current_map_cell)
	
	global_position = tile_map.to_global(target_local_pos)
	target_position = global_position
