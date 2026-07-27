extends Node2D

# Assign in Inspector or let the script auto-find your TileMapLayer
@export var tile_map_layer: TileMapLayer 

@export var BULLET: PackedScene
@export var min_reload_time: float = 0.5
@export var max_reload_time: float = 0.8

@export var respawn_time: float = 3.0
@export var warmup_delay: float = 1.0

# Node References (Make sure node names in your Scene tree match these exactly!)
@onready var base_sprite: Sprite2D = $BaseSprite
@onready var gun_sprite: Sprite2D = $GunSprite
@onready var reload_timer: Timer = $RayCast2D/ReloadTimer

var target: Node2D = null
var can_shoot: bool = true
var is_active: bool = false

var placed_tile_positions: Array[Vector2] = []

func _ready() -> void:
	# Auto-find TileMapLayer if not assigned in Inspector
	if not tile_map_layer:
		tile_map_layer = get_tree().root.find_child("*TileMapLayer*", true, false) as TileMapLayer
	
	find_target()
	
	if reload_timer:
		if not reload_timer.timeout.is_connected(_on_reload_timer_timeout):
			reload_timer.timeout.connect(_on_reload_timer_timeout)
	
	# Wait one frame for the physics and tilemap layer to initialize
	await get_tree().process_frame
	
	find_all_placed_tiles()
	
	if not placed_tile_positions.is_empty():
		start_teleport_cycle()
	else:
		push_error("TURRET CRITICAL ERROR: No tiles found! Make sure your TileMapLayer has painted tiles.")

func find_all_placed_tiles() -> void:
	placed_tile_positions.clear()
	
	if not tile_map_layer:
		push_error("TURRET ERROR: Could not find any TileMapLayer in your scene!")
		return
		
	var used_cells: Array[Vector2i] = tile_map_layer.get_used_cells()
	
	for cell_coords in used_cells:
		var local_pos: Vector2 = tile_map_layer.map_to_local(cell_coords)
		var global_pos: Vector2 = tile_map_layer.to_global(local_pos)
		placed_tile_positions.append(global_pos)

func start_teleport_cycle() -> void:
	is_active = false
	can_shoot = false
	
	# Dim BOTH base and gun sprites during warmup
	if base_sprite:
		base_sprite.modulate.a = 0.4
	if gun_sprite:
		gun_sprite.modulate.a = 0.4
		
	# Move to a random tile position
	global_position = placed_tile_positions.pick_random()
	
	# Warmup phase
	await get_tree().create_timer(warmup_delay).timeout
	
	# Restore full opacity to BOTH sprites
	if base_sprite:
		base_sprite.modulate.a = 1.0
	if gun_sprite:
		gun_sprite.modulate.a = 1.0
		
	is_active = true
	can_shoot = true
	
	if reload_timer:
		reload_timer.start(randf_range(min_reload_time, max_reload_time))
		
	# Wait active duration before next teleport
	await get_tree().create_timer(respawn_time).timeout
	start_teleport_cycle()

func _physics_process(_delta: float) -> void:
	if not is_active:
		return

	if not is_instance_valid(target):
		find_target()
		return

	var target_center: Vector2 = get_target_center()
	
	# Aim ONLY the gun sprite directly at the target
	var direction := global_position.direction_to(target_center)
	gun_sprite.rotation = direction.angle()
	
	# Fire through walls whenever reload timer permits
	if can_shoot:
		shoot()

func find_target() -> void:
	target = get_tree().get_first_node_in_group("Player") as Node2D
	if not target:
		target = get_tree().get_first_node_in_group("player") as Node2D

func get_target_center() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
		
	var collision_shape = target.find_child("*CollisionShape2D*", true, false) as CollisionShape2D
	if collision_shape:
		return collision_shape.global_position
		
	return target.global_position

func shoot() -> void:
	if not BULLET or not is_instance_valid(target):
		return
		
	can_shoot = false
	
	var bullet_instance := BULLET.instantiate() as Node2D
	get_parent().add_child(bullet_instance)
	
	bullet_instance.global_position = gun_sprite.global_position
	
	var target_center: Vector2 = get_target_center()
	var angle_to_target: float = global_position.direction_to(target_center).angle()
	bullet_instance.global_rotation = angle_to_target
	
	if reload_timer:
		reload_timer.start(randf_range(min_reload_time, max_reload_time))

func _on_reload_timer_timeout() -> void:
	if is_active:
		can_shoot = true
