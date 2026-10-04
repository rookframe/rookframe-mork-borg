extends HBoxContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## Authored presentation only. Actor/World appearance mutations stay in adapters.
signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
const PORTRAIT := "PortraitPanel/Inset/Content/"
const MINIATURE := "MiniaturePanel/Inset/Content/"
func _ready() -> void:
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").pressed.connect(_portrait)
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").pressed.connect(_portrait_reset)
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").pressed.connect(_miniature)
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").pressed.connect(_miniature_clear)

func configure(locale: I18N, texture: Texture2D, library: bool, can_edit: bool, phone: bool, tablet: bool) -> void:
	get_node(PORTRAIT + "PortraitPreview/Image").texture = texture
	get_node(PORTRAIT + "PortraitHeading/Title").text = locale.text("Portrait")
	get_node(MINIATURE + "MiniatureHeading/Title").text = locale.text("Tabletop miniature")
	get_node(PORTRAIT + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Portrait changes appear immediately.")
	get_node(MINIATURE + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Existing Rooks keep their Miniature.")
	for base in [PORTRAIT, MINIATURE]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node("PortraitPanel/Inset" if base == PORTRAIT else "MiniaturePanel/Inset").add_theme_constant_override("margin_" + edge, 10 if phone else 12 if tablet else 18)
		(get_node(base + "ControlsGap") as Control).custom_minimum_size = Vector2((get_node(base + "ControlsGap") as Control).custom_minimum_size.x, 0 if phone else 8)
		get_node(base + "Explanation").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)
		get_node(base + ("PortraitHeading/Title" if base == PORTRAIT else "MiniatureHeading/Title")).add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	for path in [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait", MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]:
		get_node(path).disabled = not can_edit
		get_node(path).add_theme_font_size_override("font_size", 11 if phone else 12 if tablet else 13)
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").text = locale.text("Choose image")
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").text = locale.text("Reset portrait")
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").text = locale.text("Clear")
	get_node(MINIATURE + "EmptyPreview/Image").custom_minimum_size = Vector2(34, 34) if phone else Vector2(100, 100)

func miniature(locale: I18N, title: String, package: String, assigned: bool) -> void:
	get_node(MINIATURE + "MiniatureCaption").text = title if assigned else locale.text("No miniature selected")
	get_node(MINIATURE + "PackageCaption").text = package
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").visible = assigned
	get_node(MINIATURE + "EmptyPreview").visible = not assigned
	get_node(MINIATURE + "MiniaturePreview").visible = assigned

func _portrait() -> void:
	portrait_requested.emit()
func _portrait_reset() -> void:
	portrait_reset_requested.emit()
func _miniature() -> void:
	miniature_requested.emit()
func _miniature_clear() -> void:
	miniature_clear_requested.emit()
