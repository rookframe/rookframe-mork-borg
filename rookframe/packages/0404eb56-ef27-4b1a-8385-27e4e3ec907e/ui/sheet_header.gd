extends HBoxContainer
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
var _tokens := SHEET_TOKENS.new()

func configure(data: Dictionary, draft: Dictionary, owner: bool, action_live: bool, dead: bool) -> void:
	var editing := not draft.is_empty()
	get_node(^"Name").visible = not editing
	get_node(^"Name").text = str(data.get("name", "Character"))
	get_node(^"NameEditField/Editor").visible = editing
	get_node(^"NameEditField/Editor").text = str(draft.get("name", data.get("name", "")))
	get_node(^"Close").visible = true
	get_node(^"EditingStatus").visible = editing
	get_node(^"Spacer").visible = editing
	get_node(^"System").visible = false
	get_node(^"Edit").disabled = not owner or action_live
	get_node(^"Edit").visible = not editing
	get_node(^"Rest").disabled = not owner or editing or action_live or dead
	get_node(^"Improve").disabled = not owner or editing or action_live
	get_node(^"SaveSheet").visible = editing
	get_node(^"CancelSheet").visible = editing

func configure_layout(phone: bool, tablet: bool) -> void:
	add_theme_constant_override(&"separation", _tokens.pixels(self, &"space_2"))
	get_node(^"NameEditField/Editor").custom_minimum_size = Vector2(220 if phone else 230 if tablet else 320, 44)
	get_node(^"NameEditField/Editor").add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
	get_node(^"NameEditField/Editor/Caption").add_theme_font_size_override("font_size", 9 if phone or tablet else 11)
	for button in [get_node(^"Rest"), get_node(^"Improve"), get_node(^"SaveSheet"), get_node(^"CancelSheet")]:
		button.add_theme_font_size_override("font_size", 12 if phone else 16)
	var title: Button = get_node(^"Name")
	title.custom_minimum_size = Vector2(title.custom_minimum_size.x, 44 if phone else 56 if tablet else 64)
	title.add_theme_font_override("font", get_theme_font(&"display", SHEET_TOKENS.TYPE))
	# The phone title fits the UI Kit button inside the 44 px header row.
	title.add_theme_font_size_override("font_size", 18 if phone else 29 if tablet else 32)
	get_node(^"RibbonSpace").visible = true
	get_node(^"Close").size_flags_vertical = 4
	get_node(^"Close").tooltip_text = "Close character sheet"
	get_node(^"Edit").tooltip_text = "Edit sheet"
	get_node(^"Edit").text = ""
