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
@onready var _previous: Button = get_node("Body/Pages/Pager/Previous")
@onready var _next: Button = get_node("Body/Pages/Pager/Next")
@onready var form: FORM = get_node(^"Body/Pages/Area/FocusInset/Form")
func _ready() -> void:
	get_node(^"Header/Inset/Row/Back").pressed.connect(_back)
	get_node(^"Header/Inset/Row/Close").pressed.connect(_back)
	get_node(^"Footer/Row/Save").pressed.connect(_save)
	get_node(^"Footer/Row/Cancel").pressed.connect(_cancel)
	form.changed.connect(_changed)
	var pager = _pager
	get_node(^"Body/Pages").get_pager()
	get_node(^"Footer/Row/Pager").add_child(pager)
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
	form.configure(keys, values, locale, phone, identity)
	get_node(^"Body/Pages/Area/FocusInset/Message").visible = keys.is_empty()
	get_node(^"Body/Pages/Area/FocusInset/Message").text = locale.text("This entry was removed or replaced. Its obsolete corrections were discarded.")
	if _identity != identity:
		_identity = identity
		get_node(^"Body/Pages").restore_state({})
	for pair in [["Header/Inset/Row/Back", "Back"], ["Header/Inset/Row/Close", "Back to creature"], ["Footer/Row/Save", "Save sheet"], ["Footer/Row/Cancel", "Cancel"]]:
		var button: Button = get_node(pair[0])
		button.accessibility_name = locale.text(pair[1])
		button.tooltip_text = button.accessibility_name
	configure_density(phone)
	get_node(^"Body/Pages").refresh()

func configure_density(phone: bool) -> void:
	get_node("Header/Inset/Row").set(&"gap", &"space_2" if phone else &"space_3")
	for edge in [&"left", &"right"]:
		get_node("Header/Inset").set(edge, &"" if phone else &"space_2")
	get_node("Footer").set(&"padding_horizontal", &"" if phone else &"space_3")
	get_node("Footer").set(&"padding_vertical", &"space_1" if phone else &"space_3")
	var pager = _pager
	pager.size_flags_horizontal = Control.SIZE_SHRINK_END
	CHROME.new().icon_action(_previous, "chevron-left")
	CHROME.new().icon_action(_next, "chevron-right")
	get_node(^"Header/Inset/Row/Close").visible = not phone
	get_node(^"Header/Inset/Row/Title").theme_type_variation = &"RookframeLabel" if phone else &"RookframeHeading"
	for edge in [&"left", &"right", &"top", &"bottom"]:
		get_node(^"Body").set(edge, &"space_2" if phone else &"space_5")
	form.gap = &"space_3" if phone else &"space_4"
	form.configure_density(phone)

func set_details_pending(active: bool) -> void:
	form.set_fields_pending(active)
	for path in [^"Header/Inset/Row/Back", ^"Header/Inset/Row/Close", ^"Footer/Row/Save", ^"Footer/Row/Cancel"]:
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
