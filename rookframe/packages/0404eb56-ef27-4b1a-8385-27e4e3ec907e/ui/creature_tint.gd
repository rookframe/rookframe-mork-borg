extends TextureRect
## Tints a Creature sheet pictogram with a `RookframeTokens` color of the World
## theme. A ColorRect takes creature_tint_rect.gd. The tint follows a live
## World theme change.

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
