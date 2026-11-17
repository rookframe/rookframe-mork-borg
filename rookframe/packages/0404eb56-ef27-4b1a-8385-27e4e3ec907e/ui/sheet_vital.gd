extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_hint_button.gd"
## The character core keeps the resource caption separate from its value.
# The track is a hairline under the row, so it carries no frame of its own.
var _track := StyleBoxEmpty.new()
var _fill := StyleBoxFlat.new()

func _ready() -> void:
	get_node(^"Health").add_theme_stylebox_override("background", _track)
	get_node(^"Health").add_theme_stylebox_override("fill", _fill)

func configure(caption: String, current: int, suffix: String, maximum: int = 0, phone: bool = false, tablet: bool = false) -> void:
	custom_minimum_size = Vector2(44, 44 if phone else 48 if tablet else 72)
	get_node(^"Inset/Copy/Lines/Caption").text = caption
	get_node(^"Inset/Copy/Lines/Caption").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 17)
	for path in [^"Inset/Copy/Lines/Number/Value", ^"Inset/Copy/Lines/Number/HealthValue", ^"Inset/Copy/Lines/Number/DeadValue"]:
		get_node(path).text = str(current)
		get_node(path).add_theme_font_size_override("font_size", 21 if phone else 24 if tablet else 32)
	get_node(^"Inset/Copy/Lines/Number/Extra").text = suffix
	get_node(^"Inset/Copy/Lines/Number/Extra").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 17)
	var icon_size := &"icon_medium" if phone or tablet else &"icon_large"
	_icon_margins(icon_size, &"space_2" if phone or tablet else &"space_4", &"space_1", &"space_2")
	# Compact rows trim each line box so the caption and number stay together: the
	# lines overlap by the trim, and the copy is that much shorter than its lines.
	var trim_top := 2 if phone or tablet else 4
	var trim_bottom := 3 if phone or tablet else 4
	get_node(^"Inset/Copy").add_theme_constant_override(&"margin_top", -trim_top)
	get_node(^"Inset/Copy").add_theme_constant_override(&"margin_bottom", -trim_bottom)
	get_node(^"Inset/Copy/Lines").add_theme_constant_override(&"separation", -(trim_top + trim_bottom))
	get_node(^"Health").visible = maximum > 0
	get_node(^"Health").max_value = maxi(1, maximum)
	get_node(^"Health").value = current
	var ratio := float(current) / float(maxi(1, maximum))
	_fill.bg_color = _tokens.color(self, &"vital_full" if ratio > 0.5 else &"vital_wounded" if ratio > 0.25 else &"vital_critical")
	get_node(^"Inset/Copy/Lines/Number/Value").visible = maximum == 0
	get_node(^"Inset/Copy/Lines/Number/HealthValue").visible = maximum > 0 and current > 0
	get_node(^"Inset/Copy/Lines/Number/DeadValue").visible = maximum > 0 and current <= 0
	if maximum > 0:
		icon = null if current <= 0 else preload("res://rookframe/ui/icons/character/heart.svg")
	var danger: TextureRect = get_node(^"DangerIcon")
	var extent := _tokens.pixels(self, icon_size)
	danger.visible = maximum > 0 and current <= 0
	danger.self_modulate = _tokens.color(self, &"danger")
	danger.offset_left = get_theme_stylebox(&"normal").content_margin_left
	danger.offset_right = danger.offset_left + extent
	danger.offset_top = -extent / 2.0
	danger.offset_bottom = extent / 2.0
	configure_hint(caption, {"Hit points":"Track wounds and recovery.", "Omens":"Resolve an Omen’s benefit, then mark it spent.", "Power uses":"Uses available for casting Powers."}.get(caption, "Inspect this resource."), not phone)
	accessibility_name = "%s. %d %s" % [caption, current, suffix]
	for path in [^"Inset/Copy/Lines/Caption", ^"Inset/Copy/Lines/Number/Extra", ^"Inset/Copy/Lines/Number/Value", ^"Inset/Copy/Lines/Number/HealthValue", ^"Inset/Copy/Lines/Number/DeadValue"]:
		var label: Label = get_node(path)
		var role := &"meta" if path == ^"Inset/Copy/Lines/Caption" or path == ^"Inset/Copy/Lines/Number/Extra" else &"value"
		label.add_theme_font_override("font", get_theme_font(role, SHEET_TOKENS.TYPE))
	custom_minimum_size = Vector2(44, maxf(custom_minimum_size.y, get_node(^"Inset").get_combined_minimum_size().y))
