extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd"

var daily := false
var _elapsed := 0.0

func _init(facade: SDK) -> void:
	super(facade)
	_operation = "power"
	_active_states = ["pending", "targets"]

func _submit(name: String, input: Dictionary) -> SDK.DataResult:
	return await super._submit("power.daily" if daily and name == "power.start" else name, input)

func confirm_targets() -> void:
	if state != "targets" or _reading or _closed:
		return
	_reading = true
	var result := await _submit("power.targets", {"id": _id})
	_reading = false
	if not _closed:
		_accept(result)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.5:
		_elapsed = 0.0
		refresh()

func _accept(result: SDK.DataResult) -> void:
	if result.ok and result.value == snapshot:
		return
	super._accept(result)
