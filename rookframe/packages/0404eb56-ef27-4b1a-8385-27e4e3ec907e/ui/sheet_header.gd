extends HBoxContainer

func configure_layout(phone: bool, tablet: bool) -> void:
	get_node(^"NameEditField/Editor").custom_minimum_size = Vector2(220 if phone else 230 if tablet else 320, 44)
	get_node(^"NameEditField/Editor").add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
	get_node(^"NameEditField/Editor/Caption").add_theme_font_size_override("font_size", 9 if phone or tablet else 11)
	for button in [get_node(^"Name"), get_node(^"Edit"), get_node(^"Rest"), get_node(^"Improve"), get_node(^"SaveSheet"), get_node(^"CancelSheet")]:
		button.add_theme_font_size_override("font_size", 12 if phone else 16)
	get_node(^"Name").add_theme_font_size_override("font_size", 22 if tablet else 28)
