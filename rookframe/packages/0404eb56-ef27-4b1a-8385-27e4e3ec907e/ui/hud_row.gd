extends HBoxContainer

const RULE = preload("res://rookframe/ui/theme/silkbound_row.tres")
var separator := false
var column_divider := false
func _ready() -> void:
	resized.connect(_redraw)
func _redraw() -> void:
	queue_redraw()
func _draw() -> void:
	if separator:
		draw_line(Vector2(0, size.y-0.5), Vector2(size.x, size.y-0.5), RULE.border_color)
	if column_divider:
		draw_line(Vector2(size.x-0.5, 0), Vector2(size.x-0.5, size.y), RULE.border_color)
