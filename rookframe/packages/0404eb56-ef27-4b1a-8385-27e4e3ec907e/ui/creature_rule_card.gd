extends VBoxContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal requested(part: String, id: String)
const BUTTON = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_text_button.tscn")
var entry_id := ""
var _buttons := []
var _parts: Array[String] = []

func configure(entry: Dictionary, locale: I18N, phone: bool, tablet: bool) -> void:
	entry_id = str(entry.get("id", ""))
	get_node("Heading").text = locale.text(str(entry.get("name", "")))
	get_node("Copy").text = locale.text(str(entry.get("text", "")))
	get_node("Heading").add_theme_font_size_override("font_size", 17 if phone else 20 if tablet else 24)
	get_node("Copy").add_theme_font_size_override("font_size", 13 if phone else 15 if tablet else 18)
	add_theme_constant_override("separation", 6 if phone else 8)
	get_node("Actions").visible = false

func configure_actions(actions: Array, locale: I18N, phone: bool) -> void:
	_buttons.clear()
	_parts.clear()
	for child in get_node("Actions").get_children():
		get_node("Actions").remove_child(child)
		child.queue_free()
	for raw in actions:
		var action: Dictionary = raw
		var button := BUTTON.instantiate()
		button.text = locale.text(str(action.get("name", ""))) + (" · " + str(action.get("dice", "")) if action.has("dice") else "")
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_font_size_override("font_size", 11 if phone else 14)
		button.accessibility_name = get_node("Heading").text + ": " + button.text
		button.disabled = bool(action.get("disabled", false))
		button.pressed.connect(_action_requested.bind(str(action.get("part", "details"))))
		get_node("Actions").add_child(button)
		_buttons.append(button)
		_parts.append(str(action.get("part", "details")))
	get_node("Actions").visible = not actions.is_empty()

func _action_requested(part: String) -> void:
	requested.emit(part, entry_id)

func restore_focus(part: String = "") -> bool:
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if (part.is_empty() or _parts[index] == part) and button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return true
	return false
