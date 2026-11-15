extends VBoxContainer
## A native editor and its adjacent validation lane share the same allocation.

const TOKENS := &"RookframeTokens"

## Constant token of the gap between the editor and its validation lane,
## `space_1` to `space_8`. Empty means no gap.
@export var gap: StringName = &"space_1":
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

func _ready() -> void:
	get_node(^"Editor").visibility_changed.connect(_sync_visibility)
	get_node(^"Editor").text_changed.connect(_edited)
	_sync_visibility()

func show_error(message: String) -> void:
	get_node(^"Error").text = "Error: " + message if not message.is_empty() else ""
	get_node(^"Error").visible = not message.is_empty()
	get_node(^"Editor").accessibility_description = message

func _edited(_value: String) -> void:
	show_error("")

func _sync_visibility() -> void:
	visible = get_node(^"Editor").visible
