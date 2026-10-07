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

func sync_draft_value(value: String) -> void:
	if current_value() != value:
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

func configure_layout(phone: bool) -> void:
	for path in [^"Value", ^"Text"]:
		get_node(path).add_theme_constant_override("separation", 4 if phone else 6)
		var editor: Control = get_node("Text/Editor") if path == ^"Text" else get_node("Value/Editor")
		editor.custom_minimum_size = Vector2(0, 96 if path == ^"Text" else 48)
		editor.add_theme_font_size_override("font_size", 18 if phone else 20)
		var label: Label = get_node("Text/Label") if path == ^"Text" else get_node("Value/Label")
		label.theme_type_variation = "SilkCreatureHealthTitlePhone" if phone else "SilkCreatureDialogSummaryPhone"
		label.add_theme_font_size_override("font_size", 15 if phone else 18)
		label.add_theme_color_override("font_color", Color(0.682353,0.729412,0.745098,1))
	for caption in [^"Value/Help", ^"Value/Error", ^"Text/Help", ^"Text/Error"]:
		get_node(caption).add_theme_font_size_override("font_size", 15 if phone else 18)

func has_editor_focus() -> bool:
	return get_node(^"Text").is_editor_focused() if _multiline else get_node(^"Value").is_editor_focused()

func restore_editor_focus() -> void:
	_focus_editor()
