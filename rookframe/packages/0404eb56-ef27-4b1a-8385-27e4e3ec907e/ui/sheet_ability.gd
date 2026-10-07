extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_hint_button.gd"
## Ability corrections stay in place while the reading view separates the modifier.
func configure(caption: String, modifier: int, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 44)
	get_node(^"Inset/Row/Title").text = {"Strength": "STR", "Agility": "AGI", "Presence": "PRE", "Toughness": "TOU"}.get(caption, caption) if phone else caption
	get_node(^"Inset/Row/Title").add_theme_font_size_override("font_size", 14 if phone else 17 if tablet else 21)
	get_node(^"Inset/Row/Value").text = ("%+d" % modifier).replace("-", "−")
	get_node(^"Inset/Row/Value").add_theme_font_size_override("font_size", 22 if phone or tablet else 27)
	if caption == "Strength":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/strength.svg")
	elif caption == "Agility":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/agility.svg")
	elif caption == "Presence":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/presence.svg")
	elif caption == "Toughness":
		icon = null if tablet else preload("res://rookframe/ui/icons/character/toughness.svg")
	get_node(^"Inset").add_theme_constant_override("margin_left", 32 if phone else 8 if tablet else 42)
	add_theme_constant_override("icon_max_width", 24 if phone else 24)
	configure_hint(caption, {"Strength":"Physical force and melee attacks.", "Agility":"Balance, movement and defence.", "Presence":"Awareness, influence and Powers.", "Toughness":"Endure poison, sickness and hardship."}.get(caption, ""), not phone)
	accessibility_name = "%s. %+d" % [caption, modifier]

	for state in ["normal", "hover", "pressed", "disabled"]:
		var frame: StyleBox = get_theme_stylebox(state).duplicate()
		frame.content_margin_left = 6 if phone else 8
		frame.content_margin_right = 8
		add_theme_stylebox_override(state, frame)
