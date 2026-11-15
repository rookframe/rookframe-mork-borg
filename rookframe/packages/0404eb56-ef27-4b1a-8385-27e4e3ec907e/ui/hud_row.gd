extends HBoxContainer
## One HUD list entry: a launch target with optional use, full-name and favorite
## actions. Its gap, rules and tints come from the World theme's `RookframeTokens`
## and follow a live World theme change.

const TOKENS := &"RookframeTokens"

## Constant token of the gap between the launch target and the row actions. Empty means no gap.
@export var gap: StringName = &"":
	set(value):
		gap = value
		_read_tokens()

var separator := false
var column_divider := false
var _icon_token: StringName = &""
var _copy_token: StringName = &""
var _copy_tinted := false
var _reading := false


## Tints the pictogram and the title and value copy with color tokens.
## An empty token leaves that part to its own type variation or caller.
func tint(icon_token: StringName, copy_token: StringName) -> void:
	_icon_token = icon_token
	_copy_token = copy_token
	_read_tokens()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()


# Setting an override notifies this Control of a theme change, so the read
# guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	add_theme_constant_override(&"separation", get_theme_constant(gap, TOKENS) if gap else 0)
	if _icon_token:
		get_node(^"Launch/Content/Icon").modulate = get_theme_color(_icon_token, TOKENS)
	for path in [^"Launch/Content/Copy/Title", ^"Launch/Content/Value"]:
		var label: Label = get_node(path)
		if _copy_token:
			label.add_theme_color_override(&"font_color", get_theme_color(_copy_token, TOKENS))
		elif _copy_tinted:
			label.remove_theme_color_override(&"font_color")
	_copy_tinted = not _copy_token.is_empty()
	_reading = false


func _draw() -> void:
	var rule := get_theme_color(&"divider", TOKENS)
	if separator:
		draw_line(Vector2(0, size.y - 0.5), Vector2(size.x, size.y - 0.5), rule, -1.0)
	if column_divider:
		draw_line(Vector2(size.x - 0.5, 0), Vector2(size.x - 0.5, size.y), rule, -1.0)
