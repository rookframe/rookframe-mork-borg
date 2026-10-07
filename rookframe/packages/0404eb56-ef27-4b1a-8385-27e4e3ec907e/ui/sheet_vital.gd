extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_hint_button.gd"
## The character core keeps the resource caption separate from its value.
func configure(caption: String, current: int, suffix: String, maximum: int = 0, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 48 if phone or tablet else 72)
	get_node(^"Inset/Copy/Caption").text = caption
	get_node(^"Inset/Copy/Caption").add_theme_font_size_override("font_size", 14 if phone or tablet else 17)
	for path in [^"Inset/Copy/Number/Value", ^"Inset/Copy/Number/HealthValue", ^"Inset/Copy/Number/DeadValue"]:
		get_node(path).text = str(current)
		get_node(path).add_theme_font_size_override("font_size", 24 if phone or tablet else 32)
	get_node(^"Inset/Copy/Number/Extra").text = suffix
	get_node(^"Inset/Copy/Number/Extra").add_theme_font_size_override("font_size", 14 if phone or tablet else 17)
	get_node(^"Inset").add_theme_constant_override("margin_left", 36 if phone or tablet else 52)
	get_node(^"Inset").add_theme_constant_override("margin_top", 4 if phone or tablet else 6)
	get_node(^"Inset").add_theme_constant_override("margin_bottom", 4 if phone or tablet else 6)
	add_theme_constant_override("icon_max_width", 22 if phone or tablet else 28)
	get_node(^"Health").visible = maximum > 0
	get_node(^"Health").max_value = maxi(1, maximum)
	get_node(^"Health").value = current
	get_node(^"Inset/Copy/Number/Value").visible = maximum == 0
	get_node(^"Inset/Copy/Number/HealthValue").visible = maximum > 0 and current > 0
	get_node(^"Inset/Copy/Number/DeadValue").visible = maximum > 0 and current <= 0
	if maximum > 0:
		icon = null if current <= 0 else preload("res://rookframe/ui/icons/character/heart.svg")
	get_node(^"DangerIcon").visible = maximum > 0 and current <= 0
	get_node(^"DangerIcon").offset_top = -12.5 if phone else -10 if tablet else -14
	get_node(^"DangerIcon").offset_bottom = 12.5 if phone else 10 if tablet else 14
	get_node(^"DangerIcon").offset_right = 22 if phone or tablet else 28
	configure_hint(caption, {"Hit points":"Track wounds and recovery.", "Omens":"Resolve an Omen’s benefit, then mark it spent.", "Power uses":"Uses available for casting Powers."}.get(caption, "Inspect this resource."), not phone)
	accessibility_name = "%s. %d %s" % [caption, current, suffix]

	get_node(^"Inset").add_theme_constant_override("margin_right", 8)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var frame: StyleBox = get_theme_stylebox(state).duplicate()
		frame.content_margin_left = 8
		frame.content_margin_right = 8
		add_theme_stylebox_override(state, frame)
	for path in [^"Inset/Copy/Caption", ^"Inset/Copy/Number/Extra", ^"Inset/Copy/Number/Value", ^"Inset/Copy/Number/HealthValue", ^"Inset/Copy/Number/DeadValue"]:
		var label: Label = get_node(path)
		var font: FontVariation = preload("res://rookframe/ui/theme/silkbound_medium.tres").duplicate()
		if path == ^"Inset/Copy/Caption" or path == ^"Inset/Copy/Number/Extra":
			font = preload("res://rookframe/ui/theme/silkbound_regular.tres").duplicate()
		font.spacing_top = -2 if phone or tablet else -4
		font.spacing_bottom = -3 if phone or tablet else -4
		label.add_theme_font_override("font", font)
	get_node(^"DangerIcon").offset_left = 8
	get_node(^"DangerIcon").offset_right = 30 if phone or tablet else 36
	custom_minimum_size = Vector2(44, maxf(custom_minimum_size.y, get_node(^"Inset").get_combined_minimum_size().y))
