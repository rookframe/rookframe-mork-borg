extends VBoxContainer
signal changed(field: String, value: String)
var _setting := false
const EDITORS := {"hit_points": ^"Pages/Area/Rows/HP/Row/Editors/hit_points/Editor",
"maximum_hit_points": ^"Pages/Area/Rows/HP/Row/Editors/maximum_hit_points/Editor",
"omens": ^"Pages/Area/Rows/Omens/Row/Editors/omens/Editor",
"power_uses": ^"Pages/Area/Rows/Powers/Row/Editors/power_uses/Editor",
"silver": ^"Pages/Area/Rows/Silver/Row/Editors/silver/Editor"}

func _ready() -> void:
	for field in EDITORS.keys():
		get_node(EDITORS[field]).text_changed.connect(_typed.bind(str(field)))
	var pager = get_node(^"Pages").get_pager()
	get_node(^"Footer").add_child(pager)

func _typed(value: String, field: String) -> void:
	if not _setting:
		changed.emit(field, value)

func get_footer_slot() -> HBoxContainer:
	return get_node(^"Footer")

func configure(values: Dictionary, phone: bool, tablet: bool) -> void:
	_setting = true
	for field in EDITORS.keys():
		get_node(EDITORS[field]).text = str(values.get(field, ""))
		get_node(EDITORS[field]).add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
		get_node(EDITORS[field]).get_node(^"Caption").add_theme_font_size_override("font_size", 9 if phone or tablet else 11)
	for path in [^"Pages/Area/Rows/HP", ^"Pages/Area/Rows/Omens", ^"Pages/Area/Rows/Powers", ^"Pages/Area/Rows/Silver"]:
		var row = get_node(path)
		row.custom_minimum_size = Vector2(row.custom_minimum_size.x, 56 if phone else 64)
		row.get_node(^"Row").add_theme_constant_override("separation", 6 if phone or tablet else 10)
		row.get_node(^"Row/Icon").custom_minimum_size = Vector2(24, 24) if phone or tablet else Vector2(28, 28)
		row.get_node(^"Row/Editors").custom_minimum_size = Vector2(140 if phone else 110 if tablet else 120, row.get_node(^"Row/Editors").custom_minimum_size.y)
		for edge in ["left", "right", "top", "bottom"]:
			row.add_theme_constant_override("margin_" + edge, 4 if phone else 6 if tablet or edge in ["top", "bottom"] else 10)
	get_node(^"Caption").visible = not phone
	get_node(^"Caption").custom_minimum_size = Vector2(get_node(^"Caption").custom_minimum_size.x, 32 if tablet else 39)
	get_node(^"Pages").refresh()
	_setting = false
