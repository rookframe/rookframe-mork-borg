extends VBoxContainer
const CHROME = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_icon_actions.gd")
const FORM = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_correction_form.gd")
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal back_requested
signal save_requested
signal cancel_requested
signal changed(field: String, text: String)
var _identity := ""
@onready var _pager: HBoxContainer = get_node("Body/Pages/Pager")
@onready var _range: Label = get_node("Body/Pages/Pager/Range")
@onready var _previous: Button = get_node("Body/Pages/Pager/Previous")
@onready var _next: Button = get_node("Body/Pages/Pager/Next")
@onready var form: FORM = get_node(^"Body/Pages/Area/FocusInset/Form")
func _ready() -> void:
	get_node(^"Header/Inset/Row/Back").pressed.connect(_back)
	get_node(^"Header/Inset/Row/Close").pressed.connect(_back)
	get_node(^"Footer/Inset/Row/Save").pressed.connect(_save)
	get_node(^"Footer/Inset/Row/Cancel").pressed.connect(_cancel)
	form.changed.connect(_changed)
	var pager = _pager
	get_node(^"Body/Pages").get_pager()
	get_node(^"Footer/Inset/Row/Pager").add_child(pager)
func _back() -> void:
	back_requested.emit()
func _save() -> void:
	save_requested.emit()
func _cancel() -> void:
	cancel_requested.emit()
func _changed(field: String, text: String) -> void:
	changed.emit(field, text)
func configure(keys: Array, values: Dictionary, locale: I18N, phone: bool, identity: String, title: String) -> void:
	get_node(^"Header/Inset/Row/Title").text = locale.text(title)
	get_node(^"Header/Inset/Row/Back").text = "‹ " + locale.text("Back")
	get_node(^"Footer/Inset/Row/Cancel").text = locale.text("Cancel")
	get_node(^"Footer/Inset/Row/Save").text = locale.text("Save sheet")
	form.configure(keys, values, locale, phone, identity)
	get_node(^"Body/Pages/Area/FocusInset/Message").visible = keys.is_empty()
	get_node(^"Body/Pages/Area/FocusInset/Message").text = locale.text("This entry was removed or replaced. Its obsolete corrections were discarded.")
	if _identity != identity:
		_identity = identity
		get_node(^"Body/Pages").restore_state({})
	for path in ["Header/Inset/Row/Back", "Header/Inset/Row/Close", "Footer/Inset/Row/Save", "Footer/Inset/Row/Cancel"]:
		var button: Button = get_node(path)
		if not button.text.is_empty():
			button.accessibility_name = button.text
			button.tooltip_text = button.text
		button.text = ""
		button.icon = preload("res://rookframe/ui/icons/check.svg") if path.ends_with("Save") else preload("res://rookframe/ui/icons/back.svg") if path.ends_with("Back") else preload("res://rookframe/ui/icons/close.svg")
		button.theme_type_variation = "SilkPrimaryIcon" if path.ends_with("Save") else "SilkIcon"
		button.custom_minimum_size = Vector2(44,44)
		button.icon_alignment = 1
	configure_density(phone)
	get_node(^"Body/Pages").refresh()
func configure_density(phone: bool) -> void:
	get_node("Header/Inset/Row").add_theme_constant_override("separation", 8 if phone else 12)
	for edge in ["left", "right"]:
		get_node("Header/Inset").add_theme_constant_override("margin_" + edge, 0 if phone else 6)
		get_node("Footer/Inset").add_theme_constant_override("margin_" + edge, 0 if phone else 14)
	for edge in ["top", "bottom"]:
		get_node("Footer/Inset").add_theme_constant_override("margin_" + edge, 4 if phone else 12)
	var pager = _pager
	pager.size_flags_horizontal = 8
	pager.custom_minimum_size = Vector2(0,44)
	_range.add_theme_font_size_override("font_size", 16)
	CHROME.new().icon_action(_previous, "chevron-left")
	CHROME.new().icon_action(_next, "chevron-right")
	get_node("Footer/Inset/Row/Pager").alignment = 2

	get_node("Header/Inset").add_theme_constant_override("margin_bottom", 5 if phone else 0)
	get_node(^"Header/Inset/Row/Close").visible = not phone
	get_node(^"Header").custom_minimum_size = Vector2(0, 49 if phone else 63)
	get_node(^"Header/Inset/Row/Title").add_theme_font_size_override("font_size", 23 if phone else 26)
	get_node(^"Footer").custom_minimum_size = Vector2(0, 53 if phone else 68)
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Body").add_theme_constant_override("margin_" + edge, (10 if edge in ["left", "right"] else 8) if phone else 24)
	form.add_theme_constant_override("separation", 12 if phone else 16)
	form.configure_density(phone, 18 if phone and _identity != "core" else 20)
func set_details_pending(active: bool) -> void:
	form.set_fields_pending(active)
	for path in [^"Header/Inset/Row/Back", ^"Header/Inset/Row/Close", ^"Footer/Inset/Row/Save", ^"Footer/Inset/Row/Cancel"]:
		get_node(path).disabled = active
func show_error(key: String, message: String) -> void:
	form.show_error(key, message)
	get_node(^"Body/Pages").refresh()
func paging() -> Dictionary:
	return get_node(^"Body/Pages").capture_state()
func restore_paging(state: Dictionary) -> void:
	get_node(^"Body/Pages").restore_state(state)
func focus_first() -> void:
	form.restore_focus()
