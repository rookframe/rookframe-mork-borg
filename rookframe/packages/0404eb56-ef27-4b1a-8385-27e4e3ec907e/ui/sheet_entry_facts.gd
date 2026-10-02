extends GridContainer

func configure(facts: Array, phone: bool) -> void:
	for raw in facts:
		var fact: Array = raw
		var lane := VBoxContainer.new()
		lane.size_flags_horizontal = 3
		lane.add_theme_constant_override("separation", 4)
		add_child(lane)
		var caption := Label.new()
		caption.text = str(fact[0])
		caption.autowrap_mode = 3
		caption.add_theme_font_size_override("font_size", 12 if phone else 15)
		caption.add_theme_color_override("font_color", Color(0.603922, 0.647059, 0.65098, 1))
		lane.add_child(caption)
		var value := Label.new()
		value.text = str(fact[1])
		value.autowrap_mode = 3
		value.add_theme_font_size_override("font_size", 20 if phone else 22)
		value.add_theme_color_override("font_color", Color(0.266667, 0.913725, 0.913725, 1))
		lane.add_child(value)
