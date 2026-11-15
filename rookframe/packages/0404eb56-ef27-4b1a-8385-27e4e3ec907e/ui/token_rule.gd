extends Control
## Package hairline rule drawn in a `RookframeTokens` color of the World theme.
##
## The rule is centred across the Control and spans its length. It assigns no
## Theme and follows a live World theme change.

const TOKENS := &"RookframeTokens"

## Color token of the line.
@export var color: StringName = &"divider":
	set(value):
		color = value
		queue_redraw()
## A vertical rule separates columns; a horizontal rule separates rows.
@export var vertical := false:
	set(value):
		vertical = value
		update_minimum_size()
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		update_minimum_size()
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()


func _get_minimum_size() -> Vector2:
	var width := get_theme_constant(&"border_width", TOKENS)
	return Vector2(width, 0) if vertical else Vector2(0, width)


func _draw() -> void:
	# Godot's hairline primitive retains a screen pixel at fractional HUD scales.
	var line := get_theme_color(color, TOKENS)
	if vertical:
		draw_line(Vector2(size.x / 2, 0), Vector2(size.x / 2, size.y), line, -1.0)
	else:
		draw_line(Vector2(0, size.y / 2), Vector2(size.x, size.y / 2), line, -1.0)
