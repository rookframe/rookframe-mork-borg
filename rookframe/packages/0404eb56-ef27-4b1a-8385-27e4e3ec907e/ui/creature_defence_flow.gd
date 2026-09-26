extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTION = preload(ROOT + "logic/defence_action.gd")
const VIEW = preload(ROOT + "ui/defence_view.gd")
const SHIELD = preload(ROOT + "ui/shield_dialog.gd")
signal changed(state: String, can_roll: bool, automatic_hit: bool)
signal resolved
signal decision_closed
signal access_lost
var _sdk: SDK
var _action: ACTION
var _update_pending := false
@onready var _view: VIEW = get_node(^"CompanionDefenceView")
@onready var _shield: SHIELD = get_node(^"Shield")
@onready var _backdrop: CanvasLayer = get_node(^"Backdrop")

func _ready() -> void:
	_shield.choice_requested.connect(_choose)
	_shield.cancelled.connect(close)

func present(sdk: SDK, outcome: Dictionary) -> void:
	_sdk = sdk
	if not _sdk.world_changed.is_connected(_changed):
		_sdk.world_changed.connect(_changed)
	if _action != null:
		if str(_action.snapshot.get("id", "")) == str(outcome.id):
			return
		_action.retire()
	var action := ACTION.new(sdk)
	add_child(action)
	_action = action
	_action.changed.connect(_changed)
	_action.adopt(outcome)

func _changed() -> void:
	_update_pending = true

func _process(_delta: float) -> void:
	if not _update_pending or _action == null:
		return
	_update_pending = false
	var action := _action
	var target := _sdk.actors.read(SDK.ActorId.new(str(action.snapshot.target)))
	if not target.ok or target.actor == null or target.actor.access_level != "Owner":
		visible = false
		_backdrop.visible = false
		_shield.dismiss()
		_action = null
		action.retire()
		access_lost.emit()
		return
	_view.configure(action.snapshot, action.state, action.message)
	if action.state == "shield":
		_backdrop.visible = true
		_shield.present(action.snapshot)
		_shield.set_pending(action.is_submitting())
	else:
		var was_open := _backdrop.visible
		_backdrop.visible = false
		_shield.dismiss()
		if was_open:
			decision_closed.emit()
	changed.emit(action.state, action.state == "ready" and not action.is_submitting(), action.snapshot.get("automatic_hit", false))
	if action.state == "resolved":
		resolved.emit()

func roll() -> void:
	if _action == null:
		return
	var options := _view.options()
	if options.is_empty():
		_view.configure(_action.snapshot, "error", "Enter whole numbers for difficulty and modifier.")
		return
	await _action.roll(options)

func _choose(choice: String) -> void:
	await _action.choose(choice)

func close() -> void:
	_backdrop.visible = false
	_shield.dismiss()
	if _action != null:
		await _action.cancel()


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"CompanionDefenceView").localize(locale)
	get_node(^"Shield").localize(locale)
