extends VBoxContainer

signal changed(field: String, text: String)
signal submitted(field: String, text: String)
var _field := ""
var _initial := ""
var _multiline := false
var _setting := false
var _phone := false
var _profile := false

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
	get_node(^"Value").label_text = title
	get_node(^"Text").label_text = title
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
		get_node(^"Value").error_text = ""
		get_node(^"Text").error_text = ""
		changed.emit(_field, text)

func show_error(message: String) -> void:
	get_node(^"Value").error_text = message
	get_node(^"Text").error_text = message
	_focus_editor.call_deferred()

func _focus_editor() -> void:
	if _multiline:
		get_node(^"Text").focus_editor()
	else:
		get_node(^"Value").focus_editor()

func configure_layout(phone: bool, profile: bool = false) -> void:
	_phone = phone
	_profile = profile
	for path in [^"Value", ^"Text"]:
		get_node(path).add_theme_constant_override("label_font_size", 12 if phone else 15)
		get_node(path).add_theme_constant_override("editor_font_size", 15 if phone else 16)
		get_node(path).add_theme_constant_override("editor_minimum_height", (80 if profile else 124) if phone else 160)
		get_node(path).compact = phone

func has_editor_focus() -> bool:
	return get_node(^"Text").is_editor_focused() if _multiline else get_node(^"Value").is_editor_focused()

func restore_editor_focus() -> void:
	_focus_editor()
