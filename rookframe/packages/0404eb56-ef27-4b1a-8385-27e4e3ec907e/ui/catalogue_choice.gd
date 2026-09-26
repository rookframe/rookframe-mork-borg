extends Button

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal navigation(direction: int, boundary: bool)
var title := ""

func _ready() -> void:
	get_node("Content/Copy/Title").text = _t(title)
	get_node("Content/Copy/Description").visible = false
	accessibility_name = _t(title)
	get_node("Content/Copy/Title").resized.connect(_fit_title)
	_fit_title()

func _fit_title() -> void:
	custom_minimum_size = Vector2(0, maxf(52, get_node("Content/Copy/Title").size.y + 24))

func set_selected(chosen: bool) -> void:
	button_pressed = chosen
	get_node("Content/State").text = _t("Selected") if chosen else _t("Select")
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


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Content/Copy/Description").text = _t("Supporting decision copy")
	get_node(^"Content/Copy/Title").text = _t("Choice")
	get_node(^"Content/State").text = _t("Select")
