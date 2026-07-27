extends HBoxContainer

@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

func update_health(current_health: int) -> void:
	var boxes: Array[Node] = get_children()
	
	for i in range(boxes.size()):
		var box = boxes[i]
		if box is TextureRect:
			if i < current_health:
				box.texture = full_heart_texture
			else:
				box.texture = empty_heart_texture
