extends PanelContainer
## Package frame built only from the World theme's `RookframeTokens` items.
##
## Use it where no UI Kit component or `Rookframe*` type variation supplies the
## surface, such as an inset well. Every exported name is a token name; an empty
## name leaves that part out. The frame assigns no Theme, so UI Kit components
## inside it keep the World theme's presentation, and it follows a live World
## theme change.

const TOKENS := &"RookframeTokens"

## Color token of the background.
@export var fill: StringName = &"surface_sunken":
	set(value):
		fill = value
		_read_tokens()
## Color token of the outline.
@export var outline: StringName = &"border":
	set(value):
		outline = value
		_read_tokens()
## Constant token of the outline thickness.
@export var outline_width: StringName = &"border_width":
	set(value):
		outline_width = value
		_read_tokens()
## Sides that carry the outline, as bit flags: 1 left, 2 top, 4 right, 8 bottom.
@export var outline_sides := 15:
	set(value):
		outline_sides = value
		_read_tokens()
## Constant token of the corner radius.
@export var radius: StringName = &"radius_small":
	set(value):
		radius = value
		_read_tokens()
## Constant tokens of the content margins.
@export var padding_horizontal: StringName = &"space_2":
	set(value):
		padding_horizontal = value
		_read_tokens()
@export var padding_vertical: StringName = &"space_1":
	set(value):
		padding_vertical = value
		_read_tokens()

var _box := StyleBoxFlat.new()
var _reading := false


func _init() -> void:
	add_theme_stylebox_override(&"panel", _box)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()


# Changing the override's StyleBox notifies this Control of a theme change, so
# the read guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	_box.bg_color = get_theme_color(fill, TOKENS) if fill else Color(0, 0, 0, 0)
	_box.border_color = get_theme_color(outline, TOKENS) if outline else Color(0, 0, 0, 0)
	var width := get_theme_constant(outline_width, TOKENS) if outline and outline_width else 0
	_box.border_width_left = width if outline_sides % 2 >= 1 else 0
	_box.border_width_top = width if outline_sides % 4 >= 2 else 0
	_box.border_width_right = width if outline_sides % 8 >= 4 else 0
	_box.border_width_bottom = width if outline_sides % 16 >= 8 else 0
	var corner := get_theme_constant(radius, TOKENS) if radius else 0
	_box.corner_radius_top_left = corner
	_box.corner_radius_top_right = corner
	_box.corner_radius_bottom_right = corner
	_box.corner_radius_bottom_left = corner
	var horizontal := get_theme_constant(padding_horizontal, TOKENS) if padding_horizontal else 0
	var vertical := get_theme_constant(padding_vertical, TOKENS) if padding_vertical else 0
	_box.content_margin_left = horizontal
	_box.content_margin_right = horizontal
	_box.content_margin_top = vertical
	_box.content_margin_bottom = vertical
	_reading = false
