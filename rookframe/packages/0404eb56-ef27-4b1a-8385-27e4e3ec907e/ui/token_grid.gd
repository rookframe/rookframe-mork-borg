extends GridContainer
## Gaps of a grid, taken from the World theme's `RookframeTokens`.
##
## The gaps follow a live World theme change.

const TOKENS := &"RookframeTokens"

## Constant token of the gap between columns. Empty means no gap.
@export var gap_horizontal: StringName = &"space_2":
	set(value):
		gap_horizontal = value
		_read_tokens()
## Constant token of the gap between rows. Empty means no gap.
@export var gap_vertical: StringName = &"space_2":
	set(value):
		gap_vertical = value
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
	add_theme_constant_override(&"h_separation", get_theme_constant(gap_horizontal, TOKENS) if gap_horizontal else 0)
	add_theme_constant_override(&"v_separation", get_theme_constant(gap_vertical, TOKENS) if gap_vertical else 0)
	_reading = false
