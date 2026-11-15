extends VBoxContainer
## Complete Creature field: the UI Kit text field or text area, unoverridden.

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

## The UI Kit fields keep their World theme look in every density.
func configure_density(_phone: bool) -> void:
	pass

func set_editor_pending(active: bool) -> void:
	get_node(^"Value").editable = not active
	get_node(^"Text").editable = not active
