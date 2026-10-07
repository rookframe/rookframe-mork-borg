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
	_arrange()

func open(facade: SDK, locale: I18N, saved: Dictionary, character_name: String = "") -> void:
	sdk = facade
	get_node(^"Margin/Layout/Header/Name/Row/Text").text = character_name if not character_name.is_empty() else locale.text("Character creation")
	get_node(^"Margin/Layout/Header/Close").accessibility_name = locale.text("Close miniature browser")
	get_node(^"Margin/Layout/Header/Close").tooltip_text = locale.text("Close miniature browser")
	picker.open_choice(facade, locale, saved)

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
	# Use the character sheet's outer ledger and header measurements.
	var phone := size.x <= 900
	var tablet := not phone and size.x <= 1300
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
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 22 if phone else 38 if tablet else 74)
	margin.add_theme_constant_override("margin_top", 19 if phone else 29 if tablet else 53)
	margin.add_theme_constant_override("margin_bottom", 19 if phone else 33 if tablet else 61)
	get_node(^"Margin/Layout").add_theme_constant_override("separation", 5 if phone else 14 if tablet else 20)
	get_node(^"Margin/Layout/Header").custom_minimum_size = Vector2(0, 44 if phone else 52 if tablet else 72)
	get_node(^"Margin/Layout/Header/Name").custom_minimum_size = Vector2(0, 44 if phone else 52 if tablet else 60)
	get_node(^"Margin/Layout/Header/Name/Row/Text").add_theme_font_size_override("font_size", 23 if phone else 29 if tablet else 40)
	get_node(^"Margin/Layout/Header/RibbonSpace").visible = not phone
	get_node(^"Margin/Layout/Header/RibbonSpace").custom_minimum_size = Vector2(40 if tablet else 56, 0)
	get_node(^"Ornament").configure(phone, tablet, false)
