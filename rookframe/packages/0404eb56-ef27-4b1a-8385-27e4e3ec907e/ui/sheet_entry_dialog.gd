extends Window
signal close_requested_by_user
signal escape_requested

func _ready() -> void:
	close_requested.connect(_close)
	get_node(^"Surface").item_rect_changed.connect(_fit_material)
	_fit_material()

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

func _fit_material() -> void:
	get_node("Frame").set_sections(Rect2(), get_node("Surface").get_global_rect())
	var frame := get_node("Surface").get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	frame.bg_color = Color(0, 0, 0, 0)
	frame.set_border_width_all(0)
	for side in range(4): frame.set_content_margin(side, 12)
	get_node("Surface").add_theme_stylebox_override("panel", frame)
