extends VBoxContainer
signal resource_requested(id: String)
signal resource_changed(field: String, value: String)
@onready var _route_quick = get_node(^"Page/Content/QuickResources")
var _resource := "power_uses"
var _setting_resource := false
var _story: Array[Dictionary] = []
var _notes: Array[Dictionary] = []

func _ready() -> void:
	get_node("Page/Content/ChapterCaption/Resource").pressed.connect(_open_resource)
	get_node("Page/Content/ChapterCaption/SilverEditField/Editor").text_changed.connect(_silver_changed)
	get_node("Page/Content/ChapterCaption/PowerEditField/Editor").text_changed.connect(_power_changed)

func _open_resource() -> void:
	resource_requested.emit("resource:" + _resource)

func _silver_changed(value: String) -> void:
	if not _setting_resource:
		resource_changed.emit("silver", value)


func _power_changed(value: String) -> void:
	if not _setting_resource:
		resource_changed.emit("power_uses", value)

func configure_layout(phone: bool, tablet: bool) -> void:
	add_theme_constant_override("separation", 8 if phone else 0)
	var section: OptionButton = get_node(^"Page/Content/Section")
	section.add_theme_font_size_override("font_size", 18)
	section.expand_icon = true
	section.fit_to_longest_item = false
	section.clip_text = true
	section.add_theme_constant_override("icon_max_width", 25)
	section.add_theme_constant_override("h_separation", 18)
	for state in ["normal", "hover", "pressed", "disabled"]:
		section.add_theme_stylebox_override(state, preload("res://rookframe/ui/theme/silkbound_row.tres"))
	for path in ["Tabs/TabCharacter", "Tabs/TabPowers", "Tabs/TabInventory", "Tabs/TabJournal", "Tabs/TabAppearance"]:
		var button = get_node(path)
		button.custom_minimum_size = Vector2(44, 44 if phone else 48 if tablet else 54)
		button.configure_layout(18 if phone else 19 if tablet else 23, 22 if phone else 23 if tablet else 30, 6 if phone or tablet else 10)
		button.get_node(^"Center/Content/Title").visible = not (phone and path.ends_with("TabAppearance"))
		button.tooltip_text = "Appearance" if path.ends_with("TabAppearance") else ""
		button.icon_alignment = 0
		button.vertical_icon_alignment = 1
		button.add_theme_constant_override("icon_max_width", 22 if phone else 23 if tablet else 30)
		button.add_theme_constant_override("h_separation", 6 if phone or tablet else 10)
		button.add_theme_font_size_override("font_size", 18 if phone else 19 if tablet else 23)
	get_node(^"Tabs").add_theme_constant_override("separation", 4 if phone else 6 if tablet else 8)
	get_node(^"Page/Content/ChapterCaption/Caption").add_theme_font_size_override("font_size", 17 if tablet else 20)
	for raw in get_node(^"Page/Content/ChapterCaption/InventoryFilters").get_children():
		var child := raw as Control
		child.add_theme_font_size_override("font_size", 17 if tablet else 20)
		for state in ["normal", "pressed", "hover", "hover_pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0) if state == "normal" else Color(0.203922, 0.239216, 0.254902, 1)
			style.content_margin_left = 12
			style.content_margin_right = 12
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			child.add_theme_stylebox_override(state, style)
		child.custom_minimum_size = Vector2(child.custom_minimum_size.x, 44)
	get_node(^"Page/Content/ChapterCaption/InventoryFilters/Ready").text = "Equipped"
	get_node(^"Page/Content/ChapterCaption/Resource").add_theme_stylebox_override("normal", preload("res://rookframe/ui/theme/silkbound_plain.tres"))
	get_node(^"Page/Content/ChapterCaption/Resource").icon = null
	get_node(^"Page/Content/ChapterCaption/PersonalNotes").add_theme_stylebox_override("normal", preload("res://rookframe/ui/theme/silkbound_plain.tres"))
	get_node(^"Page/Content/ChapterCaption/PersonalNotes").add_theme_font_size_override("font_size", 17 if tablet else 20)
	get_node(^"Page/Content/AppearancePanel").configure_layout(phone, tablet)

func configure_caption(chapter: int, phone: bool, filter: int, data: Dictionary, draft: Dictionary, section: int) -> void:
	get_node("Page/Content/Collections/Primary").columns = 2 if chapter == 2 or chapter == 1 and not phone else 1
	get_node("Page/Content/Collections/Primary").collection_layout = 2 if chapter == 2 else 1 if chapter == 1 else 0
	get_node("Page/Content/JournalPanel/Story").collection_layout = 1
	var entries: Array[Dictionary] = []
	for entry in _story:
		entries.append(entry)
	if phone and section == 0:
		for entry in _notes:
			entries.append(entry)
	get_node("Page/Content/JournalPanel/Story").configure(entries, "", "Story", str(entries.size()))
	get_node("Page/Content/JournalPanel/Notes").configure(_notes, "", "Notes", str(_notes.size()))
	get_node("Page/Content/ChapterCaption").visible = not phone and chapter in [1, 2, 3, 4]
	get_node("Page/Content/ChapterCaption/Caption").visible = chapter != 2
	get_node("Page/Content/ChapterCaption/Caption").text = "Known Powers" if chapter == 1 else "Appearance · Portrait and preferred Miniature" if chapter == 4 else "The places and words you carry"
	_resource = "power_uses" if chapter == 1 else "silver"
	get_node("Page/Content/ChapterCaption/Resource").visible = chapter in [1, 2] and draft.is_empty()
	get_node("Page/Content/ChapterCaption/Resource").text = (str(data.get("power_uses", 0)) + (" / " + str(data.power_uses_total) if data.has("power_uses_total") else "") + " uses remaining") if chapter == 1 else str(data.get("silver", 0)) + " Silver"
	get_node("Page/Content/ChapterCaption/Resource").icon = preload("res://rookframe/ui/icons/character/palms.svg") if chapter == 1 else null
	get_node("Page/Content/ChapterCaption/SilverEditField/Editor").visible = chapter == 2 and not draft.is_empty()
	_setting_resource = true
	get_node("Page/Content/ChapterCaption/SilverEditField/Editor").text = str(draft.get("silver", ""))
	get_node("Page/Content/ChapterCaption/PowerEditField/Editor").visible = chapter == 1 and not draft.is_empty()
	get_node("Page/Content/ChapterCaption/PowerEditField/Editor").text = str(draft.get("power_uses", ""))
	_setting_resource = false
	get_node("Page/Content/ChapterCaption/PersonalNotes").visible = chapter == 3
	get_node("Page/Content/ChapterCaption/InventoryFilters").visible = chapter == 2
	for index in range(4):
		get_node(["Page/Content/ChapterCaption/InventoryFilters/All", "Page/Content/ChapterCaption/InventoryFilters/Arms", "Page/Content/ChapterCaption/InventoryFilters/Supplies", "Page/Content/ChapterCaption/InventoryFilters/Ready"][index]).set_pressed_no_signal(filter == index)

func capture_pages(pages: Dictionary, chapter: int) -> Dictionary:
	pages[str(chapter) + ":primary"] = get_node("Page/Content/Collections/Primary").capture_state()
	pages[str(chapter) + ":resources"] = get_node("Page/Content/Collections/Secondary/Content/Resources").capture_state()
	pages[str(chapter) + ":companions"] = get_node("Page/Content/Collections/Secondary/Content/Companions").capture_state()
	pages[str(chapter) + ":story"] = get_node("Page/Content/JournalPanel/Story").capture_state()
	pages[str(chapter) + ":notes"] = get_node("Page/Content/JournalPanel/Notes").capture_state()
	return pages

func restore_pages(pages: Dictionary, chapter: int) -> void:
	var primary: Dictionary = pages.get(str(chapter) + ":primary", {})
	get_node("Page/Content/Collections/Primary").restore_state(primary)
	var resources: Dictionary = pages.get(str(chapter) + ":resources", {})
	get_node("Page/Content/Collections/Secondary/Content/Resources").restore_state(resources)
	var companions: Dictionary = pages.get(str(chapter) + ":companions", {})
	get_node("Page/Content/Collections/Secondary/Content/Companions").restore_state(companions)
	var story: Dictionary = pages.get(str(chapter) + ":story", {})
	get_node("Page/Content/JournalPanel/Story").restore_state(story)
	var notes: Dictionary = pages.get(str(chapter) + ":notes", {})
	get_node("Page/Content/JournalPanel/Notes").restore_state(notes)

func configure_journal(story: Array[Dictionary], notes: Array[Dictionary]) -> void:
	_story = story
	_notes = notes

func focus_entry(id: String) -> bool:
	for path in ["Collections/Primary", "Collections/Secondary/Content/Resources", "Collections/Secondary/Content/Companions", "JournalPanel/Story", "JournalPanel/Notes"]:
		if get_node("Page/Content/" + path).focus_entry(id):
			return true
	return false

func configure_route(view: Dictionary, data: Dictionary, draft: Dictionary, navigation: Dictionary) -> void:
	var chapter: int = view.chapter
	var phone: bool = view.phone
	var tablet: bool = view.tablet
	var details: bool = view.details
	var modal: bool = view.modal
	var condition_reference: bool = view.condition_reference
	var editing: bool = view.editing
	var _chapter_tabs = get_node(^"Tabs")
	var _chapter_collections = get_node(^"Page/Content/Collections")
	var _chapter_journal_panel = get_node(^"Page/Content/JournalPanel")
	var _condition_ui = get_node(^"Page/Content/Condition")
	var _section = get_node(^"Page/Content/Section")
	var _quick = _route_quick
	var _chapter_primary = get_node(^"Page/Content/Collections/Primary")
	var _chapter_secondary = get_node(^"Page/Content/Collections/Secondary")
	var _chapter_resources = get_node(^"Page/Content/Collections/Secondary/Content/Resources")
	var _chapter_companions = get_node(^"Page/Content/Collections/Secondary/Content/Companions")
	var _chapter_caption = get_node(^"Page/Content/ChapterCaption")
	var _chapter_story = get_node(^"Page/Content/JournalPanel/Story")
	var _chapter_notes = get_node(^"Page/Content/JournalPanel/Notes")
	var obscured := details and not modal
	_chapter_tabs.visible = not obscured
	_chapter_collections.visible = not obscured and chapter in [0, 1, 2]
	_chapter_journal_panel.visible = not obscured and chapter == 3
	get_node(^"Page/Content/AppearanceIntro").visible = false
	get_node(^"Page/Content/AppearanceStatus").visible = not obscured and chapter == 4
	_condition_ui.visible = not obscured and chapter == 0 and not condition_reference and not preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_projection.gd").new().condition(data).is_empty()
	_section.visible = phone and not details and chapter in [0, 1, 2, 3]
	_quick.visible = phone and not details and chapter != 4 and not _condition_ui.visible
	_section.clear()
	for title in (["Features & traits", "Resources", "Companions"] if chapter == 0 else ["Powers", "Decoctions & resources"] if chapter == 1 else ["All belongings", "Arms", "Supplies", "Equipped"] if chapter == 2 else ["All", "Story", "Notes"]):
		_section.add_item(str(title))
	for index in range(_section.item_count):
		_section.set_item_icon(index, [preload("res://rookframe/ui/icons/character/character.svg"), preload("res://rookframe/ui/icons/character/palms.svg"), preload("res://rookframe/ui/icons/character/bag.svg"), preload("res://rookframe/ui/icons/character/book.svg")][mini(chapter, 3)])
	_section.select(mini(int(navigation.get("inventory_filter", 0) if chapter == 2 else navigation.get("section", 0)), _section.item_count - 1))
	_chapter_primary.visible = chapter == 2 or not phone or _section.selected == 0
	_chapter_secondary.visible = chapter == 0 and (not phone or _section.selected != 0) or chapter == 1 and phone and _section.selected == 1
	_chapter_resources.visible = not phone or _section.selected == 1
	_chapter_companions.visible = chapter == 0 and (condition_reference or preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_projection.gd").new().condition(data).is_empty()) and (not phone or _section.selected == 2)
	if phone and _condition_ui.visible:
		_chapter_collections.visible = false
		_section.visible = false
	get_node(^"Page/Content/ReferenceBack").visible = phone and condition_reference and not details and chapter == 0
	var resource_editor = get_node(^"Page/Content/Collections/Secondary/Content/ResourceEditors")
	resource_editor.visible = editing and chapter == 0 and (not phone or _section.selected == 1)
	resource_editor.configure(draft, phone, tablet)
	_chapter_resources.visible = _chapter_resources.visible and not (chapter == 0 and editing)
	configure_caption(chapter, phone, int(navigation.get("inventory_filter", 0)), data, draft if editing else {}, int(navigation.get("section", 0)))
	_chapter_caption.visible = not obscured and not phone and chapter in [1, 2, 3]
	_chapter_story.visible = not phone or _section.selected < 2
	_chapter_notes.visible = not phone or _section.selected == 2
