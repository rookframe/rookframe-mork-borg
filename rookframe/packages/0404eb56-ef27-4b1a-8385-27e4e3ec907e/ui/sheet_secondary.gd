extends MarginContainer

func _draw() -> void:
	if get_viewport_rect().size.x > 900:
		draw_line(Vector2(0, 0), Vector2(0, size.y), Color(0.243137, 0.262745, 0.27451, 1))
