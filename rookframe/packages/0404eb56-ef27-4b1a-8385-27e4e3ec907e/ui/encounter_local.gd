extends Resource
## Participant-local view state shared by this Package's authored controls.
signal updated
var selected_rook := ""
var options := false
var panel_visible := false
var panel_rect := Rect2(0, 0, 0, 0)

func select_rook(id: String) -> void:
	selected_rook = id
	options = false
	updated.emit()

func show_options() -> void:
	options = true
	updated.emit()

func panel_changed(value: bool) -> void:
	if panel_visible != value:
		panel_visible = value
		updated.emit()

func reset() -> void:
	selected_rook = ""
	options = false
	panel_visible = false

func hide_options() -> void:
	options = false

func panel_bounds(value: Rect2) -> void:
	if panel_rect != value:
		panel_rect = value
		updated.emit()
