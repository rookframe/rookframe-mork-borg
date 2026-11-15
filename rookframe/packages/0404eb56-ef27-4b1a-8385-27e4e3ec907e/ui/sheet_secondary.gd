extends MarginContainer
const TOKENS := &"RookframeTokens"

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	if get_viewport_rect().size.x > 900:
		draw_line(Vector2(0, 0), Vector2(0, size.y), get_theme_color(&"divider", TOKENS))
