extends Node2D

@export var move_speed: float = 30.0
# Exactly 23 tiles * 18 pixels = 414 pixels across
@export var map_width: float = 414.0

@export var active_time: float = 3.0
@export var off_time: float = 2.0
@export var telegraph_time: float = 0.8

@onready var left_base: Sprite2D = $LeftBase
@onready var right_base: Sprite2D = $RightBase
@onready var beam_line: Line2D = $BeamLine
@onready var hit_area: Area2D = $HitArea
@onready var collision_shape: CollisionShape2D = $HitArea/CollisionShape2D

@onready var ray_up: RayCast2D = $RayCastUp
@onready var ray_down: RayCast2D = $RayCastDown

enum State { OFF, TELEGRAPH, ACTIVE }
var current_state: State = State.OFF

var moving_down: bool = true

func _ready() -> void:
	# Position bases at opposite edges of your 23-tile wide grid
	left_base.position = Vector2(0, 0)
	right_base.position = Vector2(map_width, 0)
	
	# Connect laser line across the 414px map
	beam_line.clear_points()
	beam_line.add_point(Vector2(0, 0))
	beam_line.add_point(Vector2(map_width, 0))
	
	# Match CollisionShape2D segment length dynamically across 414px
	if collision_shape.shape is SegmentShape2D:
		var segment = collision_shape.shape as SegmentShape2D
		segment.a = Vector2(0, 0)
		segment.b = Vector2(map_width, 0)
	
	# Center RayCasts along half a tile (9px) so they clear wall edges
	ray_up.position = Vector2(9, 0)
	ray_down.position = Vector2(9, 0)
	
	# 6px check distance for 18px tall tile boundaries (ceiling & floor)
	ray_up.target_position = Vector2(0, -6)
	ray_down.target_position = Vector2(0, 6)
	
	if not hit_area.body_entered.is_connected(_on_hit_area_body_entered):
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		
	enter_state(State.OFF)

func _physics_process(delta: float) -> void:
	if moving_down:
		if ray_down.is_colliding():
			moving_down = false
		else:
			position.y += move_speed * delta
	else:
		if ray_up.is_colliding():
			moving_down = true
		else:
			position.y -= move_speed * delta

func enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.OFF:
			beam_line.visible = false
			collision_shape.set_deferred("disabled", true)
			await get_tree().create_timer(off_time).timeout
			enter_state(State.TELEGRAPH)
			
		State.TELEGRAPH:
			beam_line.visible = true
			beam_line.width = 1.5
			beam_line.default_color.a = 0.3
			collision_shape.set_deferred("disabled", true)
			await get_tree().create_timer(telegraph_time).timeout
			enter_state(State.ACTIVE)
			
		State.ACTIVE:
			beam_line.visible = true
			beam_line.width = 4.0
			beam_line.default_color.a = 1.0
			collision_shape.set_deferred("disabled", false)
			await get_tree().create_timer(active_time).timeout
			enter_state(State.OFF)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if current_state == State.ACTIVE and (body.is_in_group("Player") or body.is_in_group("player")):
		if body.has_method("take_damage"):
			body.take_damage()
