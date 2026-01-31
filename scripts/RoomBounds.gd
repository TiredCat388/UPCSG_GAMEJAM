extends Area2D

@export var camera_padding: float = 0.0  # optional margin

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return

	var cam: Camera2D = body.get_node("Camera2D")
	if cam == null:
		return
		
	var shape_node: CollisionShape2D = $CollisionShape2D
	var rect_shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return

	var extents: Vector2 = rect_shape.extents
	var xform: Transform2D = shape_node.global_transform

	var top_left: Vector2 = xform * Vector2(-extents.x, -extents.y)
	var bottom_right: Vector2 = xform * Vector2(extents.x, extents.y)

	cam.limit_left   = int(top_left.x - 30.0)
	cam.limit_top    = int(top_left.y - 30.0)
	cam.limit_right  = int(bottom_right.x + 30.0)
	cam.limit_bottom = int(bottom_right.y + 30.0)
