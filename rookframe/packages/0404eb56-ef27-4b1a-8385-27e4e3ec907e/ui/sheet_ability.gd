extends Button
## Ability corrections stay in place while the reading view separates the modifier.
func configure(caption: String, modifier: int, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 44 if phone or tablet else 52)
	get_node(^"Inset/Row/Title").text = {"Strength": "STR", "Agility": "AGI", "Presence": "PRE", "Toughness": "TOU"}.get(caption, caption) if phone else caption
	get_node(^"Inset/Row/Title").add_theme_font_size_override("font_size", 12 if phone else 13 if tablet else 16)
	get_node(^"Inset/Row/Value").text = "%+d" % modifier
	get_node(^"Inset/Row/Value").add_theme_font_size_override("font_size", 22 if phone else 18 if tablet else 24)
	if caption == "Strength":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/strength.svg")
	elif caption == "Agility":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/agility.svg")
	elif caption == "Presence":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/presence.svg")
	elif caption == "Toughness":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/toughness.svg")
	get_node(^"Inset").add_theme_constant_override("margin_left", 30 if phone else 4 if tablet else 32)
	add_theme_constant_override("icon_max_width", 24 if phone else 24)
	accessibility_name = "%s. %+d" % [caption, modifier]
