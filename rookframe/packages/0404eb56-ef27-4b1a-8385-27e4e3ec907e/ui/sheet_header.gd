extends HBoxContainer

func configure(data: Dictionary, draft: Dictionary, owner: bool, action_live: bool, dead: bool) -> void:
	var editing := not draft.is_empty()
	get_node(^"Name").visible = not editing
	get_node(^"Name").text = str(data.get("name", "Character"))
	get_node(^"NameEditField/Editor").visible = editing
	get_node(^"NameEditField/Editor").text = str(draft.get("name", data.get("name", "")))
	get_node(^"Close").visible = true
	get_node(^"EditingStatus").visible = editing
	get_node(^"Spacer").visible = false
	get_node(^"System").visible = false
	get_node(^"Edit").disabled = not owner or action_live
	get_node(^"Edit").visible = not editing
	get_node(^"Rest").disabled = not owner or editing or action_live or dead
	get_node(^"Improve").disabled = not owner or editing or action_live
	get_node(^"SaveSheet").visible = editing
	get_node(^"CancelSheet").visible = editing

func configure_layout(phone: bool, tablet: bool) -> void:
	get_node(^"NameEditField/Editor").custom_minimum_size = Vector2(220 if phone else 230 if tablet else 320, 44)
	get_node(^"NameEditField/Editor").add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
	get_node(^"NameEditField/Editor/Caption").add_theme_font_size_override("font_size", 9 if phone or tablet else 11)
	for button in [get_node(^"Name"), get_node(^"Edit"), get_node(^"Rest"), get_node(^"Improve"), get_node(^"SaveSheet"), get_node(^"CancelSheet")]:
		button.add_theme_font_size_override("font_size", 12 if phone else 16)
	get_node(^"Name").custom_minimum_size = Vector2(get_node(^"Name").custom_minimum_size.x, 26 if phone else 52 if tablet else 60)
	get_node(^"Name").add_theme_font_size_override("font_size", 23 if phone else 29 if tablet else 40)

	get_node(^"Name").add_theme_constant_override("icon_max_width", 26)
	get_node(^"Name").add_theme_constant_override("h_separation", 11)

	get_node(^"RibbonSpace").visible = not phone
	get_node(^"RibbonSpace").custom_minimum_size = Vector2(40 if tablet else 56, 0)
	get_node(^"Close").size_flags_vertical = 4
	get_node(^"Close").add_theme_font_size_override("font_size", 28)
	get_node(^"Close").tooltip_text = "Close character sheet"
	get_node(^"Edit").tooltip_text = "Edit sheet"
	get_node(^"Edit").text = "" if phone else "Edit sheet"

	for path in [^"Close", ^"Edit"]:
		var button: Button = get_node(path)
		button.custom_minimum_size = Vector2(44, 44)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var frame: StyleBox = button.get_theme_stylebox(state).duplicate()
			frame.content_margin_top = 2
			frame.content_margin_bottom = 2
			button.add_theme_stylebox_override(state, frame)
