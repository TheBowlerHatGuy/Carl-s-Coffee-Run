extends Node2D

@export var BULLET: PackedScene
@export var min_reload_time: float = 0.5
@export var max_reload_time: float = 0.8

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var reload_timer: Timer = $RayCast2D/ReloadTimer

var target: Node2D = null
var can_shoot: bool = true

func _ready() -> void:
	find_target()
	
	if reload_timer:
		if not reload_timer.timeout.is_connected(_on_reload_timer_timeout):
			reload_timer.timeout.connect(_on_reload_timer_timeout)
		reload_timer.start(randf_range(min_reload_time, max_reload_time))

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		find_target()
		return

	# Calculate exact center position of target character
	var target_center: Vector2 = get_target_center()
	
	# Point GunSprite toward target center
	var direction := global_position.direction_to(target_center)
	gun_sprite.rotation = direction.angle()
	
	# Point RayCast2D
	ray_cast.target_position = ray_cast.to_local(target_center)
	
	# Check line of sight and shoot
	if ray_cast.is_colliding() and ray_cast.get_collider() == target:
		if can_shoot:
			shoot()

func find_target() -> void:
	target = get_tree().get_first_node_in_group("Player") as Node2D

func get_target_center() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
		
	# Finds the player's CollisionShape2D to aim directly at center mass
	var collision_shape = target.find_child("*CollisionShape2D*", true, false) as CollisionShape2D
	if collision_shape:
		return collision_shape.global_position
		
	return target.global_position

func shoot() -> void:
	if not BULLET or not is_instance_valid(target):
		push_warning("BULLET scene is not assigned in the Inspector for Turret!")
		return
		
	can_shoot = false
	
	# Spawn bullet
	var bullet_instance := BULLET.instantiate() as Node2D
	get_parent().add_child(bullet_instance)
	
	# Spawn at turret center position
	bullet_instance.global_position = gun_sprite.global_position
	
	# Point bullet directly at the target center angle
	var target_center: Vector2 = get_target_center()
	var angle_to_target: float = global_position.direction_to(target_center).angle()
	bullet_instance.global_rotation = angle_to_target
	
	# Start reload delay
	reload_timer.start(randf_range(min_reload_time, max_reload_time))

func _on_reload_timer_timeout() -> void:
	can_shoot = true
