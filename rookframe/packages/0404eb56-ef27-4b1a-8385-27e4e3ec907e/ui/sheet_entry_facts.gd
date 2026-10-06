extends GridContainer

func configure(facts: Array, phone: bool) -> void:
	for raw in facts:
		var fact: Array = raw
		var lane := VBoxContainer.new()
		lane.size_flags_horizontal = 3
		lane.add_theme_constant_override("separation", 5)
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = 3
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(0.243137, 0.262745, 0.27451, 1)
		style.border_width_bottom = 1
		style.content_margin_top = 5
		style.content_margin_bottom = 12
		frame.add_theme_stylebox_override("panel", style)
		add_child(frame)
		frame.add_child(lane)
		var caption := Label.new()
		caption.text = str(fact[0])
		caption.autowrap_mode = 3
		caption.add_theme_font_size_override("font_size", 12 if phone else 15)
		caption.add_theme_color_override("font_color", Color(0.682353, 0.729412, 0.745098, 1))
		lane.add_child(caption)
		var value := Label.new()
		value.text = str(fact[1])
		value.autowrap_mode = 3
		value.add_theme_font_size_override("font_size", 20 if phone else 22)
		value.add_theme_font_override("font", preload("res://rookframe/ui/theme/silkbound_medium.tres"))
		value.add_theme_color_override("font_color", Color(0.905882, 0.905882, 0.866667, 1))
		lane.add_child(value)
