extends VBoxContainer
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
	_editor().label_text = title
	_editor().value = value
	get_node(^"Actions/Save").accessibility_name = "Save " + title
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
	get_node(^"Field").error_text = message if error else ""
	get_node(^"Multiline").error_text = message if error else ""
	get_node(^"Field").help_text = message if not error else ""
	get_node(^"Multiline").help_text = message if not error else ""
	if saved:
		initial = _pending

func refresh_value(value: String) -> void:
	if current_value() == initial:
		_editor().value = value
	initial = value
