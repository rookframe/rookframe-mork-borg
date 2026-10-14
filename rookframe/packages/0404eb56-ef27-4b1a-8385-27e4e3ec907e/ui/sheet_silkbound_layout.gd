extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const SheetLocale = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## The approved sheet's three canvas recipes, applied to its authored Controls.

func apply_sheet_layout(phone: bool, tablet: bool, detail: bool = false, task: bool = false) -> void:
	get_node(^"Ornament").visible = false
	get_node(^"Ledger").visible = false
	var outer := 8 if phone else 16 if tablet else 28
	var margin: MarginContainer = get_node(^"Margin")
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, outer + 12)
	margin.add_theme_constant_override("margin_top", outer + 6)
	margin.add_theme_constant_override("margin_bottom", outer + 12)
	var layout: VBoxContainer = get_node(^"Margin/Layout")
	layout.add_theme_constant_override("separation", 22 if phone else 24)
	var header: Control = get_node(^"Margin/Layout/Header")
	header.custom_minimum_size = Vector2(0, 44 if phone else 56 if tablet else 64)
	_sync_frame.call_deferred()
	var body: HBoxContainer = get_node(^"Margin/Layout/Body")
	body.add_theme_constant_override("separation", 0)
	var core: Control = get_node(^"Margin/Layout/Body/Core")
	core.custom_minimum_size = Vector2(205 if phone else 300 if tablet else int((get_viewport_rect().size.x - 80) * 0.30) - 24, core.custom_minimum_size.y)
	var divider: Control = get_node(^"Margin/Layout/Body/CoreDivider")
	divider.visible = core.visible
	divider.custom_minimum_size = Vector2(14 if phone else 24 if tablet else 32, divider.custom_minimum_size.y)
	var line: Control = get_node(^"Margin/Layout/Body/CoreDivider/Line")
	line.offset_left = 8 if phone else 10 if tablet else 14
	line.offset_right = line.offset_left + 1
	var chapter: VBoxContainer = get_node(^"Margin/Layout/Body/Chapter")
	chapter.add_theme_constant_override("separation", 8 if phone else 0)
	var frame: StyleBoxFlat = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_chapter_frame.tres").duplicate()
	get_node(^"Margin/Layout/Body/Chapter/Page").add_theme_stylebox_override("panel", frame)
	frame.bg_color = Color(0, 0, 0, 0)
	for side in [0, 1, 2, 3]:
		frame.set_border_width(side, 0)
		frame.set_content_margin(side, 4 if phone else 6)
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


func _sync_frame() -> void:
	if not is_inside_tree(): return
	var header: Control = get_node(^"Margin/Layout/Header")
	var outer := 8 if get_viewport_rect().size.x <= 900 else 16 if get_viewport_rect().size.x <= 1300 else 28
	var h := Rect2(outer, outer, size.x - outer * 2 - 12, header.size.y + 12)
	var content: Control = get_node(^"Margin/Layout/Picker") if get_node(^"Margin/Layout/Picker").visible else get_node(^"Margin/Layout/Body")
	var top: float = content.get_global_rect().position.y - get_global_rect().position.y - 8 if header.visible else outer
	var b := Rect2(outer, top, size.x - outer * 2, size.y - outer - top)
	var f := Rect2()
	var picker: Control = get_node(^"Margin/Layout/Picker")
	if picker.visible:
		var actions: Control = picker.get_node("Actions")
		f = Rect2(actions.get_global_rect().position.x - get_global_rect().position.x - 12, actions.get_global_rect().position.y - get_global_rect().position.y - 6, actions.size.x + 24, actions.size.y + 12)
		b = Rect2(b.position.x, b.position.y, b.size.x, f.position.y - 8 - b.position.y)
	get_node(^"Frame").set_sections(h if header.visible else Rect2(), b, f)

func _open_miniature_picker(package_sdk: SDK, locale: SheetLocale, actor_id: SDK.ActorId, selected: Dictionary) -> void:
	get_node(^"Margin/Layout/Body").visible = false
	var picker: Control = get_node(^"Margin/Layout/Picker")
	picker.visible = true
	picker.open(package_sdk, locale, actor_id, "", selected, false, "Character")
	picker.get_node(^"Title").visible = false
	get_node(^"Margin/Layout/Header/Edit").visible = false
	var title: Button = get_node(^"Margin/Layout/Header/Name")
	title.text = locale.text("Choose Miniature")
	title.icon = null

func _close_miniature_picker() -> void:
	get_node(^"Margin/Layout/Header/Name").icon = preload("res://rookframe/ui/icons/character/character.svg")
	get_node(^"Margin/Layout/Picker").visible = false
	get_node(^"Margin/Layout/Body").visible = true
