extends Window
## Table-resolved HP adjustment, presented over the unchanged Creature sheet.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const CONTENT := "Panel/Inset/Layout/Content/"
const HEADER := CONTENT + "Header/Inset/Row/"
const BODY := CONTENT + "Body/Rows/"
const AMOUNT := BODY + "AmountRow/Amount"
const ACTIONS := "Panel/Inset/Layout/Actions/"
const OVERFLOW := CONTENT + "Overflow"
signal adjustment_requested(operation: String, amount: String)
signal correction_requested
signal dismissed
@export var input_style: StyleBoxFlat = StyleBoxFlat.new()
@export var focus_style: StyleBoxFlat = StyleBoxFlat.new()
@export var action_style: StyleBoxFlat = StyleBoxFlat.new()
@export var primary_style: StyleBoxFlat = StyleBoxFlat.new()
var _locale := I18N.new()
var _canvas := Vector2(0, 0)
var _layout_pending := false
var _phone := false
var _overflowing := false

func _ready() -> void:
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
	get_node(BODY + "AmountRow/Caption").text = locale.text("Amount")
	get_node(HEADER + "Copy/Title").text = locale.text("Hit points")
	get_node(HEADER + "Close").accessibility_name = locale.text("Close")
	get_node(ACTIONS + "Damage").text = locale.text("Apply damage")
	get_node(ACTIONS + "Heal").text = locale.text("Heal")
	get_node(ACTIONS + "Correct").text = locale.text("Edit sheet")
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
	if not visible or size != extent:
		size = extent
		popup_centered()
	var inset := 12 if _phone else 24
	for edge in ["left", "top", "right", "bottom"]:
		get_node("Panel/Inset").add_theme_constant_override("margin_" + edge, inset)
	get_node("Panel/Inset/Layout").add_theme_constant_override("separation", 8 if _phone else 16)
	get_node(CONTENT + "Header/Inset").add_theme_constant_override("margin_bottom", 6 if _phone else 14)
	get_node(HEADER + "Copy").add_theme_constant_override("separation", 3 if _phone else 6)
	get_node(HEADER + "Copy/Kicker").add_theme_font_size_override("font_size", 9 if _phone else 10)
	get_node(HEADER + "Copy/Kicker").custom_minimum_size = Vector2(0, 14 if _phone else 15)
	get_node(HEADER + "Copy/Title").add_theme_font_size_override("font_size", 20 if _phone else 25)
	get_node(HEADER + "Copy/Title").custom_minimum_size = Vector2(0, 24 if _phone else 30)
	get_node(CONTENT + "Body").add_theme_constant_override("margin_top", 8 if _phone else 16)
	get_node(BODY + "Summary").custom_minimum_size = Vector2(0, 17 if _phone else 24)
	for path in ["Summary", "AmountRow/Caption"]:
		get_node(BODY + path).add_theme_font_size_override("font_size", 12 if _phone else 15)
	var editor: Control = get_node(AMOUNT + "/Editor")
	editor.custom_minimum_size = Vector2(100, 50 if _phone else 55)
	editor.add_theme_font_size_override("font_size", 23)
	editor.add_theme_constant_override("minimum_character_width", 1)
	editor.add_theme_stylebox_override("normal", input_style)
	editor.add_theme_stylebox_override("read_only", input_style)
	editor.add_theme_stylebox_override("focus", focus_style)
	for style in [action_style, primary_style]:
		style.content_margin_left = 13 if _phone else 15
		style.content_margin_right = 13 if _phone else 15
	for action in ["Damage", "Heal", "Correct"]:
		get_node(ACTIONS + action).add_theme_font_size_override("font_size", 12 if _phone else 13)
	_refresh_amount_copy()
	_normal_layout()

func refresh(data: Dictionary, enabled: bool, pending: bool) -> void:
	var valid := HEALTH.new().valid(data)
	var name := _locale.text(str(data.get("name", "Creature")))
	var renamed := str(get_node(HEADER + "Copy/Kicker").text) != name.to_upper()
	get_node(HEADER + "Copy/Kicker").text = name.to_upper()
	accessibility_name = _locale.text("Hit points") + " · " + name
	get_node(BODY + "Summary").text = str(data.get("hit_points", "—")) + " / " + str(data.get("maximum_hit_points", "—")) if valid else _locale.text("HP is unavailable. Use Edit sheet to correct it.")
	get_node(BODY + "AmountRow").visible = valid
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
	_refresh_amount_copy()
	_layout_pending = true

func show_error(message: String, field: String) -> void:
	get_node(OVERFLOW).restore_state({"page": 0})
	get_node(BODY + "Feedback").text = ""
	get_node(BODY + "Feedback").visible = false
	get_node(BODY + "Error").text = _locale.text(message)
	get_node(BODY + "Error").visible = not message.is_empty()
	get_node(AMOUNT).error_text = _locale.text(message)
	_refresh_amount_copy()
	if field == "amount":
		get_node(AMOUNT).focus_editor.call_deferred()
	else:
		_focus_damage.call_deferred()
	_normal_layout()

func _focus_damage() -> void:
	get_node(ACTIONS + "Damage").grab_focus()

func _refresh_amount_copy() -> void:
	# The horizontal amount label and full-width error retain public field state.
	get_node(AMOUNT + "/Label").visible = false
	get_node(AMOUNT + "/Error").visible = false

func _clear_feedback() -> void:
	get_node(AMOUNT).error_text = ""
	get_node(BODY + "Error").text = ""
	get_node(BODY + "Error").visible = false
	get_node(BODY + "Feedback").text = ""
	get_node(BODY + "Feedback").visible = false
	_refresh_amount_copy()
	_normal_layout()

func _normal_layout() -> void:
	_overflowing = false
	get_node(HEADER + "Copy/Kicker").visible = true
	get_node(BODY + "Error").visible = not str(get_node(BODY + "Error").text).is_empty()
	get_node(BODY + "Feedback").visible = not str(get_node(BODY + "Feedback").text).is_empty()
	get_node(OVERFLOW).visible = false
	get_node(CONTENT + "OverflowGap").visible = false
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
			get_node(OVERFLOW + "/Area/Text/Name").add_theme_font_size_override("font_size", 9 if _phone else 10)
			pages.custom_minimum_size = Vector2(0, 0)
			pages.visible = true
			get_node(CONTENT + "OverflowGap").visible = true
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
		get_node("Shadow").position = panel.position
		get_node("Shadow").size = panel.size
		get_node("Surround").position = panel.position
		get_node("Surround").size = panel.size
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
