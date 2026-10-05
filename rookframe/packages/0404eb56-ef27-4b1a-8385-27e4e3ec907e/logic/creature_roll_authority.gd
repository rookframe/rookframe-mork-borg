extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ROLLS = preload(ROOT + "logic/creature_rolls.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Dictionary = {}

func handle(context: SDK.SystemActionContext, name: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("Creature roll choices are malformed.")
	var input: Dictionary = payload
	if typeof(input.get("id")) != TYPE_STRING:
		return _error("Choose a new action identity.")
	var id := str(input.id)
	if id.is_empty() or id.length() > 64:
		return _error("Choose a new action identity.")
	var caller_result := context.caller()
	if not caller_result.ok:
		return _error(caller_result.message)
	var caller: Dictionary = caller_result.value
	if _actions.has(id):
		var action: Dictionary = _actions.get(id, {})
		if action.participant != caller.participant_id or action.session != caller.session_id:
			return _error("This action belongs to another Participant session.")
		if name == "creature-roll.cancel":
			return _end(context, action)
		if name in ["creature-roll.start", "creature-roll.advance"]:
			return _advance(context, action)
		return _error("Choose a supported Creature roll operation.")
	if name != "creature-roll.start":
		return {"state": "ended", "message": ENDED}
	for field in ["source", "part", "entry"]:
		if typeof(input.get(field)) != TYPE_STRING:
			return _error("Creature roll choices are malformed.")
	# A recorded request from a previous Authority lifetime never starts anew.
	if context.read_throw(id).ok:
		return {"state": "ended", "message": ENDED}
	var result := _start(context, caller, input)
	if result.state == "error":
		result["participant"] = caller.participant_id
		result["session"] = caller.session_id
		result["request"] = ""
		_actions[id] = result
	return result

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	if not _present(context, str(caller.participant_id), str(caller.session_id)):
		return _error("This Participant session has ended.")
	var source := context.read_actor(SDK.ActorId.new(str(input.source)))
	if not _usable(source):
		return _error("This Creature cannot roll. Rules and corrections remain available.")
	var data: Dictionary = source.actor.data
	var accepted := CREATURES.new().stat_block(data)
	var choice := ROLLS.new().choice(accepted, str(input.part), str(input.entry))
	if choice.is_empty():
		return _error("This named roll is unavailable. Correct the supported formula or resolve it at the table.")
	var plan: Dictionary = choice.plan
	var term := SDK.DiceTerm.new(str(choice.label), int(plan.physical_faces), int(plan.count))
	var terms: Array[SDK.DiceTerm] = [term]
	var action := {"participant": caller.participant_id, "session": caller.session_id, "source": source.actor.id.value, "id": str(input.id), "request": str(input.id), "state": "pending", "message": "Rolling Creature dice…", "actor_name": str(accepted.get("name", "Creature")), "choice": choice.duplicate(true)}
	var requested := context.request_throw(SDK.HumanThrowRequest.new(str(input.id), str(caller.participant_id), terms))
	if not requested.ok:
		return _error(requested.message)
	_actions[str(input.id)] = action
	return _public(action)

func _advance(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	if str(action.state) != "pending":
		return _public(action)
	if not _present(context, str(action.participant), str(action.session)) or not _usable(context.read_actor(SDK.ActorId.new(str(action.source)))):
		return _end(context, action)
	var roll := context.read_throw(str(action.request))
	if not roll.ok or roll.status == "cancelled":
		return _end(context, action)
	if roll.status == "pending":
		return _public(action)
	if not _valid_roll(action, roll):
		return _end(context, action)
	return _complete(context, action, roll)

func _complete(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var choice: Dictionary = action.choice
	var value := ROLLS.new().total(choice.plan, roll.terms[0].results)
	var text := ROLLS.new().text(choice, value, roll.sequence)
	var report := SDK.ActionLogMessage.new(_short(str(action.actor_name), 10) + " · " + _short(str(choice.name), 12) + " · " + _short(str(choice.label), 10))
	report.text = [SDK.ActionLogText.new(_short(str(action.actor_name), 64) + " · " + _short(str(choice.name), 96), "strong"), SDK.ActionLogText.new(_short(text, 340))]
	report.result = str(value)
	report.tone = "roll"
	for face in roll.terms[0].results:
		report.dice.append(SDK.ActionLogDie.new(roll.terms[0].faces, face))
	var saved := context.commit([], report)
	if not saved.ok:
		return _end(context, action, saved.message)
	action["total"] = value
	action["sequence"] = roll.sequence
	action["message"] = text
	action["state"] = "resolved"
	return _public(action)

func _valid_roll(action: Dictionary, roll: SDK.HumanThrowResult) -> bool:
	if roll.status != "rolled" or roll.request_id != str(action.request) or roll.participant_id != str(action.participant) or roll.sequence < 1 or roll.terms.size() != 1 or roll.plan.size() != 1:
		return false
	var choice: Dictionary = action.choice
	var plan: Dictionary = choice.plan
	var term := roll.terms[0]
	var requested := roll.plan[0]
	if requested.name != str(choice.label) or requested.faces != int(plan.physical_faces) or requested.count != int(plan.count) or term.name != requested.name or term.faces != requested.faces or term.results.size() != requested.count:
		return false
	for face in term.results:
		if face < 1 or face > term.faces:
			return false
	return true

func _usable(result: SDK.ActorResult) -> bool:
	if not result.ok or result.actor == null or result.actor.access_level != "Owner" or typeof(result.actor.data) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = result.actor.data
	return str(data.get("schema", "")) == "mork-borg-adversary/v1" and HEALTH.new().can_roll(data)

func _present(context: SDK.SystemActionContext, participant: String, session: String) -> bool:
	var result := context.participant_sessions()
	if result.ok:
		var entries: Array = result.value
		for raw in entries:
			var entry: Dictionary = raw
			if str(entry.participant_id) == participant and str(entry.session_id) == session:
				return true
	return false

func _end(context: SDK.SystemActionContext, action: Dictionary, reason: String = "") -> Dictionary:
	if str(action.state) == "pending":
		action["state"] = "ended"
		action["message"] = ENDED + (" " + reason if not reason.is_empty() else "")
		context.cancel_throw(str(action.request))
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	var choice: Dictionary = action.get("choice", {})
	return {"state": action.state, "message": action.message, "request": str(action.get("request", "")), "source": str(action.get("source", "")), "choice": choice.duplicate(true), "total": action.get("total", 0), "sequence": action.get("sequence", 0)}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

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
