extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd"
var _elapsed := 0.0
func _init(facade: SDK) -> void:
	super(facade)
	_operation = "health"
	_active_states = ["pending", "scroll", "specialties"]
func choose(options: Dictionary) -> void:
	if not state in ["scroll", "specialties"] or _reading or _closed:
		return
	options["id"] = _id
	_reading = true
	var result := await _submit("health.choose", options)
	_reading = false
	if not _closed:
		_accept(result)
	if _retired and not _cancelling:
		queue_free()
func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.5:
		_elapsed = 0.0
		refresh()
func _accept(result: SDK.DataResult) -> void:
	if result.ok and result.value == snapshot:
		return
	super._accept(result)
