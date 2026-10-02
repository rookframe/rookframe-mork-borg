extends VBoxContainer
## Retain the reading position while the same entry receives World updates.
const FIELD_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field_row.tscn")
var _field_row: Control
var _field_names: Array = []
var _identity := ""
var _paging: Dictionary = {}
var _focus_name := ""

func _ready() -> void:
	get_node(^"DetailHeader/DetailTitle").resized.connect(_fit_title)

func reset_navigation() -> void:
	_identity = ""

func refresh_pages() -> void:
	get_node(^"DetailPages").refresh()

func begin_content(identity: String) -> void:
	_field_names = []
	_field_row = null
	_paging = get_node(^"DetailPages").capture_state() if identity == _identity else {}
	_focus_name = ""
	if identity == _identity:
		for child in get_node(^"DetailPages/Area/DetailContent").get_children():
			if child is Control:
				var control := child as Control
				if control.has_focus():
					_focus_name = control.accessibility_name
	_identity = identity
	for child in get_node(^"DetailPages/Area/DetailContent").get_children():
		if str(child.name) != "FullTitle":
			get_node(^"DetailPages/Area/DetailContent").remove_child(child)
			child.queue_free()

func finish_content(full_title: String) -> void:
	var title = get_node(^"DetailPages/Area/DetailContent/FullTitle")
	title.text = full_title
	title.add_theme_font_size_override("font_size", 14 if get_viewport_rect().size.y <= 560 else 18)
	_fit_title.call_deferred()
	get_node(^"DetailPages").restore_state(_paging)
	_restore_focus.call_deferred()

func _fit_title() -> void:
	get_node(^"DetailPages/Area/DetailContent/FullTitle").visible = not get_node(^"DetailPages/Area/DetailContent/FullTitle").text.is_empty() and get_node(^"DetailHeader/DetailTitle").get_line_count() > 1
	get_node(^"DetailPages").refresh()

func _restore_focus() -> void:
	if _focus_name.is_empty():
		return
	for child in get_node(^"DetailPages/Area/DetailContent").get_children():
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
	label.add_theme_font_size_override("font_size", 14 if phone else 18)
	get_node(^"DetailPages/Area/DetailContent").add_child(label)

func append_option(text: String, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.accessibility_name = button.text
	button.clip_text = true
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(0, 44)
	button.theme_type_variation = "TaskButton"
	button.text_overrun_behavior = 3 # TextServer.OVERRUN_TRIM_ELLIPSIS
	get_node(^"DetailPages/Area/DetailContent").add_child(button)
	return button

func group_fields(fields: Array, weights: Array) -> void:
	_field_names = fields
	var row = FIELD_ROW.instantiate()
	get_node(^"DetailPages/Area/DetailContent").add_child(row)
	row.configure(weights, fields.size())
	_field_row = row

func field_host(field: String) -> Control:
	for index in range(_field_names.size()):
		if str(_field_names[index]) == field:
			return _field_row.slot(index)
	return get_node(^"DetailPages/Area/DetailContent")


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
