extends Window
## Table-resolved HP adjustment, presented over the unchanged Creature sheet.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const CHROME = preload(ROOT + "ui/creature_icon_actions.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const CONTENT := "Panel/Inset/Layout/Content/"
const HEADER := CONTENT + "Header/Row/"
const BODY := CONTENT + "Rows/"
const AMOUNT := BODY + "Amount"
const ACTIONS := "Panel/Inset/Layout/Actions/"
const OVERFLOW := CONTENT + "Overflow"
signal adjustment_requested(operation: String, amount: String)
signal correction_requested
signal dismissed
var _locale := I18N.new()
var _canvas := Vector2(0, 0)
var _layout_pending := false
var _phone := false
var _overflowing := false

func _ready() -> void:
	get_node("Panel").item_rect_changed.connect(_fit_material)
	get_node(ACTIONS + "Pager").add_child(get_node(OVERFLOW).get_pager())
	get_node(ACTIONS + "Damage").pressed.connect(_adjust.bind("damage"))
	get_node(ACTIONS + "Heal").pressed.connect(_adjust.bind("heal"))
	get_node(ACTIONS + "Correct").pressed.connect(_correct)
	get_node(HEADER + "Close").pressed.connect(_dismiss)
	get_node(AMOUNT).value_changed.connect(_typed)
	close_requested.connect(_dismiss)

func begin(locale: I18N, data: Dictionary, canvas: Vector2) -> void:
	_locale = locale
	get_node(AMOUNT).value = "1"
	_clear_feedback()
	get_node(AMOUNT).label_text = locale.text("Amount")
	get_node(HEADER + "Copy/Title").text = locale.text("Hit points")
	for pair in [[HEADER + "Close", "Close"], [ACTIONS + "Damage", "Apply damage"], [ACTIONS + "Heal", "Heal Creature HP"], [ACTIONS + "Correct", "Edit sheet"]]:
		var button: Button = get_node(pair[0])
		button.accessibility_name = locale.text(pair[1])
		button.tooltip_text = button.accessibility_name
		CHROME.new().bound_icon(button)
	var previous: Control = get_node(ACTIONS + "Pager").get_child(0).get_node("Previous")
	var next: Control = get_node(ACTIONS + "Pager").get_child(0).get_node("Next")
	previous.accessibility_name = locale.text("Previous page")
	next.accessibility_name = locale.text("Next page")
	get_node(OVERFLOW).restore_state({"page": 0})
	refresh(data, true, false)
	present(canvas)
	get_node(AMOUNT).focus_editor.call_deferred()

func present(canvas: Vector2) -> void:
	_canvas = canvas
	_phone = canvas.y <= 500
	var extent := Vector2i(int(canvas.x), int(canvas.y))
	var opening := not visible
	if opening or size != extent:
		size = extent
		popup_centered()
	if opening:
		_reveal.call_deferred()
	for edge in [&"left", &"top", &"right", &"bottom"]:
		get_node("Panel/Inset").set(edge, &"space_3" if _phone else &"space_5")
	get_node("Panel/Inset/Layout").set(&"gap", &"space_2" if _phone else &"space_4")
	get_node("Panel/Inset/Layout/Content").set(&"gap", &"space_2" if _phone else &"space_4")
	get_node(CONTENT + "Header").set(&"padding_vertical", &"space_1" if _phone else &"space_3")
	get_node(HEADER + "Copy/Title").theme_type_variation = &"RookframeHeading" if _phone else &"RookframeSubtitle"
	get_node(BODY + "Summary").theme_type_variation = &"RookframeHeading" if _phone else &"RookframeValue"
	_normal_layout()

func refresh(data: Dictionary, enabled: bool, pending: bool) -> void:
	var valid := HEALTH.new().valid(data)
	var name := _locale.text(str(data.get("name", "Creature")))
	var renamed := str(get_node(HEADER + "Copy/Kicker").text) != name
	get_node(HEADER + "Copy/Kicker").text = name
	accessibility_name = _locale.text("Hit points") + " · " + name
	get_node(BODY + "Summary").text = str(data.get("hit_points", "—")) + " / " + str(data.get("maximum_hit_points", "—")) if valid else _locale.text("HP is unavailable. Use Edit sheet to correct it.")
	get_node(AMOUNT).visible = valid
	get_node(AMOUNT).editable = enabled and not pending
	for action in ["Damage", "Heal"]:
		get_node(ACTIONS + action).visible = valid
		get_node(ACTIONS + action).disabled = not enabled or pending
	get_node(ACTIONS + "Correct").visible = not valid
	get_node(ACTIONS + "Correct").disabled = not enabled or pending
	if pending:
		get_node(BODY + "Feedback").text = _locale.text("Saving HP…")
		get_node(BODY + "Feedback").visible = true
	if renamed or pending:
		_normal_layout()
	_layout_pending = true

func show_error(message: String, field: String) -> void:
	get_node(OVERFLOW).restore_state({"page": 0})
	get_node(BODY + "Feedback").text = ""
	get_node(BODY + "Feedback").visible = false
	get_node(BODY + "Error").text = _locale.text(message)
	get_node(BODY + "Error").visible = not message.is_empty()
	get_node(AMOUNT).error_text = _locale.text(message) if field == "amount" else ""
	get_node(BODY + "Error").visible = not message.is_empty() and field != "amount"
	if field == "amount":
		get_node(AMOUNT).focus_editor.call_deferred()
	else:
		_focus_damage.call_deferred()
	_normal_layout()

func _focus_damage() -> void:
	get_node(ACTIONS + "Damage").grab_focus()

func _clear_feedback() -> void:
	get_node(AMOUNT).error_text = ""
	get_node(BODY + "Error").text = ""
	get_node(BODY + "Error").visible = false
	get_node(BODY + "Feedback").text = ""
	get_node(BODY + "Feedback").visible = false
	_normal_layout()

func _normal_layout() -> void:
	_overflowing = false
	get_node(HEADER + "Copy/Kicker").visible = true
	get_node(BODY + "Error").visible = not str(get_node(BODY + "Error").text).is_empty() and str(get_node(AMOUNT).error_text).is_empty()
	get_node(BODY + "Feedback").visible = not str(get_node(BODY + "Feedback").text).is_empty()
	get_node(OVERFLOW).visible = false
	get_node(ACTIONS + "Pager").visible = false
	_layout_pending = true

func _typed(_text: String) -> void:
	_clear_feedback()

func _process(_delta: float) -> void:
	if visible and _layout_pending:
		_layout_pending = false
		var panel: Control = get_node("Panel")
		var width := minf(660, _canvas.x - 28)
		var before := panel.size
		panel.size = Vector2(width, 0)
		var height := panel.get_combined_minimum_size().y
		var pages: Control = get_node(OVERFLOW)
		if not _overflowing and height > _canvas.y - 28:
			# Complete long identity/error text uses the existing bounded native pages.
			# Amount, summary, Close and adjustment actions remain fixed and reachable.
			_overflowing = true
			var source: Label = get_node(HEADER + "Copy/Kicker")
			var target: Label = get_node(OVERFLOW + "/Area/Text/Name")
			target.text = source.text
			target.visible = true
			source.visible = false
			get_node(OVERFLOW + "/Area/Text/Error").visible = false
			get_node(OVERFLOW + "/Area/Text/Feedback").visible = false
			pages.custom_minimum_size = Vector2(0, 0)
			pages.visible = true
			get_node(ACTIONS + "Pager").visible = true
			_layout_pending = true
			return
		if _overflowing:
			var fixed_height := height - pages.custom_minimum_size.y
			if fixed_height > _canvas.y - 72:
				for item in ["Error", "Feedback"]:
					var source: Label = get_node(BODY + item)
					var target: Label = get_node(OVERFLOW + "/Area/Text/" + item)
					if source.visible:
						target.text = source.text
						target.visible = true
						source.visible = false
						_layout_pending = true
				if _layout_pending:
					return
			pages.custom_minimum_size = Vector2(0, maxf(44, _canvas.y - 28 - fixed_height))
			height = panel.get_combined_minimum_size().y
			pages.refresh()
		panel.size = Vector2(width, height)
		panel.position = Vector2((_canvas.x - width) / 2, (_canvas.y - height) / 2)
		if before != panel.size:
			_layout_pending = true

func discard() -> void:
	if visible:
		hide()
	_clear_feedback()

func _dismiss() -> void:
	discard()
	dismissed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		_dismiss()

func _adjust(operation: String) -> void:
	_clear_feedback()
	adjustment_requested.emit(operation, str(get_node(AMOUNT).value))

func _correct() -> void:
	discard()
	correction_requested.emit()

func _fit_material() -> void:
	var panel: Control = get_node("Panel")
	get_node("Frame").set_sections(Rect2(), Rect2(panel.position.x, panel.position.y, panel.size.x, panel.size.y))


func _reveal() -> void:
	if visible:
		get_node("Frame").reveal(get_node("Panel/Inset"))
