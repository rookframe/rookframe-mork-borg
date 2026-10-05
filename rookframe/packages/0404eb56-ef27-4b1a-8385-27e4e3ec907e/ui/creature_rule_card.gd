extends PanelContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
@export var article_frame: StyleBoxFlat
signal requested(part: String, id: String)
const BUTTON = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_text_button.tscn")
const CELL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_resolution_cell.tscn")
var entry_id := ""
var _buttons := []
var _parts: Array[String] = []
var _tablet := false
var _copy_line_height := 25.5

func _ready() -> void:
	get_node("Content/Copy").resized.connect(_queue_fit_copy)

func _queue_fit_copy() -> void:
	# Measure after native wrapping has accepted the current width and font.
	_fit_copy.call_deferred()

func _fit_copy() -> void:
	var copy: Label = get_node("Content/Copy")
	var height := copy.get_line_count() * _copy_line_height
	if copy.custom_minimum_size.y != height:
		copy.custom_minimum_size = Vector2(0, height)

func configure(entry: Dictionary, locale: I18N, phone: bool, tablet: bool, compact_boss: bool = false) -> void:
	_tablet = tablet
	_copy_line_height = 18.85 if phone else 19.5 if tablet else 25.5
	entry_id = str(entry.get("id", ""))
	var heading: Label = get_node("Content/Heading")
	var copy: Label = get_node("Content/Copy")
	heading.text = locale.text(str(entry.get("name", "")))
	copy.text = locale.text(str(entry.get("text", "")))
	heading.add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	heading.visible = not heading.text.is_empty()
	copy.visible = not copy.text.is_empty()
	copy.add_theme_font_size_override("font_size", 13 if phone or tablet else 17)
	copy.add_theme_constant_override("line_spacing", 2 if phone else 3 if tablet else 4)
	_queue_fit_copy()
	get_node("Content/HeadingGap").visible = heading.visible and copy.visible
	get_node("Content/HeadingGap").custom_minimum_size = Vector2(0, 4 if phone else 5 if tablet else 7)
	get_node("Content/ResolutionGap").custom_minimum_size = Vector2(0, 7 if phone else 8 if tablet else 10)
	var frame: StyleBoxFlat = article_frame.duplicate()
	frame.content_margin_left = 2 if phone else 3 if tablet else 7
	frame.content_margin_right = frame.content_margin_left
	frame.content_margin_top = 8 if phone else 10 if tablet else 8 if compact_boss else 14
	frame.content_margin_bottom = frame.content_margin_top + 1
	add_theme_stylebox_override("panel", frame)
	get_node("Content/Resolution").visible = false
	get_node("Content/ResolutionGap").visible = false

func configure_actions(actions: Array, locale: I18N, phone: bool) -> void:
	_buttons.clear()
	_parts.clear()
	var host := get_node("Content/Resolution/Actions")
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	host.add_theme_constant_override("h_separation", 10 if phone else 8 if _tablet else 14)
	for raw in actions:
		var action: Dictionary = raw
		var button: Button = CELL.instantiate() if action.has("dice") else BUTTON.instantiate()
		host.add_child(button)
		var caption := locale.text(str(action.get("name", "")))
		var value := str(action.get("dice", ""))
		if action.has("dice"):
			var passive := bool(action.get("reference", false))
			# Desktop copy uses native 14px + 27px rows and 6px padding per side.
			button.custom_minimum_size = Vector2(44, 48 if phone else 50 if _tablet else 53)
			(button.get_node("Inset/Row/Copy/Caption") as Label).text = caption
			(button.get_node("Inset/Row/Copy/Caption") as Label).add_theme_font_size_override("font_size", 10 if phone or _tablet else 11)
			(button.get_node("Inset/Row/Copy/Value") as Label).text = "1" + value if value.begins_with("d") and not value.contains("/") else value
			(button.get_node("Inset/Row/Copy/Value") as Label).add_theme_font_size_override("font_size", 18 if phone else 17 if _tablet else 21)
			(button.get_node("Inset/Row/Copy/Value") as Label).add_theme_color_override("font_color", Color(0.85098, 0.831373, 0.819608, 1) if passive else Color(0.266667, 0.913725, 0.913725, 1))
			(button.get_node("Inset/Row/Icon") as TextureRect).visible = not passive
			var icon_size := 16 if phone else 15 if _tablet else 18
			(button.get_node("Inset/Row/Icon") as TextureRect).custom_minimum_size = Vector2(icon_size, icon_size)
			(button.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_top", 4 if phone else 5 if _tablet else 6)
			(button.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_bottom", 4 if phone else 5 if _tablet else 6)
			(button.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_left", 2 if phone or _tablet else 4)
			(button.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_right", 2 if phone or _tablet else 4)
			var minimum_height := button.custom_minimum_size.y
			var value_label: Label = button.get_node("Inset/Row/Copy/Value")
			value_label.resized.connect(_queue_fit_cell.bind(button, minimum_height))
			_queue_fit_cell(button, minimum_height)
			button.disabled = passive or bool(action.get("disabled", false))
		else:
			button.text = caption
			button.custom_minimum_size = Vector2(44,44)
			button.add_theme_font_size_override("font_size", 11 if phone else 14)
			button.disabled = bool(action.get("disabled", false))
		button.accessibility_name = get_node("Content/Heading").text + ": " + caption + " " + value
		button.pressed.connect(_action_requested.bind(str(action.get("part", "details"))))
		_buttons.append(button)
		_parts.append(str(action.get("part", "details")))
	# An ordinary one-cell resolution still occupies the first half of its row.
	if actions.size() % 2 == 1:
		var space := Control.new()
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.add_child(space)
	get_node("Content/Resolution").visible = not actions.is_empty()
	get_node("Content/ResolutionGap").visible = not actions.is_empty()

func _queue_fit_cell(button: Button, minimum_height: float) -> void:
	_fit_cell.call_deferred(button, minimum_height)

func _fit_cell(button: Button, minimum_height: float) -> void:
	if not is_instance_valid(button):
		return
	# The Button is an indivisible pager item. Let its authored Containers fit
	# the complete wrapped value, retaining the normal row and all its padding.
	var inset: MarginContainer = button.get_node("Inset")
	button.custom_minimum_size = Vector2(44, maxf(minimum_height, inset.get_combined_minimum_size().y))

func _action_requested(part: String) -> void:
	requested.emit(part, entry_id)

func restore_focus(part: String = "") -> bool:
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if (part.is_empty() or _parts[index] == part) and button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return true
	return false
