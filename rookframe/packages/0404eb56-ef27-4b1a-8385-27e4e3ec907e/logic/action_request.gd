extends RefCounted

## Finish an in-flight action request/cancellation even after its task is freed.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _sdk: SDK
var _tree: SceneTree
var _starting := false
var _closed := false
var _cancelling := false
var _cancel_name := ""
var _id := ""

func _init(facade: SDK, owner: Node) -> void:
	_sdk = facade
	_tree = owner.get_tree()

func submit(name: String, input: Dictionary) -> SDK.DataResult:
	# This reference belongs to the coroutine, independently of the UI Node.
	var retained := self
	var starts := name.ends_with(".start") or name == "power.daily"
	if starts:
		_starting = true
	var result := await retained._request(name, input)
	if starts:
		_starting = false
		if _closed and result.ok:
			await retained._cancel()
	return result

func cancel(operation: String, id: String, submitted: bool) -> void:
	var retained := self
	_closed = true
	_cancel_name = operation + ".cancel"
	_id = id
	# The accepted start reply supplies the cancellation's ordering boundary.
	if submitted and not _starting:
		await retained._cancel()

func _cancel() -> void:
	if _cancelling:
		return
	var retained := self
	_cancelling = true
	await retained._request(_cancel_name, {"id": _id})
	_cancelling = false

func _request(name: String, input: Dictionary) -> SDK.DataResult:
	var _retained := self
	while true:
		if _closed and name != _cancel_name:
			return SDK.DataResult.new({"ok": false, "code": "closed", "message": ENDED})
		var result: SDK.DataResult = await _sdk.system_actions.submit(name, input)
		if result.ok or not result.code in ["busy", "rate_limited", "not_ready", "operation_in_progress"] or (_closed and name != _cancel_name):
			return result
		# Use the existing stock timer/retry policy until acknowledgement or a
		# permanent refusal (including an ended Session).
		await _tree.create_timer(0.5).timeout
	return SDK.DataResult.new({"ok": false, "message": ENDED})
