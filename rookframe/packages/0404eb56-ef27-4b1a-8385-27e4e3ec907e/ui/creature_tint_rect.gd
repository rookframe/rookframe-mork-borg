extends ColorRect
## Tints a Creature sheet rule or scrim with a `RookframeTokens` color of the
## World theme. A TextureRect takes creature_tint.gd. The tint follows a live
## World theme change.

const TOKENS := &"RookframeTokens"

## Color token of the tint. The rect's own color stays white under it.
@export var tint: StringName = &"scrim":
	set(value):
		tint = value
		_read_tokens()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_read_tokens()


func _read_tokens() -> void:
	if is_inside_tree():
		self_modulate = get_theme_color(tint, TOKENS)
