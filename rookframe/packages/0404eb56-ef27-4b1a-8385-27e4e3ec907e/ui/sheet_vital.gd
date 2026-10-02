extends Button
## The character core keeps the resource caption separate from its value.
func configure(caption: String, current: int, suffix: String, maximum: int = 0) -> void:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	custom_minimum_size.y = 44 if phone or tablet else 62
	get_node(^"Inset/Copy/Caption").text = caption
	get_node(^"Inset/Copy/Caption").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)
	get_node(^"Inset/Copy/Number/Value").text = str(current)
	get_node(^"Inset/Copy/Number/Value").add_theme_font_size_override("font_size", 20 if phone else 22 if tablet else 28)
	get_node(^"Inset/Copy/Number/Extra").text = suffix
	get_node(^"Inset/Copy/Number/Extra").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 14)
	get_node(^"Inset").add_theme_constant_override("margin_left", 28 if phone else 36 if tablet else 44)
	add_theme_constant_override("icon_max_width", 20 if phone else 26 if tablet else 32)
	get_node(^"Health").visible = maximum > 0
	get_node(^"Health").max_value = maxi(1, maximum)
	get_node(^"Health").value = current
	get_node(^"Inset/Copy/Number/Value").add_theme_color_override("font_color", Color("7dd989") if maximum > 0 else Color("44e9e9"))
	accessibility_name = "%s. %d %s" % [caption, current, suffix]
