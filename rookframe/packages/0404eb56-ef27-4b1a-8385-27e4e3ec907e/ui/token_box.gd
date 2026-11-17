extends BoxContainer
## Gap of a box container, taken from the World theme's `RookframeTokens`.
##
## Attach to an HBoxContainer, VBoxContainer or BoxContainer; a flow container
## takes token_flow.gd. The gap follows a live World theme change.

const TOKENS := &"RookframeTokens"

## Constant token of the gap, `space_1` to `space_8`. Empty means no gap.
@export var gap: StringName = &"space_2":
	set(value):
		gap = value
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
	add_theme_constant_override(&"separation", get_theme_constant(gap, TOKENS) if gap else 0)
	_reading = false
