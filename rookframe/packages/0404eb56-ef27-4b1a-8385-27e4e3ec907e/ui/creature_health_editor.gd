extends Control
## Table-resolved HP adjustment, presented over the unchanged Creature sheet.
##
## The UI Kit Dialog owns the modal Window, scrim, heading and its Close
## action. The amount, the two adjustments and their feedback are this
## Package's content in the Dialog body. This Control is visible exactly while
## the editor is open, also while the Dialog settles or is fitted again.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const KICKER := "Kicker"
const BODY := "Rows/"
const ACTIONS := "Actions/"
const AMOUNT := ACTIONS + "Amount"
const OVERFLOW := "Overflow"
## Frames the Dialog takes to fit its size after it opens.
const DIALOG_SETTLE_FRAMES := 3
signal adjustment_requested(operation: String, amount: String)
signal correction_requested
signal dismissed
var _locale := I18N.new()
var _layout_pending := false
var _overflowing := false
var _settling := 0
var _focus_amount := false
@onready var _dialog := get_node(^"Dialog")
@onready var _content: Control = get_node(^"Content")

func _enter_tree() -> void:
	if not get_viewport().size_changed.is_connected(_fill):
		get_viewport().size_changed.connect(_fill)
	_fill()

func _exit_tree() -> void:
	get_viewport().size_changed.disconnect(_fill)

func _ready() -> void:
	remove_child(_content)
	_dialog.get_body_slot().add_child(_content)
	_part(ACTIONS + "Pager").add_child(_part(OVERFLOW).get_pager())
	_part(ACTIONS + "Damage").pressed.connect(_adjust.bind("damage"))
	_part(ACTIONS + "Heal").pressed.connect(_adjust.bind("heal"))
	_part(ACTIONS + "Correct").pressed.connect(_correct)
	_part(AMOUNT).value_changed.connect(_typed)
	_part("Escape").pressed.connect(_dismiss)
	_dialog.confirmed.connect(_dismiss)
	_dialog.cancelled.connect(_dismiss)

func begin(locale: I18N, data: Dictionary, canvas: Vector2) -> void:
	_locale = locale
	_part(AMOUNT).value = "1"
	_clear_feedback()
	_part(AMOUNT).label_text = locale.text("Amount")
	_dialog.heading = locale.text("Hit points")
	_dialog.confirm_label = locale.text("Close")
	for pair in [[ACTIONS + "Damage", "Apply damage"], [ACTIONS + "Heal", "Heal Creature HP"], [ACTIONS + "Correct", "Edit sheet"]]:
		var button: Button = _part(pair[0])
		button.accessibility_name = locale.text(pair[1])
		button.tooltip_text = button.accessibility_name
	var previous: Control = _part(ACTIONS + "Pager").get_child(0).get_node("Previous")
	var next: Control = _part(ACTIONS + "Pager").get_child(0).get_node("Next")
	previous.accessibility_name = locale.text("Previous page")
	next.accessibility_name = locale.text("Next page")
	_part(OVERFLOW).restore_state({"page": 0})
	refresh(data, true, false)
	visible = true
	present(canvas)

## Opens the Dialog, or fits an open one to a changed canvas. The Dialog
## releases focus once it has settled, so the amount takes it afterwards.
func present(canvas: Vector2) -> void:
	if not visible:
		return
	_part(BODY + "Summary").theme_type_variation = &"RookframeHeading" if canvas.y <= 500 else &"RookframeValue"
	_normal_layout()
	_dialog.open_dialog()
	_settling = DIALOG_SETTLE_FRAMES
	_focus_amount = true

func refresh(data: Dictionary, enabled: bool, pending: bool) -> void:
	var valid := HEALTH.new().valid(data)
	var name := _locale.text(str(data.get("name", "Creature")))
	var renamed := str(_part(KICKER).text) != name
	_part(KICKER).text = name
	_part(BODY + "Summary").text = str(data.get("hit_points", "—")) + " / " + str(data.get("maximum_hit_points", "—")) if valid else _locale.text("HP is unavailable. Use Edit sheet to correct it.")
	_part(AMOUNT).visible = valid
	_part(AMOUNT).editable = enabled and not pending
	for action in ["Damage", "Heal"]:
		_part(ACTIONS + action).visible = valid
		_part(ACTIONS + action).disabled = not enabled or pending
	_part(ACTIONS + "Correct").visible = not valid
	_part(ACTIONS + "Correct").disabled = not enabled or pending
	if pending:
		_part(BODY + "Feedback").text = _locale.text("Saving HP…")
		_part(BODY + "Feedback").visible = true
	if renamed or pending:
		_normal_layout()
	_layout_pending = true

func show_error(message: String, field: String) -> void:
	_part(OVERFLOW).restore_state({"page": 0})
	_part(BODY + "Feedback").text = ""
	_part(BODY + "Feedback").visible = false
	_part(BODY + "Error").text = _locale.text(message)
	_part(BODY + "Error").visible = not message.is_empty()
	_part(AMOUNT).error_text = _locale.text(message) if field == "amount" else ""
	_part(BODY + "Error").visible = not message.is_empty() and field != "amount"
	if field == "amount":
		_part(AMOUNT).focus_editor.call_deferred()
	else:
		_focus_damage.call_deferred()
	_normal_layout()

func _focus_damage() -> void:
	_part(ACTIONS + "Damage").grab_focus()

func _clear_feedback() -> void:
	_part(AMOUNT).error_text = ""
	_part(BODY + "Error").text = ""
	_part(BODY + "Error").visible = false
	_part(BODY + "Feedback").text = ""
	_part(BODY + "Feedback").visible = false
	_normal_layout()

func _normal_layout() -> void:
	_overflowing = false
	_part(KICKER).visible = true
	_part(BODY + "Error").visible = not str(_part(BODY + "Error").text).is_empty() and str(_part(AMOUNT).error_text).is_empty()
	_part(BODY + "Feedback").visible = not str(_part(BODY + "Feedback").text).is_empty()
	_part(OVERFLOW).visible = false
	_part(ACTIONS + "Pager").visible = false
	_layout_pending = true

func _typed(_text: String) -> void:
	_clear_feedback()

func _process(_delta: float) -> void:
	if not visible or not _dialog.visible:
		return
	if _settling > 0:
		_settling -= 1
		return
	if _focus_amount:
		_focus_amount = false
		if _part(AMOUNT).visible and _part(AMOUNT).editable:
			_part(AMOUNT).focus_editor()
	if _layout_pending:
		_layout_pending = false
		var room := float(_dialog.size.y)
		var height: float = _dialog.get_contents_minimum_size().y
		var pages: Control = _part(OVERFLOW)
		if not _overflowing and height > room:
			# Complete long identity/error text uses the existing bounded native pages.
			# Amount, summary, Close and adjustment actions remain fixed and reachable.
			_overflowing = true
			var source: Label = _part(KICKER)
			var target: Label = _part(OVERFLOW + "/Area/Text/Name")
			target.text = source.text
			target.visible = true
			source.visible = false
			_part(OVERFLOW + "/Area/Text/Error").visible = false
			_part(OVERFLOW + "/Area/Text/Feedback").visible = false
			pages.custom_minimum_size = Vector2(0, 0)
			pages.visible = true
			_part(ACTIONS + "Pager").visible = true
			_layout_pending = true
			return
		if _overflowing:
			var fixed_height := height - pages.custom_minimum_size.y
			if fixed_height > room - 44:
				for item in ["Error", "Feedback"]:
					var source: Label = _part(BODY + item)
					var target: Label = _part(OVERFLOW + "/Area/Text/" + item)
					if source.visible:
						target.text = source.text
						target.visible = true
						source.visible = false
						_layout_pending = true
				if _layout_pending:
					return
			var page_height := maxf(44, room - fixed_height)
			if pages.custom_minimum_size.y != page_height:
				pages.custom_minimum_size = Vector2(0, page_height)
				_layout_pending = true
			pages.refresh()

func discard() -> void:
	if _dialog.visible:
		_dialog.hide()
	visible = false
	_clear_feedback()

func _dismiss() -> void:
	discard()
	dismissed.emit()

func _adjust(operation: String) -> void:
	_clear_feedback()
	adjustment_requested.emit(operation, str(_part(AMOUNT).value))

func _correct() -> void:
	discard()
	correction_requested.emit()

## The Dialog dims its parent Control, so this one covers the whole canvas.
func _fill() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _part(path: String) -> Node:
	return _content.get_node(path)
