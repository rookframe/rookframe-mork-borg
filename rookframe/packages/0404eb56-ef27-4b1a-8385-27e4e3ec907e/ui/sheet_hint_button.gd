extends Button
## Godot owns tooltip timing, positioning, dismissal and lifetime.
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
var _tokens := SHEET_TOKENS.new()
var hint_title := ""
var hint_summary := ""

func configure_hint(title: String, summary: String, enabled: bool = true) -> void:
	hint_title = title
	hint_summary = summary
	tooltip_text = title + "\n" + summary if enabled and not summary.is_empty() else ""
	accessibility_description = summary

func _make_custom_tooltip(_for_text: String) -> Object:
	if tooltip_text.is_empty():
		return null
	var content: Control = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_tooltip.tscn").instantiate()
	(content.get_node(^"Title") as Label).text = hint_title
	(content.get_node(^"Summary") as Label).text = hint_summary
	return content

## Margins of the inset, whose left edge clears this button's icon.
func _icon_margins(icon_size: StringName, icon_gap: StringName, vertical: StringName, right: StringName) -> void:
	var inset := get_node(^"Inset")
	add_theme_constant_override(&"icon_max_width", _tokens.pixels(self, icon_size))
	var left := int(get_theme_stylebox(&"normal").content_margin_left) + _tokens.pixels(self, icon_size) + _tokens.pixels(self, icon_gap)
	inset.add_theme_constant_override(&"margin_left", left)
	inset.add_theme_constant_override(&"margin_top", _tokens.pixels(self, vertical))
	inset.add_theme_constant_override(&"margin_bottom", _tokens.pixels(self, vertical))
	inset.add_theme_constant_override(&"margin_right", _tokens.pixels(self, right))
