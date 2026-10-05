extends VBoxContainer
const FORM = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_correction_form.gd")
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal back_requested
signal save_requested
signal cancel_requested
signal changed(field: String, text: String)
var _identity := ""
@onready var form: FORM = get_node(^"Body/Pages/Area/FocusInset/Form")
func _ready() -> void:
	get_node(^"Header/Inset/Row/Back").pressed.connect(_back)
	get_node(^"Header/Inset/Row/Close").pressed.connect(_back)
	get_node(^"Footer/Inset/Row/Save").pressed.connect(_save)
	get_node(^"Footer/Inset/Row/Cancel").pressed.connect(_cancel)
	form.changed.connect(_changed)
	var pager = get_node(^"Body/Pages").get_pager()
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
	form.configure(keys, values, locale, phone and identity != "core", identity)
	get_node(^"Body/Pages/Area/FocusInset/Message").visible = keys.is_empty()
	get_node(^"Body/Pages/Area/FocusInset/Message").text = locale.text("This entry was removed or replaced. Its obsolete corrections were discarded.")
	if _identity != identity:
		_identity = identity
		get_node(^"Body/Pages").restore_state({})
	configure_density(phone)
	get_node(^"Body/Pages").refresh()
func configure_density(phone: bool) -> void:
	get_node(^"Header/Inset/Row/Close").visible = not phone
	get_node(^"Header").custom_minimum_size = Vector2(0, 46 if phone else 63)
	get_node(^"Header/Inset/Row/Title").add_theme_font_size_override("font_size", 17 if phone else 22)
	get_node(^"Footer").custom_minimum_size = Vector2(0, 60 if phone else 68)
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Body").add_theme_constant_override("margin_" + edge, (16 if edge in ["left", "right"] else 12) if phone else 24)
	form.add_theme_constant_override("separation", 12 if phone else 16)
	form.configure_density(phone and _identity != "core")
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
