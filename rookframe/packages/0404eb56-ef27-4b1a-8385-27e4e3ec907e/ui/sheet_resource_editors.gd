extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/token_box.gd"
signal changed(field: String, value: String)
var _setting := false
const EDITORS := {"hit_points": "Pages/Area/Rows/HP/Row/Editors/hit_points/Editor",
"maximum_hit_points": "Pages/Area/Rows/HP/Row/Editors/maximum_hit_points/Editor",
"omens": "Pages/Area/Rows/Omens/Row/Editors/omens/Editor",
"power_uses": "Pages/Area/Rows/Powers/Row/Editors/power_uses/Editor",
"silver": "Pages/Area/Rows/Silver/Row/Editors/silver/Editor"}

## The resource pictograms take the World theme's ornament color.
const ORNAMENTS := [^"Pages/Area/Rows/HP/Row/Icon", ^"Pages/Area/Rows/Omens/Row/Icon", ^"Pages/Area/Rows/Powers/Row/Icon", ^"Pages/Area/Rows/Silver/Row/Icon"]

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		for path in ORNAMENTS:
			(get_node(path) as Control).self_modulate = get_theme_color(&"ornament", TOKENS)

func _ready() -> void:
	for field in ["hit_points", "maximum_hit_points", "omens", "power_uses", "silver"]:
		get_node(EDITORS.get(str(field), "Pages/Area/Rows/HP/Row/Editors/hit_points/Editor")).text_changed.connect(_typed.bind(str(field)))
	var pager = get_node("Pages").get_pager()
	get_node("Footer").add_child(pager)

func _typed(value: String, field: String) -> void:
	if not _setting:
		changed.emit(field, value)

func get_footer_slot() -> HBoxContainer:
	return get_node("Footer")

func configure(values: Dictionary, phone: bool, tablet: bool) -> void:
	_setting = true
	for field in ["hit_points", "maximum_hit_points", "omens", "power_uses", "silver"]:
		get_node(EDITORS.get(str(field), "Pages/Area/Rows/HP/Row/Editors/hit_points/Editor")).text = str(values.get(str(field), ""))
		(get_node(EDITORS.get(str(field), "Pages/Area/Rows/HP/Row/Editors/hit_points/Editor") + "/Caption") as Control).add_theme_font_size_override("font_size", 9 if phone or tablet else 11)
	# The hit point pair shares the narrow column's row, so each native editor
	# reserves two digits there. The UI Kit Input has no narrow width.
	for field in ["hit_points", "maximum_hit_points"]:
		get_node(EDITORS.get(str(field), "Pages/Area/Rows/HP/Row/Editors/hit_points/Editor")).add_theme_constant_override("minimum_character_width", 2 if phone or tablet else 4)
	for path in ["Pages/Area/Rows/HP", "Pages/Area/Rows/Omens", "Pages/Area/Rows/Powers", "Pages/Area/Rows/Silver"]:
		var row = get_node(path)
		row.custom_minimum_size = Vector2(row.custom_minimum_size.x, 56 if phone else 64)
		(get_node(path + "/Row") as Control).set(&"gap", &"space_1" if phone else &"space_2" if tablet else &"space_3")
		(get_node(path + "/Row/Icon") as Control).custom_minimum_size = Vector2(24, 24) if phone or tablet else Vector2(28, 28)
		(get_node(path + "/Row/Editors") as Control).custom_minimum_size = Vector2(140 if phone else 110 if tablet else 120, (get_node(path + "/Row/Editors") as Control).custom_minimum_size.y)
		for edge in ["left", "right", "top", "bottom"]:
			row.set(edge, &"space_1" if phone else &"space_2" if tablet or edge in ["top", "bottom"] else &"space_3")
	get_node("Caption").visible = not phone
	get_node("Caption").custom_minimum_size = Vector2(get_node("Caption").custom_minimum_size.x, 32 if tablet else 39)
	get_node("Pages").refresh()
	_setting = false
