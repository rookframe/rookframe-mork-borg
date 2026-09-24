extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd"
var _elapsed := 0.0
func _init(facade: SDK) -> void:
	super(facade)
	_operation = "special"
	_active_states = ["pending", "scrolls", "witnesses", "shield"]
func choose_scrolls(ids: Array[String]) -> void:
	if state != "scrolls" or _reading or _closed:
		return
	_reading = true
	var result := await _submit("special.scrolls", {"id": _id, "scrolls": ids})
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

func confirm_witnesses() -> void:
	if state != "witnesses" or _reading or _closed:
		return
	_reading = true
	var result := await _submit("special.witnesses", {"id": _id, "confirmed": true})
	_reading = false
	if not _closed:
		_accept(result)
	if _retired and not _cancelling:
		queue_free()

func choose_shield(choice: String) -> void:
	if state != "shield" or _reading or _closed:
		return
	_reading = true
	var result := await _submit("special.choose", {"id": _id, "choice": choice})
	_reading = false
	if not _closed:
		_accept(result)
