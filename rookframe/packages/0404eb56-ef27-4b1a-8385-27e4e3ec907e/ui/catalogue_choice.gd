extends Button

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal navigation(direction: int, boundary: bool)
var title := ""
const TOKENS := &"RookframeTokens"

func _ready() -> void:
	get_node("Content/Row/Copy/Title").text = _t(title)
	get_node("Content/Row/Copy/Description").visible = false
	accessibility_name = _t(title)
	get_node("Content/Row/Copy/Title").resized.connect(_fit_title)
	_read_tokens()

func _fit_title() -> void:
	custom_minimum_size = Vector2(0, maxf(get_theme_constant(&"action_height", TOKENS), get_node("Content/Row/Copy/Title").size.y + 2 * get_theme_constant(&"space_3", TOKENS)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_read_tokens()

## The selected mark is a check in `accent_content` on an `accent` pill.
func _read_tokens() -> void:
	var check := get_node(^"Content/Row/IndicatorLane/Indicator/Check") as TextureRect
	check.custom_minimum_size = Vector2(get_theme_constant(&"icon_small", TOKENS), get_theme_constant(&"icon_small", TOKENS))
	check.self_modulate = get_theme_color(&"accent_content", TOKENS)
	# The lane keeps its width so choosing a row does not shift the title.
	get_node(^"Content/Row/IndicatorLane").custom_minimum_size = Vector2(check.custom_minimum_size.x + 2 * get_theme_constant(&"space_1", TOKENS), 0)
	_fit_title()

func set_selected(chosen: bool) -> void:
	button_pressed = chosen
	get_node("Content/Row/State").text = _t("Selected") if chosen else _t("Select")
	get_node("Content/Row/IndicatorLane/Indicator").visible = chosen
	accessibility_description = _t("Selected") if chosen else _t("Not selected")

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
	get_node(^"Content/Row/Copy/Description").text = _t("Supporting decision copy")
	get_node(^"Content/Row/Copy/Title").text = _t("Choice")
	get_node(^"Content/Row/State").text = _t("Select")
