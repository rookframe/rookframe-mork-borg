extends VBoxContainer
signal back_requested
signal close_requested
signal save_requested
signal cancel_requested
## Retain the reading position while the same entry receives World updates.
const ENTRY_FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_entry_field.gd")
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
const TOKEN_BOX = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/token_box.gd")
const FIELD_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field_row.tscn")
var _field_row: Control
var _field_names: Array = []
var _identity := ""
var _paging: Dictionary = {}
var _restore_page := false
var _focus_name := ""
var _phone := false
var _tablet := false
var _task := false
var _draft := false
var _reading := false
var _note_editing := false
var _title_fit_frames := 0
var _editors: Array[ENTRY_FIELD] = []
var _focused_field := ""
@onready var _actions = get_node(^"FooterFrame/FooterInset/DetailActions")
@onready var _save_button = get_node(^"FooterFrame/FooterInset/DetailActions/Draft/Save")
@onready var _cancel_button = get_node(^"FooterFrame/FooterInset/DetailActions/Draft/Cancel")
@onready var _pager_slot = get_node(^"FooterFrame/FooterInset/DetailActions/Utility/PagerSlot")
@onready var _draft_actions = get_node(^"FooterFrame/FooterInset/DetailActions/Draft")
@onready var _primary_action = get_node(^"FooterFrame/FooterInset/DetailActions/PrimaryAction")

func _ready() -> void:
	get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle").resized.connect(_fit_title)
	get_node(^"HeaderFrame/Inset/DetailHeader/Close").pressed.connect(_close)
	(_save_button as Button).pressed.connect(_save)
	(_cancel_button as Button).pressed.connect(_cancel)
	var pager = get_node(^"Body/DetailPages").get_pager()
	pager.size_flags_horizontal = 3
	_pager_slot.add_child(pager)
	var note_pager = get_node(^"Body/NoteEditor").get_pager()
	_pager_slot.add_child(note_pager)
	get_node(^"Body/NoteEditor").value_changed.connect(_changed)

func _process(_delta: float) -> void:
	if _title_fit_frames > 0:
		_title_fit_frames -= 1
		if _title_fit_frames == 0:
			_fit_title()

func _back() -> void:
	back_requested.emit()

func _close() -> void:
	close_requested.emit()

func _save() -> void:
	save_requested.emit()

func _cancel() -> void:
	cancel_requested.emit()

func configure_layout(phone: bool, tablet: bool, task: bool, draft: bool, reading: bool) -> void:
	SHEET_TOKENS.gap(self, &"")
	_phone = phone
	_tablet = tablet
	_task = task
	_draft = draft
	_reading = reading
	get_node(^"Body/DetailPages").always_show_pager = false
	get_node(^"Body/NoteEditor").compact = phone
	get_node(^"Body/NoteEditor").visible = _note_editing
	get_node(^"Body/DetailPages").visible = not _note_editing
	for editor in _editors:
		if is_instance_valid(editor):
			editor.configure_layout(phone)
	get_node(^"HeaderFrame").visible = not task
	get_node(^"HeaderFrame").custom_minimum_size = Vector2(0, 46 if phone else 63)
	get_node(^"HeaderFrame/Inset/DetailHeader/Close").visible = not phone
	get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle").add_theme_font_size_override("font_size", 17 if phone else 22)
	for edge in [&"top", &"bottom"]:
		get_node(^"HeaderFrame/Inset").set(edge, &"" if phone else &"space_2")
	var back: Button = get_node(^"HeaderFrame/Inset/DetailHeader/Back")
	back.custom_minimum_size = Vector2(44, 44)
	(back.get_node(^"Copy/Caption") as Control).visible = false
	get_node(^"TabsFrame/Inset/DetailTabs").set(&"gap", &"space_1" if phone else &"space_2")
	for path in [^"TabsFrame/Inset/DetailTabs/Overview", ^"TabsFrame/Inset/DetailTabs/Details"]:
		get_node(path).custom_minimum_size = Vector2(44, 44 if phone else 48)
	var horizontal := &"space_4" if phone or _note_editing or (tablet and reading and not draft) else &"space_5"
	var vertical := &"space_2" if phone and _note_editing else &"space_3" if phone or _note_editing else &"space_5"
	for edge in [&"left", &"right", &"top", &"bottom"]:
		get_node(^"Body").set(edge, &"" if task else horizontal if edge in [&"left", &"right"] else vertical)
	get_node(^"Body/DetailPages/Area/DetailContent").set(&"gap", &"space_3" if phone else &"space_4" if draft else &"space_5")
	_actions.vertical = false
	_actions.set(&"gap", &"space_4" if phone else &"space_2")
	(_draft_actions as Control).visible = draft and not task
	(_primary_action as Control).custom_minimum_size = Vector2(44, 44 if phone or draft or task else 48)
	(_primary_action as Control).size_flags_horizontal = 0
	(_primary_action as Control).size_flags_vertical = 4
	get_node(^"FooterFrame").visible = not task
	get_node(^"FooterFrame/FooterInset").custom_minimum_size = Vector2(0, 60 if phone else 68)
	for edge in [&"top", &"bottom"]:
		get_node(^"FooterFrame/FooterInset").set(edge, &"space_2")

func append_draft_field(field: String, title: String, value: String, phone: bool) -> ENTRY_FIELD:
	var control = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_entry_field.tscn").instantiate()
	field_host(field).add_child(control)
	control.configure_layout(phone)
	register_field(control)
	control.configure(field, title, value, field in ["description", "origin", "class_rules", "pack"] or field.ends_with(":rules"))
	return control

func register_field(field: ENTRY_FIELD) -> void:
	_editors.append(field)

func sync_draft_field(field: String, text: String) -> void:
	for editor in _editors:
		if editor._field == field:
			editor.sync_draft_value(text)

func paging_state() -> Dictionary:
	return get_node(^"Body/DetailPages").capture_state()

func restore_paging(state: Dictionary) -> void:
	_paging = state
	_restore_page = true

func reset_navigation() -> void:
	_identity = ""

func refresh_pages() -> void:
	get_node(^"Body/DetailPages").refresh()

func begin_content(identity: String) -> void:
	_note_editing = false
	_focused_field = ""
	for editor in _editors:
		if is_instance_valid(editor) and editor.has_editor_focus():
			_focused_field = str(editor._field)
	_editors = []
	_field_names = []
	_field_row = null
	if not _restore_page:
		_paging = get_node(^"Body/DetailPages").capture_state() if identity == _identity else {}
	_restore_page = false
	_focus_name = ""
	if identity == _identity:
		for child in get_node(^"Body/DetailPages/Area/DetailContent").get_children():
			if child is Control:
				var control := child as Control
				if control.has_focus():
					_focus_name = control.accessibility_name
	_identity = identity
	for child in get_node(^"Body/DetailPages/Area/DetailContent").get_children():
		if str(child.name) != "FullTitle":
			get_node(^"Body/DetailPages/Area/DetailContent").remove_child(child)
			child.queue_free()

func finish_content(full_title: String) -> void:
	var title = get_node(^"Body/DetailPages/Area/DetailContent/FullTitle")
	title.text = full_title
	title.add_theme_font_size_override("font_size", 17 if _phone else 18 if _tablet else 20)
	get_node(^"TabsFrame").visible = not _task and get_node(^"TabsFrame/Inset/DetailTabs").visible
	configure_layout(_phone, _tablet, _task, _draft, _reading)
	_title_fit_frames = 2
	get_node(^"Body/DetailPages").restore_state(_paging)
	_restore_focus.call_deferred()

func _fit_title() -> void:
	get_node(^"Body/DetailPages/Area/DetailContent/FullTitle").visible = not get_node(^"Body/DetailPages/Area/DetailContent/FullTitle").text.is_empty() and get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle").get_line_count() > 1
	get_node(^"Body/DetailPages").refresh()

func _restore_focus() -> void:
	for editor in _editors:
		if str(editor._field) == _focused_field:
			editor.restore_editor_focus()
			return
	if _focus_name.is_empty():
		return
	for child in get_node(^"Body/DetailPages/Area/DetailContent").get_children():
		if not child is Control:
			continue
		var control := child as Control
		if control.accessibility_name == _focus_name:
			control.grab_focus()
			return

func append_text(text: String, phone: bool) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = 3 # 3
	label.size_flags_horizontal = 3 # Control.SIZE_EXPAND_FILL
	label.theme_type_variation = &"RookframeBody"
	label.add_theme_font_size_override("font_size", 17 if phone else 18 if _tablet and _reading else 20)
	label.add_theme_constant_override("line_spacing", SHEET_TOKENS.pixels(self, &"line_spacing_body"))
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(label)

func append_summary(caption: String, text: String) -> void:
	var summary := VBoxContainer.new()
	summary.set_script(TOKEN_BOX)
	summary.set(&"gap", &"space_3")
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(summary)
	var heading := Label.new()
	heading.text = caption
	heading.add_theme_font_size_override("font_size", 13 if _phone else 15)
	heading.theme_type_variation = &"RookframeMeta"
	summary.add_child(heading)
	var description := Label.new()
	description.text = text
	description.autowrap_mode = 3
	description.theme_type_variation = &"RookframeBody"
	description.add_theme_font_size_override("font_size", 17 if _phone else 20)
	summary.add_child(description)

func append_option(text: String, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.accessibility_name = button.text
	button.clip_text = true
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(0, 44)
	button.theme_type_variation = &"RookframeSecondaryButton"
	button.text_overrun_behavior = 3 # TextServer.OVERRUN_TRIM_ELLIPSIS
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(button)
	return button

func group_fields(fields: Array, weights: Array) -> void:
	_field_names = fields
	var row = FIELD_ROW.instantiate()
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(row)
	row.configure(weights, fields.size())
	SHEET_TOKENS.gap(row, &"space_3" if _phone else &"space_4")
	if _phone and weights == [1, 2]:
		row.slot(0).custom_minimum_size = Vector2(190, row.slot(0).custom_minimum_size.y)
	_field_row = row

func field_host(field: String) -> Control:
	for index in range(_field_names.size()):
		if str(_field_names[index]) == field:
			return _field_row.slot(index)
	return get_node(^"Body/DetailPages/Area/DetailContent")


func correction_route(field: String) -> String:
	if field in ["name", "description", "origin", "pack", "improvements"]:
		return "profile"
	if field in ["class_title", "class_rules"] or field.begins_with("scum_specialty:"):
		return "class"
	if field in ["Strength", "Agility", "Presence", "Toughness"]:
		return "ability:" + field
	if field.begins_with("trait:") or field.begins_with("companion:"):
		var parts := field.split(":")
		return parts[0] + ":" + parts[1]
	return "resource:" + ("hit_points" if field == "maximum_hit_points" else field)

func append_facts(facts: Array) -> void:
	var content = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_entry_facts.tscn").instantiate()
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(content)
	content.configure(facts, _phone)

func append_item_field(field: String, value: String, phone: bool, independent: bool) -> ENTRY_FIELD:
	var control = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_entry_field.tscn").instantiate()
	field_host(field).add_child(control)
	control.configure_layout(phone)
	register_field(control)
	control.configure(field, field.replace("_", " ").capitalize(), value, field == "rules", independent)
	return control

## The mock's visit-local writing flow. Durable Actor data remains separate.
var journal_draft := ""

func word_count(words: String) -> int:
	var normalized: String = words.replace("\n", " ")
	normalized = normalized.replace("\t", " ")
	var count := 0
	for word in normalized.split(" "):
		if not str(word).is_empty():
			count += 1
	return count

func compose_journal(data: Dictionary, navigation: Dictionary, story: bool, view: int, phone: bool) -> String:
	(get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle") as Label).text = "The road ahead" if story else "In your own words"
	_note_editing = not story and view == 2
	get_node(^"TabsFrame/Inset/DetailTabs").visible = not _note_editing
	if story:
		if view == 1:
			append_text(str(data.get("origin", "The places and words you carry.")), phone)
		else:
			append_summary("Your origin", str(data.get("origin", "The places and words you carry.")))
		return "Write your own story"
	if not _note_editing:
		var words := str(navigation.get("notes", ""))
		if view == 1:
			append_text("No notes yet." if words.is_empty() else words, phone)
		else:
			append_summary("Personal note", "Your personal record of the journey.")
			append_facts([["Length", str(words.length()) + " characters"], ["Stored", "For this visit"]])
		return "Edit note"
	get_node(^"Body/NoteEditor").value = journal_draft
	return "Save note"

func _changed(value: String) -> void:
	journal_draft = value
