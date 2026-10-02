extends VBoxContainer
## A native editor and its adjacent validation lane share the same allocation.

func _ready() -> void:
	get_node(^"Editor").visibility_changed.connect(_sync_visibility)
	get_node(^"Editor").text_changed.connect(_edited)
	_sync_visibility()

func show_error(message: String) -> void:
	get_node(^"Error").text = "Error: " + message if not message.is_empty() else ""
	get_node(^"Error").visible = not message.is_empty()
	get_node(^"Editor").accessibility_description = message

func _edited(_value: String) -> void:
	show_error("")

func _sync_visibility() -> void:
	visible = get_node(^"Editor").visible
