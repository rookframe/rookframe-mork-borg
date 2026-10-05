extends VBoxContainer
## Complete Creature field with retained native editor and exact authored presentation.

signal changed(field: String, text: String)
var _field := ""
var _multiline := false
var _setting := false

func _ready() -> void:
	get_node(^"Value").value_changed.connect(_typed)
	get_node(^"Text").value_changed.connect(_typed)

func configure(field: String, title: String, value: String, multiline: bool = false) -> void:
	_field = field
	_multiline = multiline
	get_node(^"Value").label_text = title
	get_node(^"Text").label_text = title
	get_node(^"Value").visible = not multiline
	get_node(^"Text").visible = multiline
	_setting = true
	get_node(^"Value").value = value
	get_node(^"Text").value = value
	_setting = false

func current_value() -> String:
	return str(get_node(^"Text").value) if _multiline else str(get_node(^"Value").value)

func sync_draft_value(value: String) -> void:
	if current_value() != value:
		_setting = true
		get_node(^"Value").value = value
		get_node(^"Text").value = value
		_setting = false

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

func has_editor_focus() -> bool:
	return get_node(^"Text").is_editor_focused() if _multiline else get_node(^"Value").is_editor_focused()

func restore_editor_focus() -> void:
	_focus_editor()

# The input style offset is 9px: its 1px border plus 8px interior padding.
@export var input_style: StyleBoxFlat = StyleBoxFlat.new()
@export var focus_style: StyleBoxFlat = StyleBoxFlat.new()

func configure_density(phone: bool) -> void:
	for path in [^"Value", ^"Text"]:
		var editor: Control = get_node(^"Text/Editor") if path == ^"Text" else get_node(^"Value/Editor")
		editor.custom_minimum_size = Vector2(0, 88 if path == ^"Text" else 44)
		editor.add_theme_font_size_override("font_size", 12 if phone else 14)
		editor.add_theme_color_override("font_color", Color(0.85098, 0.831373, 0.819608, 1))
		editor.add_theme_stylebox_override("normal", input_style)
		editor.add_theme_stylebox_override("read_only", input_style)
		editor.add_theme_stylebox_override("focus", focus_style)
		var caption: Label = get_node(^"Text/Label") if path == ^"Text" else get_node(^"Value/Label")
		caption.add_theme_font_size_override("font_size", 12)
		caption.add_theme_color_override("font_color", Color(0.603922, 0.647059, 0.65098, 1))
		var error: Label = get_node(^"Text/Error") if path == ^"Text" else get_node(^"Value/Error")
		error.add_theme_font_size_override("font_size", 12)

func set_editor_pending(active: bool) -> void:
	get_node(^"Value").editable = not active
	get_node(^"Text").editable = not active
