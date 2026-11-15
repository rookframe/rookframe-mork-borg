extends Control
## Tints a Creature sheet pictogram, rule or scrim with a `RookframeTokens`
## color of the World theme. Attach to a TextureRect or a ColorRect; the tint
## follows a live World theme change.

const TOKENS := &"RookframeTokens"

## Color token of the tint.
@export var color: StringName = &"ornament":
	set(value):
		color = value
		_read_tokens()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_read_tokens()


func _read_tokens() -> void:
	if is_inside_tree():
		self_modulate = get_theme_color(color, TOKENS)
