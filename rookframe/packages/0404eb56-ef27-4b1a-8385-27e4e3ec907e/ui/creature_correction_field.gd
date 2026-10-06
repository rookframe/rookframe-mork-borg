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
	_refresh_error_copy()

func _typed(text: String) -> void:
	if not _setting:
		get_node(^"Value").error_text = ""
		get_node(^"Text").error_text = ""
		_refresh_error_copy()
		changed.emit(_field, text)

func show_error(message: String) -> void:
	get_node(^"Value").error_text = message
	get_node(^"Text").error_text = message
	_refresh_error_copy()
	_focus_editor.call_deferred()

func _refresh_error_copy() -> void:
	# Keep the public field's validation/accessibility state; this Creature copy
	# already contains its complete localized message.
	get_node(^"Value/Error").text = get_node(^"Value").error_text
	get_node(^"Text/Error").text = get_node(^"Text").error_text

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

func configure_density(phone: bool, input_size: int = 20) -> void:
	for path in [^"Value", ^"Text"]:
		var editor: Control = get_node(^"Text/Editor") if path == ^"Text" else get_node(^"Value/Editor")
		editor.custom_minimum_size = Vector2(0, 96 if path == ^"Text" else 48)
		editor.add_theme_font_size_override("font_size", input_size)
		editor.add_theme_color_override("font_color", Color(0.905882,0.905882,0.866667, 1))
		editor.add_theme_stylebox_override("normal", input_style)
		editor.add_theme_stylebox_override("read_only", input_style)
		editor.add_theme_stylebox_override("focus", focus_style)
		var caption: Label = get_node(^"Text/Label") if path == ^"Text" else get_node(^"Value/Label")
		caption.add_theme_font_size_override("font_size", 15 if phone else 18)
		caption.theme_type_variation = "SilkCreatureHealthTitlePhone" if phone else "SilkCreatureDialogSummaryPhone"
		get_node(path).add_theme_constant_override("separation", 4 if phone else 6)
		caption.add_theme_color_override("font_color", Color(0.682353,0.729412,0.745098, 1))
		var error: Label = get_node(^"Text/Error") if path == ^"Text" else get_node(^"Value/Error")
		error.add_theme_font_size_override("font_size", 18)

func set_editor_pending(active: bool) -> void:
	get_node(^"Value").editable = not active
	get_node(^"Text").editable = not active
	_refresh_error_copy()
