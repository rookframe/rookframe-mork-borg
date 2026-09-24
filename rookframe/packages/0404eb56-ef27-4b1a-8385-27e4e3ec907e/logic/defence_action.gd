extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd"

func _init(facade: SDK) -> void:
	super(facade)
	_operation = "defence"
	_active_states = ["ready", "pending", "shield"]

func adopt(outcome: Dictionary) -> void:
	_operation = str(outcome.get("operation", "defence"))
	_id = str(outcome.id)
	_submitted = true
	_accept(SDK.DataResult.new({"ok": true, "value": outcome}))

func roll(options: Dictionary) -> void:
	if state == "ready":
		await _command("roll", options)

func choose(choice: String) -> void:
	if state == "shield":
		await _command("choose", {"choice": choice})

func _command(operation: String, input: Dictionary) -> void:
	if _closed or _reading:
		return
	input["id"] = _id
	_reading = true
	message = "Saving…" if operation == "choose" else "Requesting the Throw…"
	changed.emit()
	var result: SDK.DataResult = await _submit(_operation + "." + operation, input)
	_reading = false
	if not _closed:
		_accept(result)
	elif _retired:
		queue_free()

func is_submitting() -> bool:
	return _reading

var _elapsed := 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.5:
		_elapsed = 0.0
		refresh()

func _accept(result: SDK.DataResult) -> void:
	if result.ok and result.value == snapshot:
		return
	super._accept(result)
