extends VBoxContainer

signal changed(field: String, text: String)
signal submitted(field: String, text: String)
var _field := ""
var _initial := ""
var _multiline := false
var _setting := false

func _ready() -> void:
	get_node(^"Value").value_changed.connect(_typed)
	get_node(^"Text").value_changed.connect(_typed)
	get_node(^"Save").pressed.connect(_submit)

func _submit() -> void:
	submitted.emit(_field, current_value())

func configure(field: String, title: String, value: String, multiline: bool = false, independent: bool = false) -> void:
	_field = field
	_initial = value
	_multiline = multiline
	get_node(^"Title").text = title
	get_node(^"Value").visible = not multiline
	get_node(^"Text").visible = multiline
	get_node(^"Save").visible = independent
	get_node(^"Save").text = "Save " + title
	_setting = true
	get_node(^"Value").value = value
	get_node(^"Text").value = value
	_setting = false

func current_value() -> String:
	return str(get_node(^"Text").value) if _multiline else str(get_node(^"Value").value)

func refresh_value(value: String) -> void:
	if current_value() == _initial:
		_setting = true
		get_node(^"Value").value = value
		get_node(^"Text").value = value
		_setting = false
	_initial = value

func _typed(text: String) -> void:
	if not _setting:
		changed.emit(_field, text)
