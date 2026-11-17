extends LineEdit
## Inline sheet editor whose caption sits inside its frame.
##
## No UI Kit name supplies a field that keeps room for an inner caption, so the
## frame is built from the World theme's `RookframeTokens` alone. It assigns no
## Theme and follows a live World theme change.

const TOKENS := &"RookframeTokens"

var _normal := StyleBoxFlat.new()
var _focus := StyleBoxFlat.new()
var _reading := false


func _init() -> void:
	add_theme_stylebox_override(&"normal", _normal)
	add_theme_stylebox_override(&"focus", _focus)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()


# Changing an override's StyleBox notifies this Control of a theme change, so
# the read guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	var side := get_theme_constant(&"space_1", TOKENS)
	_normal.bg_color = get_theme_color(&"surface_sunken", TOKENS)
	_normal.border_color = get_theme_color(&"border", TOKENS)
	_normal.set_border_width_all(get_theme_constant(&"border_width", TOKENS))
	_normal.set_corner_radius_all(get_theme_constant(&"radius_small", TOKENS))
	_normal.content_margin_left = side
	_normal.content_margin_right = side
	# The caption occupies the top of the frame.
	_normal.content_margin_top = get_theme_constant(&"space_4", TOKENS)
	_normal.content_margin_bottom = side
	_focus.bg_color = Color(0, 0, 0, 0)
	_focus.border_color = get_theme_color(&"focus_ring", TOKENS)
	_focus.set_border_width_all(get_theme_constant(&"focus_width", TOKENS))
	_focus.set_corner_radius_all(get_theme_constant(&"radius_small", TOKENS))
	_reading = false
