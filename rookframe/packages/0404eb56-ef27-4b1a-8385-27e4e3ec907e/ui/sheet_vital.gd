extends Button
## The character core keeps the resource caption separate from its value.
func configure(caption: String, current: int, suffix: String, maximum: int = 0, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 44 if phone or tablet else 62)
	get_node(^"Inset/Copy/Caption").text = caption
	get_node(^"Inset/Copy/Caption").add_theme_font_size_override("font_size", 10 if phone or tablet else 12)
	for path in [^"Inset/Copy/Number/Value", ^"Inset/Copy/Number/HealthValue", ^"Inset/Copy/Number/DeadValue"]:
		get_node(path).text = str(current)
		get_node(path).add_theme_font_size_override("font_size", 20 if phone else 22 if tablet else 28)
	get_node(^"Inset/Copy/Number/Extra").text = suffix
	get_node(^"Inset/Copy/Number/Extra").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 14)
	get_node(^"Inset").add_theme_constant_override("margin_left", 28 if phone else 36 if tablet else 44)
	get_node(^"Inset").add_theme_constant_override("margin_top", 1 if phone or tablet else 5)
	get_node(^"Inset").add_theme_constant_override("margin_bottom", 1 if phone or tablet else 5)
	add_theme_constant_override("icon_max_width", 20 if phone or tablet else 32)
	get_node(^"Health").visible = maximum > 0
	get_node(^"Health").max_value = maxi(1, maximum)
	get_node(^"Health").value = current
	get_node(^"Inset/Copy/Number/Value").visible = maximum == 0
	get_node(^"Inset/Copy/Number/HealthValue").visible = maximum > 0 and current > 0
	get_node(^"Inset/Copy/Number/DeadValue").visible = maximum > 0 and current <= 0
	if maximum > 0:
		icon = null if current <= 0 else preload("res://rookframe/ui/icons/character/heart.svg")
	get_node(^"DangerIcon").visible = maximum > 0 and current <= 0
	get_node(^"DangerIcon").offset_top = -10 if phone or tablet else -16
	get_node(^"DangerIcon").offset_bottom = 10 if phone or tablet else 16
	get_node(^"DangerIcon").offset_right = 20 if phone or tablet else 32
	accessibility_name = "%s. %d %s" % [caption, current, suffix]
