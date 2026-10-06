extends Control
var _layout_phone := false
var _layout_tablet := false
var _layout_task := false

func configure(phone: bool, tablet: bool, task: bool) -> void:
	_layout_phone = phone
	_layout_tablet = tablet
	_layout_task = task
	queue_redraw()

func _draw() -> void:
	if _layout_phone or _layout_task:
		return
	var y := 81.0 if _layout_tablet else 125.0
	var inset := 34.0 if _layout_tablet else 64.0
	draw_line(Vector2(inset, y), Vector2(size.x - inset, y), Color(0.243137, 0.262745, 0.27451, 1))
	var center := Vector2(size.x * 0.5, y)
	var points: Array[Vector2] = [Vector2(center.x, center.y - 4), Vector2(center.x + 4, center.y), Vector2(center.x, center.y + 4), Vector2(center.x - 4, center.y), Vector2(center.x, center.y - 4)]
	draw_colored_polygon(points, Color(0.082353, 0.090196, 0.098039, 1))
	draw_polyline(points, Color(0.737255, 0.572549, 0.466667, 1), 1, true)
