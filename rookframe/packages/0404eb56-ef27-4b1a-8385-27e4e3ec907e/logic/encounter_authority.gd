extends RefCounted

## Encounter guidance is current World data. No action, effect or time processing.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")

var _rolls: Dictionary = {}

func empty() -> Dictionary:
	return {"revision": 0, "active": false, "round": 0, "current": "", "first_side": "pc", "entries": []}

func handle(context: SDK.SystemActionContext, operation: String, payload: Variant) -> Dictionary:
	var caller := context.caller()
	var identity: Dictionary = caller.value if caller.ok else {}
	if not caller.ok or not bool(identity.get("is_gm", false)):
		return error("Only the GM manages encounter guidance.")
	if not operation in ["encounter.edit", "encounter.roll", "encounter.advance", "encounter.cancel"]:
		return error("Choose a supported encounter operation.")
	if typeof(payload) != TYPE_DICTIONARY:
		return error("Encounter options are malformed.")
	var input: Dictionary = payload
	var saved := context.read_world_data()
	if not saved.ok:
		return error(saved.message)
	if saved.value != null and typeof(saved.value) != TYPE_DICTIONARY:
		return error("Encounter World data is malformed.")
	var world: Dictionary = {} if saved.value == null else saved.value.duplicate(true)
	var encounter: Dictionary = world.get("encounter", empty())
	if operation == "encounter.edit":
		if typeof(input.get("revision")) != TYPE_INT or input.revision != encounter.revision:
			return error("Encounter changed. Review the current order and try again.")
		return _edit(context, world, encounter, input)
	return _roll(context, caller.value, world, encounter, operation, input)

func _edit(context: SDK.SystemActionContext, world: Dictionary, encounter: Dictionary, input: Dictionary) -> Dictionary:
	var kind := str(input.get("kind", ""))
	var entries: Array = encounter.entries
	for i in range(entries.size() - 1, -1, -1):
		if not context.read_rook(SDK.RookId.new(str(_at(entries, i).rook))).ok:
			entries.remove_at(i)
	var rook_id := str(input.get("rook", ""))
	var index := -1
	for i in range(entries.size()):
		if str(_at(entries, i).rook) == rook_id:
			index = i
	if kind == "add":
		var rook := context.read_rook(SDK.RookId.new(rook_id))
		if not rook.ok or rook.rook.actor == null or index >= 0:
			return error("Select a linked Rook outside combat.")
		var found := context.read_actor(rook.rook.actor)
		if not found.ok:
			return error("This Rook's Actor is unavailable.")
		var data: Dictionary = found.actor.data
		if not str(data.get("schema", "")) in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
			return error("Select a Character or Creature Rook.")
		entries.append({"rook": rook_id, "actor": found.actor.id.value, "side": "pc" if data.schema == "mork-borg-character/v1" else "enemy", "always_first": str(data.get("definition_id", "")) == "wrat-wraith"})
		_sort(encounter)
	elif kind == "remove":
		if index < 0:
			return error("Select a Rook in combat.")
		entries.remove_at(index)
		if entries.is_empty():
			encounter.active = false
			encounter.round = 0
			encounter.current = ""
		elif not str(encounter.current) in phases(encounter) and encounter.active:
			encounter.current = phases(encounter)[0]
	elif kind == "begin":
		if entries.is_empty() or encounter.active:
			return error("Add Rooks before beginning combat.")
		encounter.active = true
		encounter.round = 1
		encounter.current = phases(encounter)[0]
	elif kind == "end":
		encounter.active = false
		encounter.round = 0
		encounter.current = ""
	elif kind in ["next", "previous"]:
		if not encounter.active or entries.is_empty():
			return error("Begin combat first.")
		var order := phases(encounter)
		var current := -1
		for i in range(order.size()):
			if order[i] == str(encounter.current):
				current = i
		current += 1 if kind == "next" else -1
		if current >= order.size():
			current = 0
			encounter.round = int(encounter.round) + 1
		elif current < 0:
			if int(encounter.round) <= 1:
				return error("Already at the first side.")
			current = order.size() - 1
			encounter.round = int(encounter.round) - 1
		encounter.current = order[current]
	elif kind == "correct":
		if entries.is_empty() or typeof(input.get("round")) != TYPE_INT or int(input.round) < 1 or int(input.round) > 9999:
			return error("Round must be between 1 and 9999.")
		var current := str(input.get("current", ""))
		if not current in phases(encounter):
			return error("Choose Players or Monsters.")
		if not encounter.active:
			encounter.first_side = current if current != "first" else str(encounter.first_side)
			_sort(encounter)
		encounter.active = true
		encounter.round = int(input.round)
		encounter.current = current
	else:
		return error("Choose a supported encounter control.")
	return save(context, world, encounter, "Encounter guidance updated.")

func phases(encounter: Dictionary) -> Array[String]:
	var result: Array[String] = []
	# A Wraith acts before either side. It is excluded from the later monster
	# activation, preserving the source exception without individual scores.
	var entries: Array = encounter.entries
	for raw in entries:
		var entry: Dictionary = raw
		if bool(entry.get("always_first", false)):
			result.append("first")
			break
	result.append(str(encounter.first_side))
	result.append("enemy" if encounter.first_side == "pc" else "pc")
	return result

func _sort(encounter: Dictionary) -> void:
	var entries: Array = encounter.entries
	for i in range(1, entries.size()):
		var j := i
		while j > 0 and _before(entries[j], entries[j - 1], encounter):
			var previous: Variant = entries[j - 1]
			entries[j - 1] = entries[j]
			entries[j] = previous
			j -= 1

func _before(a: Dictionary, b: Dictionary, encounter: Dictionary) -> bool:
	if bool(a.get("always_first", false)) != bool(b.get("always_first", false)):
		return bool(a.get("always_first", false))
	return a.side != b.side and a.side == encounter.first_side

func save(context: SDK.SystemActionContext, world: Dictionary, encounter: Dictionary, text: String) -> Dictionary:
	encounter.revision = int(encounter.revision) + 1
	world["encounter"] = encounter
	var report := SDK.ActionLogMessage.new("Encounter")
	report.text = [SDK.ActionLogText.new(text)]
	var result := context.commit_world_data(world, report)
	return {"state": "resolved", "message": text} if result.ok else error(result.message)

func error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _roll(context: SDK.SystemActionContext, caller: Dictionary, world: Dictionary, encounter: Dictionary, operation: String, input: Dictionary) -> Dictionary:
	var entries: Array = encounter.entries
	var id := str(input.get("id", ""))
	if id.is_empty() or id.length() > 64:
		return error("Choose a new roll identity.")
	if not _rolls.has(id):
		if operation != "encounter.roll" or context.read_throw(id).ok:
			return {"state": "ended", "message": "Roll ended. Start a new roll or correct the current guidance."}
		if typeof(input.get("revision")) != TYPE_INT or input.revision != encounter.revision:
			return error("Encounter changed. Review it before rolling.")
		var kind := str(input.get("kind", ""))
		if not kind in ["group", "reaction", "morale"]:
			return error("Choose a supported encounter roll.")
		if kind == "group" and encounter.entries.is_empty():
			return error("Add Rooks before rolling initiative.")
		var label := ""
		var morale := 0
		if kind != "group":
			var actor := context.read_actor(SDK.ActorId.new(str(input.get("actor", ""))))
			if not actor.ok:
				return error("Choose an available Actor.")
			label = _public_label(actor.actor)
			var actor_data: Dictionary = actor.actor.data
			if kind == "morale":
				var raw_profile: Variant = actor_data.get("morale")
				if typeof(raw_profile) != TYPE_DICTIONARY:
					return error("This Creature has no numeric Morale. Resolve its printed rule with the table.")
				var profile: Dictionary = raw_profile
				if str(profile.get("kind", "")) != "fixed" or typeof(profile.get("value")) != TYPE_INT:
					return error("This Creature has no numeric Morale. Resolve its printed rule with the table.")
				morale = int(profile.value)

		var action := {"state": "pending", "message": "%s · Throw pending" % ("Initiative" if kind == "group" else ("Morale" if kind == "morale" else "Reaction") + " · " + label), "request": id, "participant": str(caller.participant_id), "session": str(caller.session_id), "revision": int(encounter.revision), "kind": kind, "label": label, "morale": morale, "phase": "check", "actor": str(input.get("actor", ""))}
		var terms: Array[SDK.DiceTerm] = []
		terms.append(SDK.DiceTerm.new("Initiative", 6) if kind == "group" else SDK.DiceTerm.new("Morale" if kind == "morale" else "Reaction", 6, 2))
		var requested := context.request_throw(SDK.HumanThrowRequest.new(id, str(caller.participant_id), terms))
		if not requested.ok:
			return error(requested.message)
		_rolls[id] = action
		return _outcome(action)
	var action: Dictionary = _rolls.get(id, {})
	if action.participant != caller.participant_id or action.session != caller.session_id:
		return error("This roll belongs to another GM session.")
	if action.state != "pending":
		return _outcome(action)
	if operation == "encounter.cancel" or int(action.revision) != int(encounter.revision):
		return _end_roll(context, action)
	var rolled := context.read_throw(str(action.request))
	if not rolled.ok or rolled.status == "cancelled":
		return _end_roll(context, action)
	if rolled.status == "pending":
		return _outcome(action)
	var face: int = rolled.terms[0].results[0]
	var message := ""
	if action.kind == "group":
		encounter.first_side = "enemy" if face <= 3 else "pc"
		_sort(encounter)
		encounter.active = true
		encounter.round = maxi(1, int(encounter.round))
		encounter.current = phases(encounter)[0]
		message = "Monsters go first." if face <= 3 else "Players go first."
	elif action.kind == "morale":
		if action.phase == "check":
			var total: int = face + int(rolled.terms[0].results[1])
			if total > int(action.morale):
				action.phase = "response"
				action["first_roll"] = rolled.sequence
				action.request = context.new_request_id()
				action.message = "Morale · %s · Throw pending" % str(action.label)
				var requested := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), str(action.participant), [SDK.DiceTerm.new("Flee or surrender", 6)]))
				return _outcome(action) if requested.ok else _end_roll(context, action)
			message = "%s: Holds." % str(action.label)
		else:
			message = "%s: %s." % [str(action.label), "Flees" if face <= 3 else "Surrenders"]
	else:
		var total: int = face + int(rolled.terms[0].results[1])
		var reaction := "Kill!" if total <= 3 else "Angered" if total <= 6 else "Indifferent" if total <= 8 else "Almost friendly" if total <= 10 else "Helpful"
		message = "%s: %s." % [str(action.label), reaction]
	var display := message
	if action.has("first_roll"):
		message += " Morale Raw Roll #%d." % int(action.first_roll)
	message += " Raw Roll #%d." % rolled.sequence
	encounter["last_outcome"] = message
	var result := save(context, world, encounter, message)
	action.state = result.state
	action.message = display if result.state == "resolved" else result.message
	return _outcome(action)

func _end_roll(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	context.cancel_throw(str(action.request))
	action.state = "ended"
	action.message = "Throw ended."
	return _outcome(action)

func _outcome(action: Dictionary) -> Dictionary:
	return {"state": action.state, "message": action.message, "request": action.request}

func _public_label(actor: SDK.Actor) -> String:
	var data: Dictionary = actor.data
	if not actor.public_label.is_empty():
		return actor.public_label
	return str(data.get("name", "Character")) if str(data.get("schema", "")) == "mork-borg-character/v1" else "Creature"

func _at(entries: Array, index: int) -> Dictionary:
	var entry: Dictionary = entries[index]
	return entry
