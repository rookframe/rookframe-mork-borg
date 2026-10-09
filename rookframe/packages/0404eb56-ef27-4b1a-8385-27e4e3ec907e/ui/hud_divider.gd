extends Control

const RULE := Color(0.244353, 0.262784, 0.272745, 1)

func _ready() -> void:
	resized.connect(_redraw)

func _redraw() -> void:
	queue_redraw()

func _draw() -> void:
	# Godot's hairline primitive retains a screen pixel at fractional HUD scales.
	draw_line(Vector2(size.x / 2, 0), Vector2(size.x / 2, size.y), RULE, -1.0)
