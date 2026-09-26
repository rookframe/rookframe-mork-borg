extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal save_requested(field: String, text: String)
var field := ""
var initial := ""
func _ready() -> void:
	get_node(^"Actions/Save").pressed.connect(_save)
	get_node(^"Actions/Cancel").pressed.connect(_cancel)
func configure(key: String, title: String, value: String) -> void:
	field = key
	initial = value
	_multiline = key in ["description", "origin", "class_rules", "rules"] or key.ends_with(":rules")
	get_node(^"Field").visible = not _multiline
	get_node(^"Multiline").visible = _multiline
	_editor().label_text = _t(title)
	_editor().value = value
	get_node(^"Actions/Save").accessibility_name = _t("Save %s") % _t(title)
func _save() -> void:
	var text: String = current_value()
	_pending = text
	show_result("Saving…", false, false)
	save_requested.emit(field, text)
func _submitted(_value: String) -> void:
	_save()
func _cancel() -> void:
	_editor().value = initial
	show_result("", false, false)

var _multiline := false
var _pending := ""
func _editor() -> Control:
	return get_node(^"Multiline") if _multiline else get_node(^"Field")
func current_value() -> String:
	return str(_editor().get("value"))
func show_result(message: String, error: bool, saved: bool) -> void:
	var pending := message == "Saving…"
	get_node(^"Actions/Save").disabled = pending
	get_node(^"Actions/Cancel").disabled = pending
	get_node(^"Field").editable = not pending
	get_node(^"Multiline").editable = not pending
	get_node(^"Field").error_text = _t(message) if error else ""
	get_node(^"Multiline").error_text = _t(message) if error else ""
	get_node(^"Field").help_text = _t(message) if not error else ""
	get_node(^"Multiline").help_text = _t(message) if not error else ""
	if saved:
		initial = _pending

func refresh_value(value: String) -> void:
	if current_value() == initial:
		_editor().value = value
	initial = value


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Actions/Cancel").text = _t("Cancel")
	get_node(^"Actions/Save").text = _t("Save")
	get_node(^"Field").label_text = _t("Field label")
	get_node(^"Multiline").label_text = _t("Field label")
