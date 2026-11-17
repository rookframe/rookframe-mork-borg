extends Control

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const TOKENS := &"RookframeTokens"

signal closed
signal selected(reference: Dictionary)
var sdk: SDK
@onready var picker := get_node(^"Margin/Layout/Picker")

func _ready() -> void:
	picker.chosen.connect(_choose)
	picker.closed.connect(_picker_closed)
	get_node(^"Margin/Layout/Header/Close").pressed.connect(_cancel)
	resized.connect(_arrange)
	picker.get_node("Browser").item_rect_changed.connect(_fit_frame)
	picker.get_node("Actions").item_rect_changed.connect(_fit_frame)
	_arrange()

func open(facade: SDK, locale: I18N, saved: Dictionary, character_name: String = "") -> void:
	sdk = facade
	get_node(^"Margin/Layout/Header/Text").text = locale.text("Choose a miniature")
	get_node(^"Margin/Layout/Header/Close").accessibility_name = locale.text("Close miniature browser")
	get_node(^"Margin/Layout/Header/Close").tooltip_text = locale.text("Close miniature browser")
	picker.open_choice(facade, locale, saved)
	_arrange()

func _choose(reference: Dictionary) -> void:
	selected.emit(reference)
	sdk.windows.pop(self)

func _cancel() -> void:
	sdk.windows.pop(self)

func _picker_closed(_saved: bool) -> void:
	_cancel()

func _notification(what: int) -> void:
	# A World theme switch changes token values, so the token reads repeat.
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_arrange()

func _arrange() -> void:
	if not is_node_ready():
		return
	var phone := size.y <= 560
	var tablet := size.x <= 1300
	var margin := get_node(^"Margin")
	for edge in [&"left", &"right"]:
		margin.set(edge, &"space_5" if phone else &"space_6" if tablet else &"space_7")
	for edge in [&"top", &"bottom"]:
		margin.set(edge, &"space_5" if phone or tablet else &"space_6")
	get_node(^"Margin/Layout").set(&"gap", &"space_3" if phone else &"space_5")
	var icon := get_node(^"Margin/Layout/Header/Icon") as TextureRect
	icon.custom_minimum_size = Vector2(get_theme_constant(&"icon_medium" if phone else &"icon_large", TOKENS), get_theme_constant(&"icon_medium" if phone else &"icon_large", TOKENS))
	icon.self_modulate = get_theme_color(&"ornament", TOKENS)
	get_node(^"Margin/Layout/Header/Text").theme_type_variation = &"RookframeHeading" if phone else &"RookframeSubtitle"
	get_node(^"Margin/Layout/Picker/Title").visible = false
	_fit_frame.call_deferred()

func _fit_frame() -> void:
	if not is_node_ready(): return
	# The kit's ledger leaves sit one step outside the content they frame.
	var outset_x := get_theme_constant(&"space_4", TOKENS)
	var outset_y := get_theme_constant(&"space_2", TOKENS)
	var rects: Array[Rect2] = []
	for path in ["Margin/Layout/Header", "Margin/Layout/Picker/Browser", "Margin/Layout/Picker/Actions"]:
		var item: Control = get_node(path)
		rects.append(Rect2(item.get_global_rect().position.x - get_global_rect().position.x - outset_x, item.get_global_rect().position.y - get_global_rect().position.y - outset_y, item.size.x + outset_x * 2, item.size.y + outset_y * 2))
	get_node("Frame").set_sections(rects[0], rects[1], rects[2])
