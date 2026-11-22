extends Control
## Break shield or take the damage, presented by the UI Kit Dialog.
##
## The Dialog owns the modal Window, scrim, heading, copy and footer. Break
## shield is its danger confirmation and Cancel ends the action; taking the
## damage is this Package's own action in the Dialog body.

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal choice_requested(choice: String)
signal cancelled
var _take: Button

func _enter_tree() -> void:
	if not get_viewport().size_changed.is_connected(_fill):
		get_viewport().size_changed.connect(_fill)
	_fill()

func _exit_tree() -> void:
	get_viewport().size_changed.disconnect(_fill)

func _ready() -> void:
	var take := _take_button()
	remove_child(take)
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialog().get_body_slot().add_child(take)
	take.pressed.connect(_choose.bind("take"))
	_dialog().confirmed.connect(_choose.bind("break"))
	_dialog().cancelled.connect(_cancel)

func present(outcome: Dictionary) -> void:
	var loss: int = outcome.loss
	var hp: int = outcome.hp
	_dialog().description = _t("%s will take %d damage (%d → %d HP).\n\nBreak your shield to take no damage instead.") % [str(outcome.character), loss, hp, hp - loss]
	_take_button().text = _t("Take %d damage") % loss
	if not _dialog().visible:
		_dialog().open_dialog()
		_focus_take()

func set_pending(value: bool) -> void:
	_take_button().disabled = value
	_dialog().confirm_enabled = not value

func dismiss() -> void:
	_dialog().hide()

func _choose(choice: String) -> void:
	set_pending(true)
	choice_requested.emit(choice)

func _cancel() -> void:
	cancelled.emit()

## The Dialog opens without a focused action and settles its size over the
## next frames. Taking the damage stays the keyboard default afterwards.
func _focus_take() -> void:
	for frame in 3:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	if is_inside_tree() and _dialog().visible and not _take_button().disabled:
		_take_button().grab_focus()

## The Dialog dims its parent Control, so this one covers the whole canvas.
func _fill() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _dialog() -> Node:
	return get_node(^"Dialog")

func _take_button() -> Button:
	if _take == null:
		_take = get_node(^"Take")
	return _take

func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	_dialog().heading = _t("Break shield?")
	_dialog().confirm_label = _t("Break shield")
	_dialog().cancel_label = _t("Cancel")
	_take_button().text = _t("Take 2 damage")
