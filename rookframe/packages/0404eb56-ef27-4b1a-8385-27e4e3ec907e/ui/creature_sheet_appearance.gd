extends VBoxContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## Authored presentation only. Actor/World appearance mutations stay in adapters.
signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
@export var action_hover: StyleBoxFlat = StyleBoxFlat.new()
@export var action_disabled: StyleBoxFlat = StyleBoxFlat.new()
var _assigned := false
const PORTRAIT := "Columns/PortraitPanel/Inset/Content/"
const MINIATURE := "Columns/MiniaturePanel/Inset/Content/"
func _ready() -> void:
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").pressed.connect(_portrait)
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").pressed.connect(_portrait_reset)
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").pressed.connect(_miniature)
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").pressed.connect(_miniature_clear)

func configure(locale: I18N, texture: Texture2D, library: bool, can_edit: bool, phone: bool, tablet: bool, name: String = "") -> void:
	get_node("Intro").visible = not phone
	get_node("Intro").custom_minimum_size = Vector2(0, 49.5 if tablet else 54.5)
	get_node("TopSpace").visible = phone
	get_node("BottomSpace").visible = phone
	get_node("TopSpace").custom_minimum_size = Vector2(0, 8)
	get_node("BottomSpace").custom_minimum_size = Vector2(0, 8)
	get_node("Intro/Title").text = locale.text("Appearance")
	get_node("Intro/Title").add_theme_font_size_override("font_size", 23 if tablet else 26)
	get_node("Intro/Copy").text = locale.text("World defaults for future Actors") if library else locale.text("How %s appears in the sheet and on the tabletop.") % name
	get_node("Intro/Copy").add_theme_font_size_override("font_size", 12 if tablet else 13)
	add_theme_constant_override("separation", 0 if phone else 18)
	get_node("Columns").add_theme_constant_override("separation", 12 if phone or tablet else 20)
	get_node(PORTRAIT + "PortraitPreview/Image").texture = texture
	get_node(PORTRAIT + "PortraitHeading/Title").text = locale.text("Portrait")
	get_node(MINIATURE + "MiniatureHeading/Title").text = locale.text("Tabletop miniature")
	get_node(PORTRAIT + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Shown in the creature sheet.")
	get_node(MINIATURE + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Saved for this creature. Existing Rooks keep their current miniature.")
	for base in [PORTRAIT, MINIATURE]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node("Columns/PortraitPanel/Inset" if base == PORTRAIT else "Columns/MiniaturePanel/Inset").add_theme_constant_override("margin_" + edge, 10 if phone else 12 if tablet else 18)
		(get_node(base + "ControlsGap") as Control).custom_minimum_size = Vector2((get_node(base + "ControlsGap") as Control).custom_minimum_size.x, 4 if phone else 16)
		get_node(base + "Explanation").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)
		get_node(base + ("PortraitHeading/Title" if base == PORTRAIT else "MiniatureHeading/Title")).add_theme_font_size_override("font_size", 17 if phone else 18 if tablet else 22)
	for controls in [PORTRAIT + "PortraitButtons", MINIATURE + "MiniatureButtons"]:
		get_node(controls).add_theme_constant_override("h_separation", 6 if phone else 8)
		get_node(controls).add_theme_constant_override("v_separation", 6 if phone else 8)
	for path in [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait", MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]:
		get_node(path).disabled = not can_edit
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.266667, 0.913725, 0.913725, 1) if path.ends_with("ChangePortrait") or path.ends_with("ChangeMiniature") else Color(0, 0, 0, 0)
		frame.border_color = Color(0.27451, 0.321569, 0.337255, 1)
		frame.set_border_width_all(1)
		frame.content_margin_left = 8 if phone else 10 if tablet else 12
		frame.content_margin_right = frame.content_margin_left
		frame.content_margin_top = 5 if phone else 6
		frame.content_margin_bottom = frame.content_margin_top
		var hover: StyleBoxFlat = action_hover.duplicate()
		var disabled: StyleBoxFlat = action_disabled.duplicate()
		for state_frame in [hover, disabled]:
			state_frame.content_margin_left = frame.content_margin_left
			state_frame.content_margin_right = frame.content_margin_right
			state_frame.content_margin_top = frame.content_margin_top
			state_frame.content_margin_bottom = frame.content_margin_bottom
		get_node(path).add_theme_stylebox_override("disabled", disabled)
		get_node(path).add_theme_stylebox_override("normal", frame)
		if path.ends_with("ChangePortrait") or path.ends_with("ChangeMiniature"):
			get_node(path).add_theme_stylebox_override("hover", frame)
			get_node(path).add_theme_stylebox_override("pressed", frame)
		else:
			get_node(path).add_theme_stylebox_override("hover", hover)
			get_node(path).add_theme_stylebox_override("pressed", hover)
		get_node(path).add_theme_font_size_override("font_size", 11 if phone else 12 if tablet else 13)
	for base in [PORTRAIT, MINIATURE]:
		(get_node(base) as Control).add_theme_constant_override("separation", 0)
		(get_node(base + "ExplanationGap") as Control).custom_minimum_size = Vector2(0, 5 if phone else 12)
		(get_node(base + "Explanation") as Control).custom_minimum_size = Vector2(0, 15 if phone else 16.5 if tablet else 18)
		get_node(base + ("PortraitHeading/Icon" if base == PORTRAIT else "MiniatureHeading/Icon")).custom_minimum_size = Vector2(20, 20) if phone else Vector2(24, 24)
	get_node(MINIATURE + "EmptyPreview/Content/Title").text = locale.text("No miniature assigned")
	get_node(MINIATURE + "EmptyPreview/Content/Title").add_theme_font_size_override("font_size", 12 if phone else 17)
	get_node(MINIATURE + "EmptyPreview/Content/Copy").text = locale.text("Choose from installed Packages.")
	get_node(MINIATURE + "EmptyPreview/Content/Copy").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)
	get_node(MINIATURE + "EmptyPreview/Content/Gap").custom_minimum_size = Vector2(0, 4 if phone else 24)
	get_node(MINIATURE + "MiniatureCaption").add_theme_font_size_override("font_size", 12 if phone else 15 if tablet else 17)
	get_node(MINIATURE + "PackageCaption").add_theme_font_size_override("font_size", 10 if phone else 11 if tablet else 12)
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").text = locale.text("Choose image")
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").text = locale.text("Reset portrait")
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if _assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").text = locale.text("Clear")
	get_node(MINIATURE + "EmptyPreview/Content/Image").custom_minimum_size = Vector2(34, 34) if phone else Vector2(100, 100)

func miniature(locale: I18N, title: String, package: String, assigned: bool) -> void:
	_assigned = assigned
	get_node(MINIATURE + "MiniatureCaption").text = title if assigned else locale.text("No miniature selected")
	get_node(MINIATURE + "PackageCaption").text = package
	get_node(MINIATURE + "MiniatureCaption").visible = assigned
	get_node(MINIATURE + "PackageCaption").visible = assigned
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
