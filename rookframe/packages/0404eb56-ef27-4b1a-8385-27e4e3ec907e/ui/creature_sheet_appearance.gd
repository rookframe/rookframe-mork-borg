extends VBoxContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## Authored presentation only. Actor/World appearance mutations stay in adapters.
signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
@export var miniature_only := false
var _assigned := false
const PORTRAIT := "Columns/PortraitPanel/Inset/Content/"
const MINIATURE := "Columns/MiniaturePanel/Inset/Content/"
func _ready() -> void:
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").pressed.connect(_portrait)
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").pressed.connect(_portrait_reset)
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").pressed.connect(_miniature)
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").pressed.connect(_miniature_clear)

func configure(locale: I18N, texture: Texture2D, library: bool, can_edit: bool, phone: bool, tablet: bool, name: String = "") -> void:
	get_node("Intro").visible = not phone and not miniature_only
	get_node("Columns/PortraitPanel").visible = not miniature_only
	get_node("Intro").custom_minimum_size = Vector2(0, 54 if tablet else 64)
	get_node("TopSpace").visible = phone and not miniature_only
	get_node("BottomSpace").visible = phone and not miniature_only
	get_node("TopSpace").custom_minimum_size = Vector2(0, 0)
	get_node("BottomSpace").custom_minimum_size = Vector2(0, 0)
	get_node("Intro/Title").text = locale.text("Appearance")
	get_node("Intro/Title").add_theme_font_size_override("font_size", 24 if tablet else 30)
	get_node("Intro/Copy").text = locale.text("World defaults for future Actors") if library else locale.text("How %s appears in the sheet and on the tabletop.") % name
	get_node("Intro/Copy").add_theme_font_size_override("font_size", 16 if tablet else 18)
	add_theme_constant_override("separation", 0 if phone else 12 if tablet else 18)
	get_node("Columns").add_theme_constant_override("separation", 16 if phone or tablet else 24)
	get_node(PORTRAIT + "PortraitPreview/Image").texture = texture
	get_node(PORTRAIT + "PortraitHeading/Title").text = locale.text("Portrait")
	get_node(MINIATURE + "MiniatureHeading/Title").text = locale.text("Tabletop miniature")
	get_node(PORTRAIT + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Shown in the creature sheet.")
	get_node(MINIATURE + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Saved for this creature. Existing Rooks keep their current miniature.")
	for base in [PORTRAIT, MINIATURE]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node("Columns/PortraitPanel/Inset" if base == PORTRAIT else "Columns/MiniaturePanel/Inset").add_theme_constant_override("margin_" + edge, 0 if miniature_only or base == PORTRAIT or edge != "left" else 16 if phone or tablet else 20)
		get_node(base + "HeadingGap").custom_minimum_size = Vector2(0, 4 if phone else 8)
		(get_node(base + "ControlsGap") as Control).custom_minimum_size = Vector2((get_node(base + "ControlsGap") as Control).custom_minimum_size.x, 4 if phone else 16)
		get_node(base + "Explanation").add_theme_font_size_override("font_size", 14 if phone else 15 if tablet else 17)
		get_node(base + ("PortraitHeading/Title" if base == PORTRAIT else "MiniatureHeading/Title")).add_theme_font_size_override("font_size", 20 if phone else 21 if tablet else 24)
	for controls in [PORTRAIT + "PortraitButtons", MINIATURE + "MiniatureButtons"]:
		get_node(controls).add_theme_constant_override("h_separation", 6 if phone else 12)
		get_node(controls).add_theme_constant_override("v_separation", 6 if phone else 8)
	for path in [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait", MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]:
		var button: Button = get_node(path)
		button.disabled = not can_edit
		button.theme_type_variation = "WizardPrimary" if "Change" in path else "WizardButton"
		button.custom_minimum_size = Vector2(44,44)
		button.icon = null
		button.add_theme_font_size_override("font_size", 14 if phone else 16 if tablet else 18)
	if miniature_only:
		get_node("Columns/MiniaturePanel").add_theme_stylebox_override("panel", get_node("Columns/PortraitPanel").get_theme_stylebox("panel"))
		get_node(MINIATURE + "MiniatureHeading/Title").add_theme_font_size_override("font_size", 24 if phone else 26 if tablet else 30)
		get_node(MINIATURE + "HeadingGap").custom_minimum_size = Vector2(0, 8 if phone else 12 if tablet else 16)
	get_node(MINIATURE + "Explanation").visible = not miniature_only
	get_node(MINIATURE + "ExplanationGap").visible = not miniature_only
	for base in [PORTRAIT, MINIATURE]:
		(get_node(base) as Control).add_theme_constant_override("separation", 0)
		(get_node(base + "ExplanationGap") as Control).custom_minimum_size = Vector2(0, 4 if phone else 8 if tablet else 10)
		(get_node(base + "Explanation") as Control).custom_minimum_size = Vector2(0, 16 if phone else 20 if tablet else 23)
		get_node(base + ("PortraitHeading/Icon" if base == PORTRAIT else "MiniatureHeading/Icon")).custom_minimum_size = Vector2(22, 22) if phone else Vector2(26,26)
	get_node(MINIATURE + "EmptyPreview/Content/Title").text = locale.text("No miniature assigned")
	get_node(MINIATURE + "EmptyPreview/Content/Title").add_theme_font_size_override("font_size", 18 if phone else 19 if tablet else 23)
	get_node(MINIATURE + "EmptyPreview/Content/Copy").text = locale.text("Choose from installed Packages.")
	get_node(MINIATURE + "EmptyPreview/Content/Copy").add_theme_font_size_override("font_size", 14 if phone else 15 if tablet else 17)
	get_node(MINIATURE + "EmptyPreview/Content/Gap").custom_minimum_size = Vector2(0, 4 if phone else 24)
	get_node(MINIATURE + "MiniatureCaption").add_theme_font_size_override("font_size", 18 if phone else 19 if tablet else 23)
	get_node(MINIATURE + "PackageCaption").add_theme_font_size_override("font_size", 14 if phone else 15 if tablet else 17)
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").text = locale.text("Choose image")
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").text = locale.text("Reset")
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if _assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").text = locale.text("Reset")
	get_node(MINIATURE + "PreviewCaptionGap").custom_minimum_size = Vector2(0, 4 if phone else 8)
	get_node(MINIATURE + "EmptyPreview/Content/Image").custom_minimum_size = Vector2(34, 34) if phone else Vector2(100, 100)
	var density := "Phone" if phone else "Tablet" if tablet else "Desktop"
	get_node("Intro/Title").theme_type_variation = "SilkCreatureAppearanceTitle" + density
	get_node("Intro/Copy").theme_type_variation = "SilkCreatureAppearanceCopy" + density
	get_node(PORTRAIT + "PortraitHeading/Title").theme_type_variation = "SilkCreatureAppearanceHeading" + density
	get_node(MINIATURE + "MiniatureHeading/Title").theme_type_variation = "SilkCreatureAppearanceHeading" + density
	get_node(PORTRAIT + "Explanation").theme_type_variation = "SilkCreatureAppearanceNote" + density
	get_node(MINIATURE + "Explanation").theme_type_variation = "SilkCreatureAppearanceNote" + density
	get_node(MINIATURE + "EmptyPreview/Content/Title").theme_type_variation = "SilkCreatureMiniatureTitle" + density
	get_node(MINIATURE + "EmptyPreview/Content/Copy").theme_type_variation = "SilkCreatureAppearanceNote" + density
	_present_actions()

func miniature(locale: I18N, title: String, package: String, assigned: bool) -> void:
	_assigned = assigned
	get_node(MINIATURE + "MiniatureCaption").text = title if assigned else locale.text("No miniature selected")
	get_node(MINIATURE + "PackageCaption").text = package
	get_node(MINIATURE + "MiniatureCaption").visible = assigned
	get_node(MINIATURE + "PackageCaption").visible = assigned
	get_node(MINIATURE + "PreviewCaptionGap").visible = assigned
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").visible = assigned
	get_node(MINIATURE + "EmptyPreview").visible = not assigned
	get_node(MINIATURE + "MiniaturePreview").visible = assigned
	_present_actions()

func _present_actions() -> void:
	for path in [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait", MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]:
		var button: Button = get_node(path)
		if not button.text.is_empty():
			button.accessibility_name = button.text
			button.tooltip_text = button.text

func _portrait() -> void:
	portrait_requested.emit()
func _portrait_reset() -> void:
	portrait_reset_requested.emit()
func _miniature() -> void:
	miniature_requested.emit()
func _miniature_clear() -> void:
	miniature_clear_requested.emit()
