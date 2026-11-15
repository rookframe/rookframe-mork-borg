extends MarginContainer
## Margins of a MarginContainer, taken from the World theme's `RookframeTokens`.
##
## The margins follow a live World theme change.

const TOKENS := &"RookframeTokens"

## Constant token of each margin, `space_1` to `space_8`. Empty means no margin.
@export var left: StringName = &"space_2":
	set(value):
		left = value
		_read_tokens()
@export var top: StringName = &"space_2":
	set(value):
		top = value
		_read_tokens()
@export var right: StringName = &"space_2":
	set(value):
		right = value
		_read_tokens()
@export var bottom: StringName = &"space_2":
	set(value):
		bottom = value
		_read_tokens()

var _reading := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()


# Setting an override notifies this Control of a theme change, so the read
# guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	var sides := {&"margin_left": left, &"margin_top": top, &"margin_right": right, &"margin_bottom": bottom}
	for item: StringName in sides:
		var token: StringName = sides[item]
		add_theme_constant_override(item, get_theme_constant(token, TOKENS) if token else 0)
	_reading = false
