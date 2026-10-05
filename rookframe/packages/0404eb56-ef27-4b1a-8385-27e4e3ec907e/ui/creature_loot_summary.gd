extends Button
## One ordinary button keeps a loot summary and its Details action on the same page.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal requested(part: String, id: String)
signal full_name_needed
var entry_id := ""
var _measurement_pending := false
var page_height := 0.0
var _compact := false
var _horizontal_padding := 0

func _ready() -> void:
	pressed.connect(_details)
	get_node("Padding").resized.connect(_queue_measure)
	resized.connect(_queue_measure)
	_queue_measure()

func configure(item: Dictionary, locale: I18N, phone: bool, tablet: bool) -> void:
	entry_id = str(item.get("inventory_id", ""))
	var title := str(item.get("name", "Item"))
	if not item.get("custom", false):
		title = locale.text(title)
	var summary := str(item.get("quantity", 1)) + " × " + locale.text(str(item.get("kind", "Item")))
	get_node("Padding/Row/Identity/Name").text = title
	get_node("Padding/Row/Identity/CompactName").text = title
	get_node("Padding/Row/Identity/Summary").text = summary
	get_node("Padding/Row/Details").text = locale.text("Details")
	get_node("Padding/Row/Identity/Name").add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	get_node("Padding/Row/Identity/CompactName").add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	get_node("Padding/Row/Identity/Summary").add_theme_font_size_override("font_size", 13 if phone or tablet else 17)
	get_node("Padding/Row/Identity/Summary").add_theme_constant_override("line_spacing", 2 if phone else 3 if tablet else 4)
	get_node("Padding/Row/Details").add_theme_font_size_override("font_size", 11 if phone else 12 if tablet else 14)
	get_node("Padding/Row/Identity").add_theme_constant_override("separation", 4 if phone else 5 if tablet else 7)
	var horizontal := 2 if phone else 3 if tablet else 7
	_horizontal_padding = horizontal
	var vertical := 8 if phone else 10 if tablet else 14
	for edge in ["left", "right"]:
		get_node("Padding").add_theme_constant_override("margin_" + edge, horizontal)
	get_node("Padding").add_theme_constant_override("margin_top", vertical)
	get_node("Padding").add_theme_constant_override("margin_bottom", vertical + 1)
	accessibility_name = title + ". " + summary + ". " + locale.text("Details")
	_queue_measure()

func _queue_measure() -> void:
	if _measurement_pending:
		return
	_measurement_pending = true
	_measure.call_deferred()

func _measure() -> void:
	_measurement_pending = false
	var padding: MarginContainer = get_node("Padding")
	var content_width := size.x - 2 * _horizontal_padding
	# Native Containers must finish assigning the real width before wrapped height
	# becomes this button's minimum. An initial one-pixel Label is not a page.
	if get_node("Padding/Row").size.x != content_width:
		return
	if page_height <= 0:
		return
	var height := maxf(44.0, padding.get_combined_minimum_size().y)
	if not _compact and height > page_height:
		_compact = true
		get_node("Padding/Row/Identity/Name").visible = false
		get_node("Padding/Row/Identity/CompactName").visible = true
		full_name_needed.emit()
		return
	custom_minimum_size = Vector2(44, height)

func set_page_height(height: float) -> void:
	page_height = height
	_queue_measure()

func _details() -> void:
	requested.emit("details", entry_id)

func restore_focus(_part: String = "") -> bool:
	if not is_visible_in_tree() or disabled:
		return false
	grab_focus()
	return true
