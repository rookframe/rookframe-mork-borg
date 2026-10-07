extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## The approved sheet's three canvas recipes, applied to its authored Controls.

func apply_sheet_layout(phone: bool, tablet: bool, detail: bool = false, task: bool = false) -> void:
	get_node(^"Ornament").configure(phone, tablet, task)
	var outer := 8 if phone else 16 if tablet else 32
	var ledger: Control = get_node(^"Ledger")
	ledger.offset_left = outer
	ledger.offset_top = outer
	ledger.offset_right = -outer
	ledger.offset_bottom = -outer
	var ribbon: Control = get_node(^"Ledger/Ribbon")
	ribbon.visible = not phone
	ribbon.offset_left = -40 if tablet else -60
	ribbon.offset_right = -20 if tablet else -32
	ribbon.offset_bottom = 68 if tablet else 100
	var margin: MarginContainer = get_node(^"Margin")
	var horizontal := 22 if phone else 38 if tablet else 74
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, horizontal)
	margin.add_theme_constant_override("margin_top", 19 if phone else 29 if tablet else 53)
	margin.add_theme_constant_override("margin_bottom", 19 if phone else 33 if tablet else 61)
	var layout: VBoxContainer = get_node(^"Margin/Layout")
	layout.add_theme_constant_override("separation", 5 if phone else 14 if tablet else 20)
	var header: Control = get_node(^"Margin/Layout/Header")
	header.custom_minimum_size = Vector2(header.custom_minimum_size.x, 26 if phone else 52 if tablet else 72)
	var body: HBoxContainer = get_node(^"Margin/Layout/Body")
	body.add_theme_constant_override("separation", 0)
	var core: Control = get_node(^"Margin/Layout/Body/Core")
	core.custom_minimum_size = Vector2(205 if phone else 249 if tablet else int((get_viewport_rect().size.x - 148) * 0.29 + 0.5) - 29, core.custom_minimum_size.y)
	var divider: Control = get_node(^"Margin/Layout/Body/CoreDivider")
	divider.visible = core.visible
	divider.custom_minimum_size = Vector2(29 if phone else 33 if tablet else 61, divider.custom_minimum_size.y)
	var line: Control = get_node(^"Margin/Layout/Body/CoreDivider/Line")
	line.offset_left = 12 if phone else 14 if tablet else 28
	line.offset_right = line.offset_left + 1
	var chapter: VBoxContainer = get_node(^"Margin/Layout/Body/Chapter")
	chapter.add_theme_constant_override("separation", 8 if phone else 0)
	var frame: StyleBoxFlat = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_chapter_frame.tres").duplicate()
	get_node(^"Margin/Layout/Body/Chapter/Page").add_theme_stylebox_override("panel", frame)
	frame.bg_color = Color(0, 0, 0, 0) if phone else Color(0.082353, 0.090196, 0.098039, 0.780392)
	for side in [0, 1, 2, 3]:
		frame.set_border_width(side, 0 if phone else 1)
		frame.set_content_margin(side, 4 if phone and side in [0, 2] else 0 if phone else 13 if tablet else 25)
	var content: VBoxContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content")
	content.add_theme_constant_override("separation", 4 if phone else 12)
	var collections: HBoxContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections")
	collections.add_theme_constant_override("separation", 12 if tablet else 24)
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Primary").size_flags_stretch_ratio = 1.0 if tablet or phone else 1.05
	var secondary: MarginContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary")
	secondary.add_theme_constant_override("margin_left", 0 if phone else 11 if tablet else 21)
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content").add_theme_constant_override("separation", 12 if tablet else 24)
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Resources").size_flags_vertical = 3 if phone else 1
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Companions").size_flags_stretch_ratio = 0.65
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Companions").divider_top = not phone
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Companions").custom_minimum_size = Vector2(get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Companions").custom_minimum_size.x, 0 if phone or tablet else 300)

