extends RefCounted
## An announced special has no automated gameplay effects. Authority validates
## the exact Actor and existing rule, then accepts one ordinary Action Log entry.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/creature_hud_actions.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
var _accepted: Dictionary = {}

func handle(context: SDK.SystemActionContext, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("Creature action is unavailable.")
	var input: Dictionary = payload
	for field in ["id", "actor", "entry"]:
		if typeof(input.get(field)) != TYPE_STRING or str(input.get(field)).is_empty():
			return _error("Creature action is unavailable.")
	if str(input.id).length() > 64:
		return _error("Choose a new action identity.")
	var caller := context.caller()
	if not caller.ok:
		return _error(caller.message)
	var identity: Dictionary = caller.value
	var sessions := context.participant_sessions()
	var present := false
	if sessions.ok:
		var entries: Array = sessions.value
		for raw_session in entries:
			var session: Dictionary = raw_session
			if session.participant_id == identity.participant_id and session.session_id == identity.session_id:
				present = true
	if not present:
		return _error("This Participant session has ended.")
	var source := context.read_actor(SDK.ActorId.new(str(input.actor)))
	if not source.ok or source.actor == null or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Owner access is required to use this Creature.")
	var data: Dictionary = source.actor.data
	if str(data.get("schema", "")) != "mork-borg-adversary/v1":
		return _error("Creature action is unavailable.")
	var key := str(identity.session_id) + ":" + str(identity.participant_id) + ":" + str(input.id)
	if _accepted.has(key):
		var accepted: Array = _accepted.get(key, [])
		return {"ok": true} if accepted == [input.actor, input.entry] else _error("This action already has different choices.")
	if not HEALTH.new().can_roll(data):
		return _error("This Creature is dead. Rules and corrections remain available.")
	for entry in ACTIONS.new().specials(data):
		if str(entry.id) != str(input.entry):
			continue
		var report := SDK.ActionLogMessage.new("Creature action")
		report.text = [SDK.ActionLogText.new(_short(str(data.get("name", "Creature")), 200) + " uses " + _short(str(entry.get("name", "Special")), 200))]
		var result := context.commit([], report)
		if not result.ok:
			return _error(result.message)
		_accepted[key] = [input.actor, input.entry]
		return {"ok": true}
	return _error("This Creature action is no longer available.")

func _error(message: String) -> Dictionary:
	return {"ok": false, "message": message}

func _short(text: String, limit: int) -> String:
	var result := ""
	var used := 0
	for raw_character in text.split(""):
		var character: String = str(raw_character)
		# String ordering keeps Unicode control ranges out of printable summaries.
		if character < " " or character >= "\u007f" and character <= "\u009f":
			continue
		# One code point above the BMP occupies two UTF-16 units.
		var units := 2 if character > "\uffff" else 1
		if used + units > limit:
			break
		result += character
		used += units
	return result
