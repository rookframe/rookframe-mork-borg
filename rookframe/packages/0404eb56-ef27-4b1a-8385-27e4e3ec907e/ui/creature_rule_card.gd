extends VBoxContainer
signal requested(part: String, id: String)
const BUTTON = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_text_button.tscn")
var entry_id := ""

func configure(entry: Dictionary, locale: RefCounted, phone: bool, tablet: bool, actions: Array = []) -> void:
	entry_id = str(entry.get("id", ""))
	get_node("Heading").text = locale.text(str(entry.get("name", "")))
	get_node("Copy").text = locale.text(str(entry.get("text", "")))
	get_node("Heading").add_theme_font_size_override("font_size", 17 if phone else 20 if tablet else 24)
	get_node("Copy").add_theme_font_size_override("font_size", 13 if phone else 15 if tablet else 18)
	add_theme_constant_override("separation", 6 if phone else 8)
	for child in get_node("Actions").get_children():
		get_node("Actions").remove_child(child)
		child.queue_free()
	for action in actions:
		var button := BUTTON.instantiate()
		button.text = locale.text(str(action.get("name", ""))) + (" · " + str(action.get("dice", "")) if action.has("dice") else "")
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_font_size_override("font_size", 11 if phone else 14)
		button.accessibility_name = get_node("Heading").text + ": " + button.text
		button.disabled = action.get("disabled", false)
		button.pressed.connect(func(): requested.emit(str(action.get("part", "details")), entry_id))
		get_node("Actions").add_child(button)
	get_node("Actions").visible = not actions.is_empty()
