extends VBoxContainer
## Oversized names remain complete native paginated text above a contextual action.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal requested(part: String, id: String)
var entry_id := ""

func _ready() -> void:
	get_node("Summary").requested.connect(_requested)
	get_node("Summary").full_name_needed.connect(_show_full_name)

func configure(item: Dictionary, locale: I18N, phone: bool, tablet: bool) -> void:
	entry_id = str(item.get("inventory_id", ""))
	get_node("Summary").configure(item, locale, phone, tablet)
	get_node("FullName").text = get_node("Summary/Padding/Row/Identity/Name").text
	get_node("FullName").add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)

func set_page_height(height: float) -> void:
	get_node("Summary").set_page_height(height)

func _show_full_name() -> void:
	get_node("FullName").visible = true

func _requested(part: String, id: String) -> void:
	requested.emit(part, id)

func restore_focus(part: String = "") -> bool:
	return get_node("Summary").restore_focus(part)
