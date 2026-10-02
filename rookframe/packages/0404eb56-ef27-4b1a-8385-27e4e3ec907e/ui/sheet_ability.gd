extends Button
## Ability corrections stay in place while the reading view separates the modifier.
func configure(caption: String, modifier: int, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size.y = 44 if phone or tablet else 56
	get_node(^"Inset/Row/Title").text = caption
	get_node(^"Inset/Row/Title").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 18)
	get_node(^"Inset/Row/Value").text = "%+d" % modifier
	get_node(^"Inset/Row/Value").add_theme_font_size_override("font_size", 16 if phone else 18 if tablet else 24)
	get_node(^"Inset").add_theme_constant_override("margin_left", 24 if phone else 32)
	add_theme_constant_override("icon_max_width", 18 if phone else 24)
	accessibility_name = "%s. %+d" % [caption, modifier]
