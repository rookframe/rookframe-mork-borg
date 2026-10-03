extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd"
var _elapsed := 0.0
var _queued_scrolls: Array[String] = []
var choosing_scrolls := false
func _init(facade: SDK) -> void:
	super(facade)
	_operation = "special"
	_active_states = ["pending", "scrolls", "witnesses", "shield"]
func choose_scrolls(ids: Array[String]) -> void:
	if state != "scrolls" or choosing_scrolls or _closed:
		return
	choosing_scrolls = true
	changed.emit()
	if _reading:
		_queued_scrolls = ids.duplicate()
		_refresh_requested = false
		return
	await _send_scrolls(ids)

func _send_scrolls(ids: Array[String]) -> void:
	_reading = true
	var result := await _submit("special.scrolls", {"id": _id, "scrolls": ids})
	_reading = false
	choosing_scrolls = false
	if not _closed:
		_accept(result)
	if _retired and not _cancelling:
		queue_free()

func refresh() -> void:
	if not choosing_scrolls:
		await super.refresh()

func _process(delta: float) -> void:
	# Preserve a selection made while a remote refresh is in flight.
	if not _queued_scrolls.is_empty():
		if not _reading:
			var selected := _queued_scrolls
			_queued_scrolls = []
			if state == "scrolls" and not _closed:
				_send_scrolls(selected)
			else:
				choosing_scrolls = false
				changed.emit()
		return
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
