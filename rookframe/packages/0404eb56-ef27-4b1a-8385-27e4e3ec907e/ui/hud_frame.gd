extends Control

## The approved angular frame uses ordinary Godot CanvasItem drawing.
@export var cut := 10.0
@export var pointer := -1.0
const TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/hud_palette.gd")
func _ready() -> void:
	resized.connect(_redraw)
func _redraw() -> void:
	queue_redraw()
func _draw() -> void:
	var w := size.x - 0.5
	var h := size.y - 0.5
	var points := ([Vector2(cut, 0.5), Vector2(w, 0.5), Vector2(w, h-cut), Vector2(w-cut, h), Vector2(0.5, h), Vector2(0.5, cut)])
	draw_colored_polygon(points, TOKENS.COLOR_INK)
	points.append(points[0])
	draw_polyline(points, TOKENS.COLOR_EDGE, 1.0, true)
	if pointer >= 0.0:
		var triangle := ([Vector2(pointer-6, h), Vector2(pointer, h+6), Vector2(pointer+6, h)])
		draw_colored_polygon(triangle, TOKENS.COLOR_INK)
		draw_polyline(triangle, TOKENS.COLOR_EDGE, 1.0, true)
