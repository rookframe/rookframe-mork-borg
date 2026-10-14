extends Control

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")

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
	get_node(^"Margin/Layout/Header/Name/Row/Text").text = locale.text("Choose a miniature")
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

func _arrange() -> void:
	if not is_node_ready():
		return
	var phone := size.y <= 560
	var outer := 12 if phone else 16 if size.x <= 1300 else 28
	get_node(^"Ledger").visible = false
	get_node(^"Ornament").visible = false
	for edge in ["left", "right"]: get_node(^"Margin").add_theme_constant_override("margin_" + edge, outer + 16)
	for edge in ["top", "bottom"]: get_node(^"Margin").add_theme_constant_override("margin_" + edge, outer + 8)
	get_node(^"Margin/Layout").add_theme_constant_override("separation", 20)
	get_node(^"Margin/Layout/Header").custom_minimum_size = Vector2(0, 44 if phone else 56)
	get_node(^"Margin/Layout/Header/Name").custom_minimum_size = Vector2(0, 44)
	get_node(^"Margin/Layout/Header/Name/Row/Text").add_theme_font_size_override("font_size", 25 if phone else 32)
	get_node(^"Margin/Layout/Header/RibbonSpace").visible = true
	get_node(^"Margin/Layout/Header/RibbonSpace").custom_minimum_size = Vector2(16, 0)
	get_node(^"Margin/Layout/Picker/Title").visible = false
	get_node(^"Margin/Layout/Picker/Actions").custom_minimum_size = Vector2(0, 48 if phone else 60)
	_fit_frame.call_deferred()

func _fit_frame() -> void:
	if not is_node_ready(): return
	var rects: Array[Rect2] = []
	for path in ["Margin/Layout/Header", "Margin/Layout/Picker/Browser", "Margin/Layout/Picker/Actions"]:
		var item: Control = get_node(path)
		rects.append(Rect2(item.get_global_rect().position.x - get_global_rect().position.x - 16, item.get_global_rect().position.y - get_global_rect().position.y - 8, item.size.x + 32, item.size.y + 16))
	get_node("Frame").set_sections(rects[0], rects[1], rects[2])
