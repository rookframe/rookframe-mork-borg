extends Node
## One transient, initiating-Actor-bound action using the ordinary action transport.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const ROLLS = preload(ROOT + "logic/creature_rolls.gd")
const I18N = preload(ROOT + "ui/localization.gd")
signal changed
var source := ""
var pending := false
var has_action := false
var state := "ready"
var message := ""
var snapshot: Dictionary = {}
var selection: Dictionary = {}
var _sdk: SDK
var _surface: Control
var _action: ACTION
var _dirty := false
var _closed := false
var _presenting := true
var _poll := 0.0
var _locale := I18N.new()

func _exit_tree() -> void:
	# Actual content teardown abandons; hiding/Close keeps the Node and Roll.
	abandon()

func configure(sdk: SDK, surface: Control) -> void:
	_sdk = sdk
	_surface = surface
	_locale.bind(sdk)

func opened(actor: String) -> void:
	_closed = false
	_presenting = source == actor
	if has_action and not pending:
		abandon()

func closed() -> void:
	_closed = true
	if has_action and not pending:
		abandon()

func start(actor: String, part: String, entry: String, initial_choice: Dictionary = {}) -> void:
	if pending:
		return
	abandon()
	source = actor
	selection = initial_choice.duplicate(true)
	selection["part"] = part
	selection["entry"] = entry
	_closed = false
	_presenting = true
	var action := ACTION.new(_sdk)
	action._operation = "creature-roll"
	add_child(action)
	_action = action
	has_action = true
	pending = true
	state = "pending"
	message = "Requesting the action…"
	snapshot = {}
	action.changed.connect(_changed)
	changed.emit()
	await action.start({"source": actor, "part": part, "entry": entry})

func _changed() -> void:
	_dirty = true

func _process(delta: float) -> void:
	if _dirty:
		_dirty = false
		_accept()
	_poll += delta
	if _action != null and pending and _poll >= 0.25:
		_poll = 0.0
		_action.refresh()
	# Host may temporarily hide this surface before the requested Roll is claimed.
	# Only explicit Close/Actor changes stop its Window Dice presentation.
	if _action != null and pending and not _closed and _presenting:
		_present()

func _accept() -> void:
	if _action == null:
		return
	var value: Dictionary = _action.snapshot
	var next := {"state": _action.state, "message": _action.message, "request": value.get("request", ""), "total": value.get("total", 0), "sequence": value.get("sequence", 0)}
	var previous := {"state": state, "message": message, "request": snapshot.get("request", ""), "total": snapshot.get("total", 0), "sequence": snapshot.get("sequence", 0)}
	snapshot = value.duplicate(true)
	state = _action.state
	message = _action.message
	pending = _action.pending
	if _closed and not pending:
		abandon()
	elif next != previous:
		changed.emit()

func _present() -> void:
	var request := str(snapshot.get("request", ""))
	if not request.is_empty():
		var result := _sdk.dice.roll_requested(request, _surface)
		if not result.ok and result.code != "not_ready" and message != result.message:
			message = result.message
			changed.emit()

func abandon() -> void:
	var action := _action
	_action = null
	_dirty = false
	has_action = false
	pending = false
	state = "ended"
	message = ACTION.ENDED
	snapshot = {}
	if action != null:
		action.retire()
		changed.emit()

func summary() -> String:
	if state != "resolved":
		if pending:
			return _locale.text("Rolling Creature dice…")
		if message.begins_with(ACTION.ENDED):
			return _locale.text(ACTION.ENDED) + message.trim_prefix(ACTION.ENDED)
		return _locale.text(message)
	var choice: Dictionary = snapshot.get("choice", {})
	var plan: Dictionary = choice.get("plan", {})
	var result := _locale.text("%s: %s = %d. Raw Roll #%d.") % [_locale.text(str(choice.label)), str(choice.normalized), int(snapshot.total), int(snapshot.sequence)]
	if str(choice.part) in ["attack", "defence"]:
		var outcome := ROLLS.new().outcome(choice, int(snapshot.total))
		return _locale.text("%s: d20 %d, DR%d — %s. Raw Roll #%d.") % [_locale.text(str(choice.label)), int(snapshot.total), int(choice.difficulty), _locale.text(outcome), int(snapshot.sequence)] + "\n" + _locale.text("Apply table modifiers and resolve consequences manually.")
	if bool(snapshot.get("critical", false)):
		result += "\n" + _locale.text("Matching Attack critical: damage doubled.")
	if int(snapshot.get("attack_sequence", 0)) > 0:
		result += "\n" + _locale.text("Preceding Attack Raw Roll #%d.") % int(snapshot.attack_sequence)
	if int(plan.faces) == 2:
		result += "\n" + _locale.text("Physical d4 faces map 1–2 to 1 and 3–4 to 2 before the modifier.")
	if str(choice.part) == "morale":
		result += "\n" + _locale.text("Morale %d: %s.") % [int(choice.morale), _locale.text("holds" if int(snapshot.total) <= int(choice.morale) else "fails")]
		result += "\n" + _locale.text("Resolve the response at the table.")
	else:
		result += "\n" + _locale.text("Resolve protection and consequences at the table." if str(choice.part) == "damage" else "Resolve consequences at the table.")
	return result
