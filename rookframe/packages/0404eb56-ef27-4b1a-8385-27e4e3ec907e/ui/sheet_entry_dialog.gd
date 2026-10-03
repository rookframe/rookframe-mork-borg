extends Window
signal close_requested_by_user
signal escape_requested

func _ready() -> void:
	close_requested.connect(_close)

func present(active: bool, canvas: Vector2, presentation: String = "entry") -> void:
	if not active:
		if visible:
			hide()
		return
	var height := 790 if presentation == "note" else 410 if presentation == "number" else 610
	var extent := Vector2i(int(minf(640, canvas.x - 80)), int(minf(height, canvas.y - 70)))
	if not visible or size != extent:
		size = extent
		popup_centered()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		escape_requested.emit()

func _close() -> void:
	close_requested_by_user.emit()
