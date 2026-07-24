extends Area2D

@export var speed: float = 500
var velocity := Vector2.ZERO

func launch(direction: Vector2):
	velocity = direction * speed
	# Ensure the bullet is added to the main world, not the turret
	get_tree().current_scene.add_child(self)
	position = global_position

func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	# Get current viewport dimensions
	var viewport_size = get_viewport_rect().size
	
	# Check if bullet is outside the screen bounds
	if position.x < 0 or position.x > viewport_size.x or \
	   position.y < 0 or position.y > viewport_size.y:
		queue_free()
	
