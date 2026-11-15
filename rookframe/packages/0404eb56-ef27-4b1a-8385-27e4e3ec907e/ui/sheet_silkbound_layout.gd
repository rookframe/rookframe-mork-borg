extends "res://rookframe/sdk/window.gd"
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
const SheetLocale = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## The approved sheet's three canvas recipes, applied to its authored Controls.

func apply_sheet_layout(phone: bool, tablet: bool, detail: bool = false, task: bool = false) -> void:
	var outer := _outer()
	var inset := _leaf_inset()
	var picker: Control = get_node(^"Margin/Layout/Picker")
	picker.add_theme_constant_override("separation", inset + SHEET_TOKENS.pixels(self, &"space_5"))
	var margin: MarginContainer = get_node(^"Margin")
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, outer + inset)
	margin.add_theme_constant_override("margin_top", outer + SHEET_TOKENS.pixels(self, &"space_2"))
	margin.add_theme_constant_override("margin_bottom", outer + inset)
	var layout: VBoxContainer = get_node(^"Margin/Layout")
	layout.add_theme_constant_override("separation", SHEET_TOKENS.pixels(self, &"space_4") + inset)
	var header: Control = get_node(^"Margin/Layout/Header")
	header.custom_minimum_size = Vector2(0, 44 if phone else 56 if tablet else 64)
	_sync_frame.call_deferred()
	var body: HBoxContainer = get_node(^"Margin/Layout/Body")
	body.set(&"gap", &"")
	var core: Control = get_node(^"Margin/Layout/Body/Core")
	core.custom_minimum_size = Vector2(205 if phone else 300 if tablet else int((get_viewport_rect().size.x - 80) * 0.30) - 24, core.custom_minimum_size.y)
	var divider: Control = get_node(^"Margin/Layout/Body/CoreDivider")
	divider.visible = core.visible
	divider.custom_minimum_size = Vector2(SHEET_TOKENS.pixels(self, &"space_4" if phone else &"space_5" if tablet else &"space_6"), divider.custom_minimum_size.y)
	var page: PanelContainer = get_node(^"Margin/Layout/Body/Chapter/Page")
	page.set(&"padding_horizontal", &"space_1" if phone else &"space_2")
	page.set(&"padding_vertical", &"space_1" if phone else &"space_2")
	var content: VBoxContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content")
	content.set(&"gap", &"space_1" if phone else &"space_3")
	var collections: HBoxContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections")
	collections.set(&"gap", &"space_3" if tablet else &"space_5")
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Primary").size_flags_stretch_ratio = 1.0 if tablet or phone else 1.05
	var secondary: MarginContainer = get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary")
	secondary.add_theme_constant_override("margin_left", SHEET_TOKENS.pixels(self, &"" if phone else &"space_3" if tablet else &"space_5"))
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content").set(&"gap", &"space_3" if tablet else &"space_5")
	get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Resources").size_flags_vertical = 3 if phone else 1
	var companions: Control = get_node(^"Margin/Layout/Body/Chapter/Page/Content/Collections/Secondary/Content/Companions")
	companions.size_flags_stretch_ratio = 0.65
	companions.divider_top = not phone
	companions.custom_minimum_size = Vector2(companions.custom_minimum_size.x, 0 if phone or tablet else 300)
	(get_node(^"EntryScrim") as ColorRect).color = SHEET_TOKENS.color(self, &"scrim")


## Margin between the canvas edge and the sheet's frame.
func _outer() -> int:
	var width := get_viewport_rect().size.x
	return SHEET_TOKENS.pixels(self, &"space_2" if width <= 900 else &"space_4" if width <= 1300 else &"space_6")


## Margin between the frame's leaf and the sheet's content.
func _leaf_inset() -> int:
	return SHEET_TOKENS.pixels(self, &"space_3" if get_viewport_rect().size.x <= 900 else &"space_5")

func present_entry_dialog(shown: bool, mode: String) -> void:
	get_node(^"EntryDialog").present(shown, get_viewport_rect().size, mode)
	get_node(^"EntryScrim").visible = shown

func _sync_frame() -> void:
	if not is_inside_tree(): return
	var header: Control = get_node(^"Margin/Layout/Header")
	var outer := _outer()
	var h := Rect2(outer, outer, size.x - outer * 2 - 12, header.size.y + 12)
	var content: Control = get_node(^"Margin/Layout/Picker") if get_node(^"Margin/Layout/Picker").visible else get_node(^"Margin/Layout/Body")
	var top: float = content.get_global_rect().position.y - get_global_rect().position.y - _leaf_inset() if header.visible else outer
	var b := Rect2(outer, top, size.x - outer * 2, size.y - outer - top)
	var f := Rect2()
	var picker: Control = get_node(^"Margin/Layout/Picker")
	if picker.visible:
		var actions: Control = picker.get_node("Actions")
		f = Rect2(actions.get_global_rect().position.x - get_global_rect().position.x - 12, actions.get_global_rect().position.y - get_global_rect().position.y - 12, actions.size.x + 24, actions.size.y + 24)
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
