extends Node
## A captured named Creature Roll uses the ordinary requested tabletop Dice Tray.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
signal changed
var sdk: SDK
var _action: ACTION
var _poll := 0.0
var pending: bool:
	get:
		return _action != null and _action.pending

func start(actor: SDK.ActorId, part: String) -> void:
	if pending:
		return
	if _action != null:
		_action.retire()
	var action := ACTION.new(sdk)
	action._operation = "creature-roll"
	add_child(action)
	_action = action
	_action.changed.connect(_changed)
	await _action.start({"source": actor.value, "part": part, "entry": ""})

func _process(delta: float) -> void:
	_poll += delta
	if pending and _poll >= 0.25:
		_poll = 0.0
		_action.refresh()

func _changed() -> void:
	changed.emit()
	if _action != null and not _action.pending and _action.state != "resolved":
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = sdk.translations.text("Creature")
		feedback.message = sdk.translations.text(_action.message)
		sdk.feedback.error(feedback)

func _exit_tree() -> void:
	if pending:
		_action.cancel()
