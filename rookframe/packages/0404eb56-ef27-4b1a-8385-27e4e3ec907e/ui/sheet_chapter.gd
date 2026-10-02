extends VBoxContainer

func configure_layout(phone: bool, tablet: bool) -> void:
	add_theme_constant_override("separation", 4 if phone else 12)
	for path in [^"Tabs/TabCharacter", ^"Tabs/TabPowers", ^"Tabs/TabInventory", ^"Tabs/TabJournal", ^"Tabs/TabAppearance"]:
		var button = get_node(path)
		button.custom_minimum_size = Vector2(44, 50 if phone else 48)
		button.icon_alignment = 1 if phone else 0
		button.vertical_icon_alignment = 0 if phone else 1
		button.add_theme_constant_override("icon_max_width", 21 if phone else 26)
		button.add_theme_constant_override("h_separation", 2 if phone else 8)
		button.add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 18)
	for path in [^"AppearancePanel/PortraitPanel/Inset", ^"AppearancePanel/MiniaturePanel/Inset"]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node(path).add_theme_constant_override("margin_" + edge, 10 if phone else 12 if tablet else 18)
	get_node(^"AppearancePanel").add_theme_constant_override("separation", 12 if phone or tablet else 20)
	for path in [^"AppearancePanel/PortraitPanel/Inset/Content/PortraitHeading", ^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureHeading"]:
		get_node(path).add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	for path in [^"AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait", ^"AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait", ^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature", ^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature"]:
		get_node(path).add_theme_font_size_override("font_size", 11 if phone else 12 if tablet else 13)
	for path in [^"AppearancePanel/PortraitPanel/Inset/Content/Explanation", ^"AppearancePanel/MiniaturePanel/Inset/Content/Explanation", ^"AppearancePanel/MiniaturePanel/Inset/Content/PackageCaption"]:
		get_node(path).add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)

func configure_caption(chapter: int, phone: bool, filter: int, data: Dictionary) -> void:
	get_node(^"ChapterCaption").visible = not phone and chapter in [1, 2, 3, 4]
	get_node(^"ChapterCaption/Caption").visible = chapter != 2
	get_node(^"ChapterCaption/Caption").text = "Known Powers · %d / %d uses remaining" % [int(data.get("power_uses", 0)), int(data.get("power_uses_total", 0))] if chapter == 1 else "Appearance · Portrait and preferred Miniature" if chapter == 4 else "The places and words you carry"
	get_node(^"ChapterCaption/PersonalNotes").visible = chapter == 3
	get_node(^"ChapterCaption/InventoryFilters").visible = chapter == 2
	for index in range(4):
		get_node([^"ChapterCaption/InventoryFilters/All", ^"ChapterCaption/InventoryFilters/Arms", ^"ChapterCaption/InventoryFilters/Supplies", ^"ChapterCaption/InventoryFilters/Ready"][index]).set_pressed_no_signal(filter == index)

func configure_appearance(owner: bool, reference: Dictionary) -> void:
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature").disabled = not owner
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature").disabled = not owner
	get_node(^"AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait").disabled = not owner
	get_node(^"AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait").disabled = not owner
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/MiniaturePreview").visible = not reference.is_empty()
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/EmptyPreview").visible = reference.is_empty()
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature").visible = not reference.is_empty()
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/PackageCaption").text = ""
	get_node(^"AppearancePanel/MiniaturePanel/Inset/Content/MiniatureCaption").text = "No miniature selected"

func configure_portrait(texture: Texture2D, caption: String) -> void:
	get_node(^"AppearancePanel/PortraitPanel/Inset/Content/PortraitPreview").texture = texture
	get_node(^"AppearancePanel/PortraitPanel/Inset/Content/PortraitCaption").text = caption
