extends PanelContainer
## One rule of a Creature: heading, copy and its roll or correction actions.
##
## The card frame is a hairline under the card, built from `RookframeTokens`.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const TYPE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_type.gd")
var _type := TYPE.new()
const TOKENS := &"RookframeTokens"
signal requested(part: String, id: String)
const CELL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_resolution_cell.tscn")
const ACTION = preload("res://rookframe/ui/components/actions/button.tscn")
var entry_id := ""
var _buttons := []
var _parts: Array[String] = []
var _tablet := false
var _phone := false
var _actions := false
var _frame := StyleBoxFlat.new()
var _reading := false

func _init() -> void:
	add_theme_stylebox_override(&"panel", _frame)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()

# Changing the override's StyleBox notifies this Control of a theme change, so
# the read guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	var padding := get_theme_constant(&"space_1" if _phone else &"space_3" if _tablet else &"space_4", TOKENS)
	_frame.bg_color = Color(0, 0, 0, 0)
	_frame.border_color = get_theme_color(&"divider", TOKENS)
	# The rule above the actions already closes a card that ends with them.
	_frame.border_width_bottom = 0 if _actions else get_theme_constant(&"border_width", TOKENS)
	_frame.content_margin_top = padding
	_frame.content_margin_bottom = 0 if _actions else padding
	_reading = false

func configure(entry: Dictionary, locale: I18N, phone: bool, tablet: bool, _compact_boss: bool = false) -> void:
	_tablet = tablet
	_phone = phone
	entry_id = str(entry.get("id", ""))
	var heading: Label = get_node("Content/Heading")
	var copy: Label = get_node("Content/Copy")
	heading.text = locale.text(str(entry.get("name", "")))
	copy.text = locale.text(str(entry.get("text", "")))
	heading.visible = not heading.text.is_empty()
	copy.visible = not copy.text.is_empty()
	_type.apply(heading, "RuleTitle", phone, tablet)
	_type.apply(copy, "RuleCopy", phone, tablet)
	get_node("Content").set(&"gap", &"space_1" if phone else &"space_2")
	get_node("Content/Resolution").visible = false
	_actions = false
	_read_tokens()

func configure_actions(actions: Array, locale: I18N, phone: bool) -> void:
	_buttons.clear()
	_parts.clear()
	var host := get_node("Content/Resolution/Actions")
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	host.set(&"gap_horizontal", &"space_2" if phone else &"space_3")
	for raw in actions:
		var action: Dictionary = raw
		var button: Button
		if action.has("dice"):
			button = CELL.instantiate()
		else:
			var plain := ACTION.instantiate()
			plain.compact = true
			button = plain
		host.add_child(button)
		var caption := locale.text(str(action.get("name", "")))
		var value := str(action.get("dice", ""))
		if action.has("dice"):
			var passive := bool(action.get("reference", false))
			var caption_label: Label = button.get_node("Inset/Row/Copy/Caption")
			var value_label: Label = button.get_node("Inset/Row/Copy/Value")
			caption_label.text = caption
			value_label.text = "1" + value if value.begins_with("d") and not value.contains("/") else value
			(button.get_node("Inset/Row/Icon") as TextureRect).visible = not passive
			_type.apply(caption_label, "Caption", phone, _tablet)
			_type.apply(value_label, "Value", phone, _tablet)
			var inset: MarginContainer = button.get_node("Inset")
			inset.minimum_size_changed.connect(_queue_fit_cell.bind(button))
			_queue_fit_cell(button)
			button.disabled = passive or bool(action.get("disabled", false))
		else:
			button.text = caption
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_actions = not actions.is_empty()
	get_node("Content/Resolution").visible = _actions
	_read_tokens()

func _queue_fit_cell(button: Button) -> void:
	_fit_cell.call_deferred(button)

func _fit_cell(button: Button) -> void:
	if not is_instance_valid(button):
		return
	# The Button is an indivisible pager item. Let its authored Containers fit
	# the complete wrapped value, retaining the normal row and all its padding.
	var inset: MarginContainer = button.get_node("Inset")
	var height := maxf(44.0, inset.get_combined_minimum_size().y)
	if button.custom_minimum_size.y != height:
		button.custom_minimum_size = Vector2(44, height)

func _action_requested(part: String) -> void:
	requested.emit(part, entry_id)

func restore_focus(part: String = "") -> bool:
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if (part.is_empty() or _parts[index] == part) and button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return true
	return false
