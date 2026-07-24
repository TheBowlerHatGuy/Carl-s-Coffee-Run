extends CharacterBody2D

# Assign your TileMapLayer (Godot 4.3+) or TileMap (Godot 4.0-4.2) in Inspector
@export var tile_map: TileMapLayer 

const SPEED: float = 270.0 # How fast the character glides between tiles

var target_position: Vector2
var is_moving: bool = false

func _ready() -> void:
	# Auto-find the TileMapLayer if it's not manually set in the Inspector
	if not tile_map:
		tile_map = get_tree().get_first_node_in_group("map") as TileMapLayer
		
		# Fallback search if groups aren't used:
		if not tile_map:
			tile_map = get_parent().find_child("*TileMapLayer*", true, false) as TileMapLayer
			
	snap_to_grid()

func _physics_process(delta: float) -> void:
	if is_moving:
		# Smoothly glide towards the target tile position
		global_position = global_position.move_toward(target_position, SPEED * delta)
		
		# Once the player arrives, unlock input for the next tile move
		if global_position == target_position:
			is_moving = false
	else:
		get_input()

func get_input() -> void:
	var input_dir := Vector2i.ZERO
	
	# Check for single-tap directional inputs
	if Input.is_action_just_pressed("ui_right"):
		input_dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("ui_left"):
		input_dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_down"):
		input_dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_up"):
		input_dir = Vector2i.UP

	if input_dir != Vector2i.ZERO:
		set_next_tile_target(input_dir)

func set_next_tile_target(dir: Vector2i) -> void:
	if not tile_map:
		push_warning("TileMap node is not assigned in the Inspector!")
		return
		
	# 1. Convert current global position to TileMap local position
	var current_local_pos: Vector2 = tile_map.to_local(global_position)
	
	# 2. Find current grid cell coordinates as integer vector (Vector2i)
	var current_map_cell: Vector2i = tile_map.local_to_map(current_local_pos)
	
	# 3. Calculate target grid cell
	var target_map_cell: Vector2i = current_map_cell + dir
	
	# 4. Convert target grid cell back to global pixel position
	# Explicit Vector2 type fixes the type inference warning
	var target_local_pos: Vector2 = tile_map.map_to_local(target_map_cell)
	target_position = tile_map.to_global(target_local_pos)
	
	is_moving = true

func snap_to_grid() -> void:
	if not tile_map:
		return
		
	# Instantly snap player to the center of their current grid cell
	var current_local_pos: Vector2 = tile_map.to_local(global_position)
	var current_map_cell: Vector2i = tile_map.local_to_map(current_local_pos)
	
	# Explicit Vector2 type fixes the type inference warning
	var target_local_pos: Vector2 = tile_map.map_to_local(current_map_cell)
	
	global_position = tile_map.to_global(target_local_pos)
	target_position = global_position
