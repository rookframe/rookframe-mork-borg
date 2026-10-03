extends HBoxContainer

const TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/hud_palette.gd")
var separator := false
var column_divider := false
func _ready() -> void:
	resized.connect(_redraw)
func _redraw() -> void:
	queue_redraw()
func _draw() -> void:
	if separator:
		draw_line(Vector2(0, size.y-0.5), Vector2(size.x, size.y-0.5), TOKENS.COLOR_RULE)
	if column_divider:
		draw_line(Vector2(size.x-0.5, 0), Vector2(size.x-0.5, size.y), TOKENS.COLOR_RULE)
