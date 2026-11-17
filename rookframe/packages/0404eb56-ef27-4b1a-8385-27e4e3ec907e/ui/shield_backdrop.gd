extends CanvasLayer
## Dims the table behind the shield decision in the World theme's `scrim`.
##
## A CanvasLayer does not pass a Theme on to its Controls, so the layer reads
## the token from the Control it is added to and follows that Control's theme.

const TOKENS := &"RookframeTokens"

var _source: Control


func _enter_tree() -> void:
	_source = get_parent() as Control
	if _source != null and not _source.theme_changed.is_connected(_read_tokens):
		_source.theme_changed.connect(_read_tokens)
	_read_tokens()


func _read_tokens() -> void:
	if _source != null:
		(get_node(^"Dim") as ColorRect).color = _source.get_theme_color(&"scrim", TOKENS)
