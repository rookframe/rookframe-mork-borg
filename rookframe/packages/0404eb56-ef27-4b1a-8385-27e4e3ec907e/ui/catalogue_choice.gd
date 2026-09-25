extends Button
signal navigation(direction: int, boundary: bool)
var title := ""

func _ready() -> void:
	get_node("Content/Copy/Title").text = title
	get_node("Content/Copy/Description").visible = false
	accessibility_name = title
	get_node("Content/Copy/Title").resized.connect(_fit_title)
	_fit_title()

func _fit_title() -> void:
	custom_minimum_size = Vector2(0, maxf(52, get_node("Content/Copy/Title").size.y + 24))

func set_selected(chosen: bool) -> void:
	button_pressed = chosen
	get_node("Content/State").text = "Selected" if chosen else "Select"
	get_node("Content/IndicatorLane/Indicator").visible = chosen
	accessibility_description = "Selected" if chosen else "Not selected"

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		navigation.emit(1, false)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		navigation.emit(-1, false)
	elif event.is_action_pressed("ui_home"):
		navigation.emit(0, true)
	elif event.is_action_pressed("ui_end"):
		navigation.emit(-1, true)
	else:
		return
	accept_event()
