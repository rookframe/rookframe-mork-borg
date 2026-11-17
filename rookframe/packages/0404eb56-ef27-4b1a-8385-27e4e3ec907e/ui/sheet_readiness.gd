extends Button
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
var _tokens := SHEET_TOKENS.new()

func configure(caption: String, description: String, phone: bool) -> void:
	custom_minimum_size = Vector2(44, 44)
	get_node(^"Inset/Copy/Caption").text = caption
	get_node(^"Inset/Copy/Caption").add_theme_font_size_override("font_size", 13)
	get_node(^"Inset/Copy/Caption").visible = phone
	get_node(^"Inset/Copy/Value").text = description
	get_node(^"Inset/Copy/Value").add_theme_font_size_override("font_size", 17 if phone else 18)
	icon = preload("res://rookframe/ui/icons/character/sword.svg") if caption.begins_with("Ready") else preload("res://rookframe/ui/icons/character/shield.svg")
	_icon_margins(&"icon_medium", &"space_2", &"space_1", &"space_4")
	accessibility_name = caption + ". " + description

## Margins of the inset, whose left edge clears this button's icon.
func _icon_margins(icon_size: StringName, icon_gap: StringName, vertical: StringName, right: StringName) -> void:
	var inset := get_node(^"Inset")
	add_theme_constant_override(&"icon_max_width", _tokens.pixels(self, icon_size))
	var left := int(get_theme_stylebox(&"normal").content_margin_left) + _tokens.pixels(self, icon_size) + _tokens.pixels(self, icon_gap)
	inset.add_theme_constant_override(&"margin_left", left)
	inset.add_theme_constant_override(&"margin_top", _tokens.pixels(self, vertical))
	inset.add_theme_constant_override(&"margin_bottom", _tokens.pixels(self, vertical))
	inset.add_theme_constant_override(&"margin_right", _tokens.pixels(self, right))
