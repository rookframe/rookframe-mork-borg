extends VBoxContainer
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
## Authored presentation only. Actor/World appearance mutations stay in adapters.
const TYPE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_type.gd")
var _type := TYPE.new()
const TOKENS := &"RookframeTokens"
## Constant token of the gap between the parts, `space_1` to `space_8`. Empty means no gap.
@export var gap: StringName = &"space_4":
	set(value):
		gap = value
		_read_tokens()
var _reading := false

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()

# Setting an override notifies this Control of a theme change, so the read
# guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	add_theme_constant_override(&"separation", get_theme_constant(gap, TOKENS) if gap else 0)
	_reading = false

signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
@export var miniature_only := false
var _assigned := false
var _phone := false
## Width at which a row's regular actions wrapped, by row name.
var _wrapped := {}
## Rows whose actions are compact now, by row name.
var _compact_rows := {}
const PORTRAIT := "Columns/PortraitPanel/Inset/Content/"
const MINIATURE := "Columns/MiniaturePanel/Inset/Content/"
func _ready() -> void:
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").pressed.connect(_portrait)
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").pressed.connect(_portrait_reset)
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").pressed.connect(_miniature)
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").pressed.connect(_miniature_clear)
	for row in [PORTRAIT + "PortraitButtons", MINIATURE + "MiniatureButtons"]:
		# A row that wraps grows taller, and one that is resized may fit again.
		get_node(row).minimum_size_changed.connect(_fit_actions.bind(get_node(row)))
		get_node(row).resized.connect(_fit_actions.bind(get_node(row)))

func configure(locale: I18N, texture: Texture2D, library: bool, can_edit: bool, phone: bool, tablet: bool, name: String = "") -> void:
	_phone = phone
	get_node("Intro").visible = not phone and not miniature_only
	get_node("Columns/PortraitPanel").visible = not miniature_only
	get_node("TopSpace").visible = false
	get_node("BottomSpace").visible = false
	get_node("Intro/Title").text = locale.text("Appearance")
	get_node("Intro/Copy").text = locale.text("World defaults for future Actors") if library else locale.text("How %s appears in the sheet and on the tabletop.") % name
	gap = &"" if phone else &"space_3" if tablet else &"space_4"
	get_node("Columns").set(&"gap", &"space_4" if phone or tablet else &"space_5")
	get_node(PORTRAIT + "PortraitPreview/Image").texture = texture
	get_node(PORTRAIT + "PortraitHeading/Title").text = locale.text("Portrait")
	get_node(MINIATURE + "MiniatureHeading/Title").text = locale.text("Tabletop miniature")
	get_node(PORTRAIT + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Shown in the creature sheet.")
	get_node(MINIATURE + "Explanation").text = locale.text("Applies only to new Actors created from this entry." if library else "Saved for this creature. Existing Rooks keep their current miniature.")
	var inset: StringName = &"space_3" if tablet else &"space_4"
	for edge in [&"left", &"right", &"top", &"bottom"]:
		get_node("Columns/PortraitPanel/Inset").set(edge, &"")
		# The lone miniature column keeps a frame inset; beside the portrait it
		# only stands clear of the divider.
		get_node("Columns/MiniaturePanel/Inset").set(edge, ((&"space_2" if edge == &"bottom" else &"") if phone else inset) if miniature_only else &"space_4" if edge == &"left" else &"")
	get_node("Columns/MiniaturePanel").set(&"outline", &"" if miniature_only else &"divider")
	for content in ["Columns/PortraitPanel/Inset/Content", "Columns/MiniaturePanel/Inset/Content"]:
		get_node(content).set(&"gap", &"space_1" if phone else &"space_2")
	for base in [PORTRAIT, MINIATURE]:
		for spacer in ["HeadingGap", "ControlsGap", "ExplanationGap"]:
			get_node(base + spacer).visible = false
		get_node(base + ("PortraitHeading" if base == PORTRAIT else "MiniatureHeading")).set(&"gap", &"space_2")
		_type.apply(get_node(base + ("PortraitHeading/Title" if base == PORTRAIT else "MiniatureHeading/Title")), "Title" if miniature_only else "Section", phone, tablet)
	for controls in [PORTRAIT + "PortraitButtons", MINIATURE + "MiniatureButtons"]:
		get_node(controls).set(&"gap", &"space_2" if phone else &"space_3")
	for path in [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait", MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]:
		var button: Button = get_node(path)
		button.disabled = not can_edit
	get_node(MINIATURE + "Explanation").visible = not miniature_only
	get_node(MINIATURE + "EmptyPreview/Content/Title").text = locale.text("No miniature assigned")
	get_node(MINIATURE + "EmptyPreview/Content/Copy").text = locale.text("Choose from installed Packages.")
	get_node(MINIATURE + "EmptyPreview/Content").set(&"gap", &"space_1" if phone else &"space_2")
	get_node(MINIATURE + "EmptyPreview/Content/Gap").visible = false
	get_node(PORTRAIT + "PortraitButtons/ChangePortrait").text = locale.text("Choose image")
	get_node(PORTRAIT + "PortraitButtons/ClearPortrait").text = locale.text("Reset")
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if _assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").text = locale.text("Reset")
	get_node(MINIATURE + "PreviewCaptionGap").visible = false
	get_node(MINIATURE + "EmptyPreview/Content/Image").custom_minimum_size = Vector2(32, 32) if phone else Vector2(96, 96)
	# The creator's phone page keeps its height for the words and the action.
	get_node(MINIATURE + "EmptyPreview/Content/Image").visible = not (phone and miniature_only)
	_refit_actions()
	_type.apply(get_node("Intro/Title"), "Title", phone, tablet)
	_type.apply(get_node(MINIATURE + "EmptyPreview/Content/Title"), "Section", phone, tablet)
	_type.apply(get_node(MINIATURE + "MiniatureCaption"), "Section", phone, tablet)
	_present_actions()

func miniature(locale: I18N, title: String, package: String, assigned: bool) -> void:
	_assigned = assigned
	get_node(MINIATURE + "MiniatureCaption").text = title if assigned else locale.text("No miniature selected")
	get_node(MINIATURE + "PackageCaption").text = package
	get_node(MINIATURE + "MiniatureCaption").visible = assigned
	# A phone keeps the height for the miniature itself.
	get_node(MINIATURE + "PackageCaption").visible = assigned and not (_phone and miniature_only)
	get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").text = locale.text("Change miniature" if assigned else "Choose miniature")
	get_node(MINIATURE + "MiniatureButtons/ClearMiniature").visible = assigned
	get_node(MINIATURE + "EmptyPreview").visible = not assigned
	get_node(MINIATURE + "MiniaturePreview").visible = assigned
	_refit_actions()
	_present_actions()

# Actions take their compact size on a phone and wherever a row of regular
# ones wraps. A row tries the regular size again when its width changes.
func _fit_actions(row: HFlowContainer) -> void:
	var key := str(row.name)
	var wrapped_at: float = _wrapped.get(key, -1.0)
	if wrapped_at >= 0.0 and maxf(wrapped_at - row.size.x, row.size.x - wrapped_at) >= 1.0:
		_wrapped.erase(key)
	elif wrapped_at < 0.0 and not _phone and _wraps(row):
		_wrapped[key] = row.size.x
	var compact: bool = _phone or _wrapped.has(key)
	if _compact_rows.get(key, false) == compact:
		return
	_compact_rows[key] = compact
	var actions := [PORTRAIT + "PortraitButtons/ChangePortrait", PORTRAIT + "PortraitButtons/ClearPortrait"] if key == "PortraitButtons" else [MINIATURE + "MiniatureButtons/ChangeMiniature", MINIATURE + "MiniatureButtons/ClearMiniature"]
	for path in actions:
		var button: Button = get_node(path)
		button.compact = compact

# A wrapped row places a later action below its first one.
func _wraps(row: HFlowContainer) -> bool:
	var first: Control = null
	for child in row.get_children():
		var action := child as Control
		if action == null or not action.visible:
			continue
		if first == null:
			first = action
		elif action.position.y >= first.position.y + first.size.y:
			return true
	return false

func _refit_actions() -> void:
	_wrapped = {}
	for row in [PORTRAIT + "PortraitButtons", MINIATURE + "MiniatureButtons"]:
		_fit_actions(get_node(row))

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
