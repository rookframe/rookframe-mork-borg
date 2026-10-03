extends VBoxContainer
signal resource_requested(id: String)
signal resource_changed(field: String, value: String)
@onready var _route_quick = get_node(^"QuickResources")
var _resource := "power_uses"
var _setting_resource := false
var _story: Array[Dictionary] = []
var _notes: Array[Dictionary] = []

func _ready() -> void:
	get_node("ChapterCaption/Resource").pressed.connect(_open_resource)
	get_node("ChapterCaption/SilverEditField/Editor").text_changed.connect(_silver_changed)
	get_node("ChapterCaption/PowerEditField/Editor").text_changed.connect(_power_changed)

func _open_resource() -> void:
	resource_requested.emit("resource:" + _resource)

func _silver_changed(value: String) -> void:
	if not _setting_resource:
		resource_changed.emit("silver", value)


func _power_changed(value: String) -> void:
	if not _setting_resource:
		resource_changed.emit("power_uses", value)

func configure_layout(phone: bool, tablet: bool) -> void:
	add_theme_constant_override("separation", 4 if phone else 12)
	for path in ["Tabs/TabCharacter", "Tabs/TabPowers", "Tabs/TabInventory", "Tabs/TabJournal", "Tabs/TabAppearance"]:
		var button = get_node(path)
		button.custom_minimum_size = Vector2(44, 50 if phone else 48)
		button.icon_alignment = 1 if phone else 0
		button.vertical_icon_alignment = 0 if phone else 1
		button.add_theme_constant_override("icon_max_width", 21 if phone else 26)
		button.add_theme_constant_override("h_separation", 2 if phone else 8)
		button.add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 18)
	for path in ["AppearancePanel/PortraitPanel/Inset", "AppearancePanel/MiniaturePanel/Inset"]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node(path).add_theme_constant_override("margin_" + edge, 10 if phone else 12 if tablet else 18)
	get_node("AppearancePanel").add_theme_constant_override("separation", 12 if phone or tablet else 20)
	for path in ["AppearancePanel/PortraitPanel/Inset/Content/PortraitHeading", "AppearancePanel/MiniaturePanel/Inset/Content/MiniatureHeading"]:
		(get_node(path + "/Title") as Control).add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
		(get_node(path + "/Icon") as Control).custom_minimum_size = Vector2(20, 20) if phone else Vector2(24, 24)
	for path in ["AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait", "AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait", "AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature", "AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature"]:
		get_node(path).add_theme_font_size_override("font_size", 11 if phone else 12 if tablet else 13)
	for path in ["AppearancePanel/PortraitPanel/Inset/Content/Explanation", "AppearancePanel/MiniaturePanel/Inset/Content/Explanation", "AppearancePanel/MiniaturePanel/Inset/Content/PackageCaption"]:
		get_node(path).add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)

	get_node("AppearanceIntro/Title").add_theme_font_size_override("font_size", 23 if tablet else 26)
	get_node("AppearanceIntro/Copy").add_theme_font_size_override("font_size", 12 if tablet else 13)
	get_node("AppearanceStatus").custom_minimum_size = Vector2(get_node("AppearanceStatus").custom_minimum_size.x, 24 if phone else 28)
	get_node("AppearanceStatus").add_theme_font_size_override("font_size", 10 if phone else 12)
	get_node("AppearancePanel/MiniaturePanel/Inset/Content/MiniatureCaption").add_theme_font_size_override("font_size", 12 if phone else 17)
	get_node("AppearancePanel/MiniaturePanel/Inset/Content/EmptyPreview/Image").custom_minimum_size = Vector2(34, 34) if phone else Vector2(100, 100)
	for path in ["AppearancePanel/PortraitPanel/Inset/Content", "AppearancePanel/MiniaturePanel/Inset/Content"]:
		get_node(path).add_theme_constant_override("separation", 4 if phone else 8)
		(get_node(path + "/ControlsGap") as Control).custom_minimum_size = Vector2((get_node(path + "/ControlsGap") as Control).custom_minimum_size.x, 0 if phone else 8)
	for path in ["AppearancePanel/PortraitPanel/Inset/Content/PortraitButtons", "AppearancePanel/MiniaturePanel/Inset/Content/MiniatureButtons"]:
		get_node(path).add_theme_constant_override("separation", 6 if phone else 8)

func configure_caption(chapter: int, phone: bool, filter: int, data: Dictionary, draft: Dictionary, section: int) -> void:
	get_node("Collections/Primary").columns = 2 if chapter == 2 or chapter == 1 and not phone else 1
	get_node("Collections/Primary").collection_layout = 2 if chapter == 2 else 1 if chapter == 1 else 0
	get_node("JournalPanel/Story").collection_layout = 1
	var entries: Array[Dictionary] = []
	for entry in _story:
		entries.append(entry)
	if phone and section == 0:
		for entry in _notes:
			entries.append(entry)
	get_node("JournalPanel/Story").configure(entries, "", "STORY", "")
	get_node("JournalPanel/Notes").configure(_notes, "", "NOTES", "")
	get_node("ChapterCaption").visible = not phone and chapter in [1, 2, 3, 4]
	get_node("ChapterCaption/Caption").visible = chapter != 2
	get_node("ChapterCaption/Caption").text = "Known Powers" if chapter == 1 else "Appearance · Portrait and preferred Miniature" if chapter == 4 else "The places and words you carry"
	_resource = "power_uses" if chapter == 1 else "silver"
	get_node("ChapterCaption/Resource").visible = chapter in [1, 2] and draft.is_empty()
	get_node("ChapterCaption/Resource").text = (str(data.get("power_uses", 0)) + (" / " + str(data.power_uses_total) if data.has("power_uses_total") else "") + " uses remaining") if chapter == 1 else str(data.get("silver", 0)) + " Silver"
	get_node("ChapterCaption/Resource").icon = preload("res://rookframe/ui/icons/character/palms.svg") if chapter == 1 else preload("res://rookframe/ui/icons/character/silver.svg")
	get_node("ChapterCaption/SilverEditField/Editor").visible = chapter == 2 and not draft.is_empty()
	_setting_resource = true
	get_node("ChapterCaption/SilverEditField/Editor").text = str(draft.get("silver", ""))
	get_node("ChapterCaption/PowerEditField/Editor").visible = chapter == 1 and not draft.is_empty()
	get_node("ChapterCaption/PowerEditField/Editor").text = str(draft.get("power_uses", ""))
	_setting_resource = false
	get_node("ChapterCaption/PersonalNotes").visible = chapter == 3
	get_node("ChapterCaption/InventoryFilters").visible = chapter == 2
	for index in range(4):
		get_node(["ChapterCaption/InventoryFilters/All", "ChapterCaption/InventoryFilters/Arms", "ChapterCaption/InventoryFilters/Supplies", "ChapterCaption/InventoryFilters/Ready"][index]).set_pressed_no_signal(filter == index)

func capture_pages(pages: Dictionary, chapter: int) -> Dictionary:
	pages[str(chapter) + ":primary"] = get_node("Collections/Primary").capture_state()
	pages[str(chapter) + ":resources"] = get_node("Collections/Secondary/Resources").capture_state()
	pages[str(chapter) + ":companions"] = get_node("Collections/Secondary/Companions").capture_state()
	pages[str(chapter) + ":story"] = get_node("JournalPanel/Story").capture_state()
	pages[str(chapter) + ":notes"] = get_node("JournalPanel/Notes").capture_state()
	return pages

func restore_pages(pages: Dictionary, chapter: int) -> void:
	var primary: Dictionary = pages.get(str(chapter) + ":primary", {})
	get_node("Collections/Primary").restore_state(primary)
	var resources: Dictionary = pages.get(str(chapter) + ":resources", {})
	get_node("Collections/Secondary/Resources").restore_state(resources)
	var companions: Dictionary = pages.get(str(chapter) + ":companions", {})
	get_node("Collections/Secondary/Companions").restore_state(companions)
	var story: Dictionary = pages.get(str(chapter) + ":story", {})
	get_node("JournalPanel/Story").restore_state(story)
	var notes: Dictionary = pages.get(str(chapter) + ":notes", {})
	get_node("JournalPanel/Notes").restore_state(notes)

func configure_journal(story: Array[Dictionary], notes: Array[Dictionary]) -> void:
	_story = story
	_notes = notes

func focus_entry(id: String) -> bool:
	for path in ["Collections/Primary", "Collections/Secondary/Resources", "Collections/Secondary/Companions", "JournalPanel/Story", "JournalPanel/Notes"]:
		if get_node(path).focus_entry(id):
			return true
	return false

func configure_route(chapter: int, phone: bool, tablet: bool, details: bool, modal: bool, condition_reference: bool, data: Dictionary, editing: bool, draft: Dictionary, navigation: Dictionary) -> void:
	var _chapter_tabs = get_node(^"Tabs")
	var _chapter_collections = get_node(^"Collections")
	var _chapter_journal_panel = get_node(^"JournalPanel")
	var _condition_ui = get_node(^"Condition")
	var _section = get_node(^"Section")
	var _quick = _route_quick
	var _chapter_primary = get_node(^"Collections/Primary")
	var _chapter_secondary = get_node(^"Collections/Secondary")
	var _chapter_resources = get_node(^"Collections/Secondary/Resources")
	var _chapter_companions = get_node(^"Collections/Secondary/Companions")
	var _chapter_caption = get_node(^"ChapterCaption")
	var _chapter_story = get_node(^"JournalPanel/Story")
	var _chapter_notes = get_node(^"JournalPanel/Notes")
	var obscured := details and not modal
	_chapter_tabs.visible = not obscured
	_chapter_collections.visible = not obscured and chapter in [0, 1, 2]
	_chapter_journal_panel.visible = not obscured and chapter == 3
	get_node(^"AppearanceIntro").visible = not obscured and chapter == 4 and not phone
	get_node(^"AppearanceStatus").visible = not obscured and chapter == 4
	_condition_ui.visible = not obscured and chapter == 0 and not condition_reference and not preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_projection.gd").new().condition(data).is_empty()
	_section.visible = phone and not details and chapter in [0, 1, 2, 3]
	_quick.visible = phone and not details and chapter != 4 and not _condition_ui.visible
	_section.clear()
	for title in (["Features & traits", "Resources", "Companions"] if chapter == 0 else ["Powers", "Decoctions & resources"] if chapter == 1 else ["All belongings", "Arms", "Supplies", "Ready"] if chapter == 2 else ["All", "Story", "Notes"]):
		_section.add_item(str(title))
	_section.select(mini(int(navigation.get("inventory_filter", 0) if chapter == 2 else navigation.get("section", 0)), _section.item_count - 1))
	_chapter_primary.visible = chapter == 2 or not phone or _section.selected == 0
	_chapter_secondary.visible = chapter == 0 and (not phone or _section.selected != 0) or chapter == 1 and phone and _section.selected == 1
	_chapter_resources.visible = not phone or _section.selected == 1
	_chapter_companions.visible = chapter == 0 and (condition_reference or preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_projection.gd").new().condition(data).is_empty()) and (not phone or _section.selected == 2)
	if phone and _condition_ui.visible:
		_chapter_collections.visible = false
		_section.visible = false
	get_node(^"ReferenceBack").visible = phone and condition_reference and not details and chapter == 0
	var resource_editor = get_node(^"Collections/Secondary/ResourceEditors")
	resource_editor.visible = editing and chapter == 0 and (not phone or _section.selected == 1)
	resource_editor.configure(draft, phone, tablet)
	_chapter_resources.visible = _chapter_resources.visible and not (chapter == 0 and editing)
	configure_caption(chapter, phone, int(navigation.get("inventory_filter", 0)), data, draft if editing else {}, int(navigation.get("section", 0)))
	_chapter_caption.visible = not obscured and not phone and chapter in [1, 2, 3]
	_chapter_story.visible = not phone or _section.selected < 2
	_chapter_notes.visible = not phone or _section.selected == 2
