extends Node

## Live presentation of an authority-owned action; never saved or restored.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const REQUEST = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/action_request.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
signal changed
var _operation := "melee"
var _active_states := ["pending"]
var snapshot: Dictionary = {}
var state := "ready"
var message := ""
var pending := false
var _sdk: SDK
var _id := ""
var _reading := false
var _refresh_requested := false
var _closed := false
var _submitted := false
var _retired := false
var _cancelling := false
var _request: REQUEST

func _init(facade: SDK) -> void:
	_sdk = facade

func _enter_tree() -> void:
	_ensure_request()

func start(input: Dictionary) -> void:
	if state != "ready" or _closed:
		return
	_id = _sdk.dice.new_request_id()
	input["id"] = _id
	pending = true
	state = "pending"
	message = "Requesting the action…"
	changed.emit()
	_reading = true
	var result: SDK.DataResult = await _submit(_operation + ".start", input)
	_reading = false
	_submitted = result.ok
	if _closed:
		if _retired:
			queue_free()
		return
	_accept(result)
	if _refresh_requested:
		await refresh()

func refresh() -> void:
	if not pending or _closed:
		return
	_refresh_requested = true
	if _reading:
		return
	while _refresh_requested and pending and not _closed:
		_refresh_requested = false
		_reading = true
		var result: SDK.DataResult = await _submit(_operation + ".advance", {"id": _id})
		_reading = false
		if not _closed:
			_accept(result)

	if _retired and not _cancelling:
		queue_free()

func retire() -> void:
	_retired = true
	await cancel()
	if not _reading and not _cancelling:
		queue_free()

func cancel() -> void:
	if _closed:
		return
	_closed = true
	if not pending:
		return
	pending = false
	state = "ended"
	message = ENDED
	changed.emit()
	_cancelling = true
	_ensure_request()
	await _request.cancel(_operation, _id, _submitted)
	_cancelling = false
	if _retired and not _reading:
		queue_free()

func _accept(result: SDK.DataResult) -> void:
	if not result.ok:
		state = "ended"
		message = ENDED + " " + result.message
	else:
		snapshot = result.value
		var outcome: Dictionary = snapshot
		state = str(outcome.get("state", "ended"))
		message = str(outcome.get("message", ENDED))
	pending = state in _active_states
	changed.emit()

func _ensure_request() -> void:
	if _request == null:
		_request = REQUEST.new(_sdk, self)

func _submit(name: String, input: Dictionary) -> SDK.DataResult:
	_ensure_request()
	return await _request.submit(name, input)
