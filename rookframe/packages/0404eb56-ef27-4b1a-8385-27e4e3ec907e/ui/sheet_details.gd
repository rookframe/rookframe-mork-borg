extends VBoxContainer
signal back_requested
signal close_requested
signal save_requested
signal cancel_requested
## Retain the reading position while the same entry receives World updates.
const ENTRY_FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_entry_field.gd")
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
	_pager_slot.add_child(pager)

func _back() -> void:
	back_requested.emit()

func _close() -> void:
	close_requested.emit()

func _save() -> void:
	save_requested.emit()

func _cancel() -> void:
	cancel_requested.emit()

func configure_layout(phone: bool, tablet: bool, task: bool, draft: bool, reading: bool) -> void:
	_phone = phone
	_tablet = tablet
	_task = task
	_draft = draft
	_reading = reading
	get_node(^"HeaderFrame").visible = not task
	get_node(^"HeaderFrame").custom_minimum_size = Vector2(0, 46 if phone else 63)
	get_node(^"HeaderFrame/Inset/DetailHeader/Close").visible = not phone
	get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle").add_theme_font_size_override("font_size", 17 if phone else 22)
	for edge in ["top", "bottom"]:
		get_node(^"HeaderFrame/Inset").add_theme_constant_override("margin_" + edge, 1 if phone else 9)
	get_node(^"HeaderFrame/Inset").add_theme_constant_override("margin_left", 5)
	get_node(^"HeaderFrame/Inset").add_theme_constant_override("margin_right", 7)
	get_node(^"TabsFrame/Inset/DetailTabs").add_theme_constant_override("separation", 5 if phone else 8)
	for path in [^"TabsFrame/Inset/DetailTabs/Overview", ^"TabsFrame/Inset/DetailTabs/Details"]:
		get_node(path).custom_minimum_size = Vector2(44, 44 if phone else 48)
	var horizontal := 16 if draft and phone else 24 if draft else 20 if phone and reading else 18 if phone or (tablet and reading) else 24 if reading else 26
	var vertical := 12 if phone else 24 if draft or (reading and not tablet) else 20 if reading else 22
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Body").add_theme_constant_override("margin_" + edge, 0 if task else horizontal if edge in ["left", "right"] else vertical)
	get_node(^"Body/DetailPages/Area/DetailContent").add_theme_constant_override("separation", 12 if phone else 16 if draft else 22)
	_actions.vertical = not phone and not draft and not task
	_actions.add_theme_constant_override("separation", 16 if phone else 7)
	(_draft_actions as Control).visible = draft and not task
	(_primary_action as Control).custom_minimum_size = Vector2(44, 44 if phone or draft or task else 48)
	(_primary_action as Control).size_flags_horizontal = 1 if task or draft else 3
	get_node(^"FooterFrame").visible = not task
	get_node(^"FooterFrame").theme_type_variation = "TaskFooterPhone" if phone else "TaskFooter"
	get_node(^"FooterFrame/FooterInset").custom_minimum_size = Vector2(0, 60 if phone else 68 if draft else 118 if (_primary_action as Control).visible else 60)
	get_node(^"FooterFrame/FooterInset").add_theme_constant_override("margin_top", 7 if phone else 8)
	get_node(^"FooterFrame/FooterInset").add_theme_constant_override("margin_bottom", 7 if phone else 8)

func register_field(field: ENTRY_FIELD) -> void:
	_editors.append(field)

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
	_fit_title.call_deferred()
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
	label.autowrap_mode = 3 # TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = 3 # Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 17 if phone else 18 if _tablet and _reading else 20)
	label.add_theme_constant_override("line_spacing", 8 if phone else 9 if _tablet else 10)
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(label)

func append_option(text: String, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.accessibility_name = button.text
	button.clip_text = true
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(0, 44)
	button.theme_type_variation = "TaskButton"
	button.text_overrun_behavior = 3 # TextServer.OVERRUN_TRIM_ELLIPSIS
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(button)
	return button

func group_fields(fields: Array, weights: Array) -> void:
	_field_names = fields
	var row = FIELD_ROW.instantiate()
	get_node(^"Body/DetailPages/Area/DetailContent").add_child(row)
	row.configure(weights, fields.size())
	row.add_theme_constant_override("separation", 12 if _phone else 16)
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
