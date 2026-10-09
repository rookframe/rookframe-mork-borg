extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
## Accepted relative writes retain one identity in this live Authority session.
## Transient transport retries must reuse it; no gameplay/action data is hidden.
var _accepted: Dictionary = {}

func handle(context: SDK.SystemActionContext, name: String, payload: Variant) -> Dictionary:
	if name != "creature-health.adjust" or typeof(payload) != TYPE_DICTIONARY:
		return _error("Creature HP choices are malformed.")
	var input: Dictionary = payload
	for field in ["id", "actor", "operation", "amount"]:
		if typeof(input.get(field)) != TYPE_STRING:
			return _error("Creature HP choices are malformed.")
	var id := str(input.id)
	if id.is_empty() or id.length() > 64:
		return _error("Choose a new action identity.")
	var caller_result := context.caller()
	if not caller_result.ok:
		return _error(caller_result.message)
	var caller: Dictionary = caller_result.value
	if _accepted.has(id):
		var action: Dictionary = _accepted.get(id, {})
		if action.participant != caller.participant_id or action.session != caller.session_id:
			return _error("This action belongs to another Participant session.")
		if action.actor != input.actor or action.operation != input.operation or action.amount != input.amount:
			return _error("This HP adjustment already has different choices.")
		return _read_accepted(context, SDK.ActorId.new(str(input.actor)))
	var sessions := context.participant_sessions()
	var present := false
	if sessions.ok:
		var entries: Array = sessions.value
		for raw in entries:
			var entry: Dictionary = raw
			if entry.participant_id == caller.participant_id and entry.session_id == caller.session_id:
				present = true
	if not present:
		return _error("This Participant session has ended.")
	var actor_id := SDK.ActorId.new(str(input.actor))
	var source := context.read_actor(actor_id)
	if not source.ok or source.actor == null:
		return _error(source.message)
	if source.actor.access_level != "Owner":
		return _error("Owner access is required to change this Creature.")
	if typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Creature data is unavailable.")
	var current: Dictionary = source.actor.data
	if str(current.get("schema", "")) != "mork-borg-adversary/v1":
		return _error("Creature data is unavailable.")
	var health := HEALTH.new()
	var amount := health.integer(str(input.amount)) if str(input.operation) == "set" else health.amount(str(input.amount))
	if not amount.ok:
		return _error(str(amount.message), "amount")
	var change := health.adjusted(current, str(input.operation), int(amount.value))
	if not change.ok:
		return _error(str(change.message), "amount" if health.valid(current) else "")
	var data := CREATURES.new().stat_block(current)
	data["hit_points"] = int(change.value)
	var committed := context.commit([SDK.ActorChange.new(actor_id, data)])
	if not committed.ok:
		return _error(committed.message)
	# Record acceptance before readback, so a missing acknowledgement never reapplies HP.
	_accepted[id] = {"participant": caller.participant_id, "session": caller.session_id, "actor": input.actor, "operation": input.operation, "amount": input.amount}
	return _read_accepted(context, actor_id)

func _read_accepted(context: SDK.SystemActionContext, id: SDK.ActorId) -> Dictionary:
	var result := context.read_actor(id)
	if not result.ok or result.actor == null:
		return _error(result.message)
	if result.actor.access_level != "Owner":
		return _error("Owner access is required to change this Creature.")
	var actor := result.actor
	return {"ok": true, "state": "resolved", "value": {"id": actor.id.value, "data": actor.data, "access_level": actor.access_level, "public_label": actor.public_label}}

func _error(message: String, field: String = "") -> Dictionary:
	return {"ok": false, "state": "error", "message": message, "field": field}
