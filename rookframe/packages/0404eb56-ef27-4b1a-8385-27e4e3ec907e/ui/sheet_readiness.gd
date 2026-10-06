extends Button

func configure(caption: String, description: String, phone: bool) -> void:
	custom_minimum_size = Vector2(44, 44)
	get_node(^"Inset/Copy/Caption").text = caption
	get_node(^"Inset/Copy/Caption").add_theme_font_size_override("font_size", 13)
	get_node(^"Inset/Copy/Caption").visible = phone
	get_node(^"Inset/Copy/Value").text = description
	get_node(^"Inset/Copy/Value").add_theme_font_size_override("font_size", 17 if phone else 18)
	icon = preload("res://rookframe/ui/icons/character/sword.svg") if caption.begins_with("Ready") else preload("res://rookframe/ui/icons/character/shield.svg")
	accessibility_name = caption + ". " + description
