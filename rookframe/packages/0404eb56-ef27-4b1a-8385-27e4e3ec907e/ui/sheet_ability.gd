extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_hint_button.gd"
## Ability corrections stay in place while the reading view separates the modifier.
func configure(caption: String, modifier: int, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 44)
	get_node(^"Inset/Row/Title").text = {"Strength": "STR", "Agility": "AGI", "Presence": "PRE", "Toughness": "TOU"}.get(caption, caption) if phone else caption
	get_node(^"Inset/Row/Title").add_theme_font_size_override("font_size", 14 if phone else 17 if tablet else 21)
	get_node(^"Inset/Row/Value").text = ("%+d" % modifier).replace("-", "−")
	get_node(^"Inset/Row/Value").add_theme_font_size_override("font_size", 22 if phone or tablet else 27)
	# Phone and tablet rows carry no pictogram, so their copy starts at the row's own inset.
	var compact := phone or tablet
	if caption == "Strength":
		icon = null if compact else preload("res://rookframe/ui/icons/character/strength.svg")
	elif caption == "Agility":
		icon = null if compact else preload("res://rookframe/ui/icons/character/agility.svg")
	elif caption == "Presence":
		icon = null if compact else preload("res://rookframe/ui/icons/character/presence.svg")
	elif caption == "Toughness":
		icon = null if compact else preload("res://rookframe/ui/icons/character/toughness.svg")
	_icon_margins(&"" if compact else &"icon_medium", &"" if compact else &"space_2", &"", &"space_2")
	configure_hint(caption, {"Strength":"Physical force and melee attacks.", "Agility":"Balance, movement and defence.", "Presence":"Awareness, influence and Powers.", "Toughness":"Endure poison, sickness and hardship."}.get(caption, ""), not phone)
	accessibility_name = "%s. %+d" % [caption, modifier]
