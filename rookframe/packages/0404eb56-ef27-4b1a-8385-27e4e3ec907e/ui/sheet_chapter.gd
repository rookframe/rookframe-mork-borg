extends VBoxContainer
signal resource_requested(id: String)
signal resource_changed(field: String, value: String)
var _resource := "power_uses"
var _setting_resource := false
var _story: Array[Dictionary] = []
var _notes: Array[Dictionary] = []

func _ready() -> void:
	get_node(^"ChapterCaption/Resource").pressed.connect(_open_resource)
	get_node(^"ChapterCaption/SilverEditField/Editor").text_changed.connect(_silver_changed)

func _open_resource() -> void:
	resource_requested.emit("resource:" + _resource)

func _silver_changed(value: String) -> void:
	if not _setting_resource:
		resource_changed.emit("silver", value)


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

func configure_caption(chapter: int, phone: bool, filter: int, data: Dictionary, draft: Dictionary, section: int) -> void:
	get_node(^"Collections/Primary").columns = 2 if chapter == 2 or chapter == 1 and not phone else 1
	var entries: Array[Dictionary] = []
	for entry in _story:
		entries.append(entry)
	if phone and section == 0:
		for entry in _notes:
			entries.append(entry)
	get_node(^"JournalPanel/Story").configure(entries, "", "STORY", "")
	get_node(^"JournalPanel/Notes").configure(_notes, "", "NOTES", "")
	get_node(^"ChapterCaption").visible = not phone and chapter in [1, 2, 3, 4]
	get_node(^"ChapterCaption/Caption").visible = chapter != 2
	get_node(^"ChapterCaption/Caption").text = "Known Powers" if chapter == 1 else "Appearance · Portrait and preferred Miniature" if chapter == 4 else "The places and words you carry"
	_resource = "power_uses" if chapter == 1 else "silver"
	get_node(^"ChapterCaption/Resource").visible = chapter == 1 or chapter == 2 and draft.is_empty()
	get_node(^"ChapterCaption/Resource").text = (str(data.get("power_uses", 0)) + (" / " + str(data.power_uses_total) if data.has("power_uses_total") else "") + " uses remaining") if chapter == 1 else str(data.get("silver", 0)) + " Silver"
	get_node(^"ChapterCaption/Resource").icon = preload("res://rookframe/ui/icons/character/palms.svg") if chapter == 1 else preload("res://rookframe/ui/icons/character/silver.svg")
	get_node(^"ChapterCaption/SilverEditField/Editor").visible = chapter == 2 and not draft.is_empty()
	_setting_resource = true
	get_node(^"ChapterCaption/SilverEditField/Editor").text = str(draft.get("silver", ""))
	_setting_resource = false
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

func capture_pages(pages: Dictionary, chapter: int) -> Dictionary:
	pages[str(chapter) + ":primary"] = get_node(^"Collections/Primary").capture_state()
	pages[str(chapter) + ":resources"] = get_node(^"Collections/Secondary/Resources").capture_state()
	pages[str(chapter) + ":companions"] = get_node(^"Collections/Secondary/Companions").capture_state()
	pages[str(chapter) + ":story"] = get_node(^"JournalPanel/Story").capture_state()
	pages[str(chapter) + ":notes"] = get_node(^"JournalPanel/Notes").capture_state()
	return pages

func restore_pages(pages: Dictionary, chapter: int) -> void:
	var primary: Dictionary = pages.get(str(chapter) + ":primary", {})
	get_node(^"Collections/Primary").restore_state(primary)
	var resources: Dictionary = pages.get(str(chapter) + ":resources", {})
	get_node(^"Collections/Secondary/Resources").restore_state(resources)
	var companions: Dictionary = pages.get(str(chapter) + ":companions", {})
	get_node(^"Collections/Secondary/Companions").restore_state(companions)
	var story: Dictionary = pages.get(str(chapter) + ":story", {})
	get_node(^"JournalPanel/Story").restore_state(story)
	var notes: Dictionary = pages.get(str(chapter) + ":notes", {})
	get_node(^"JournalPanel/Notes").restore_state(notes)

func configure_journal(story: Array[Dictionary], notes: Array[Dictionary]) -> void:
	_story = story
	_notes = notes
