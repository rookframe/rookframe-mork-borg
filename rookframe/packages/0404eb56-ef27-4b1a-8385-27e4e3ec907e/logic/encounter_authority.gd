extends RefCounted

## Encounter guidance is current World data. No action, effect or time processing.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")

var _rolls: Dictionary = {}

func empty() -> Dictionary:
	return {"revision": 0, "active": false, "round": 0, "current": "", "mode": "group", "first_side": "pc", "entries": []}

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
	var actor := str(input.get("actor", ""))
	var index := -1
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		if str(entry.actor) == actor:
			index = i
	var selected: Dictionary = {} if index < 0 else entries[index]
	if kind == "add":
		var found := context.read_actor(SDK.ActorId.new(actor))
		if not found.ok or index >= 0 or not str(input.get("side", "")) in ["pc", "enemy"]:
			return error("Choose an Actor and side; each Actor appears once.")
		var found_data: Dictionary = found.actor.data
		entries.append({"actor": actor, "side": str(input.side), "initiative": null, "always_first": str(found_data.get("definition_id", "")) == "wrat-wraith"})
		_sort(encounter)
	elif kind == "portrait":
		if index < 0 or not input.get("portrait") is Texture2D:
			return error("Choose an image for this Actor's public portrait.")
		selected["portrait"] = input.portrait
	elif kind == "remove":
		if index < 0:
			return error("Choose an Actor in this encounter.")
		entries.remove_at(index)
		if encounter.current == actor:
			encounter.current = "" if entries.is_empty() else str(_at(entries, mini(index, entries.size() - 1)).actor)
		if entries.is_empty():
			encounter.active = false
			encounter.round = 0
	elif kind == "begin":
		if entries.is_empty() or encounter.active:
			return error("Add Actors before beginning a new encounter.")
		encounter.active = true
		encounter.round = 1
		encounter.current = str(_at(entries, 0).actor)
	elif kind == "end":
		encounter.active = false
		encounter.current = ""
	elif kind in ["next", "previous"]:
		if not encounter.active or entries.is_empty():
			return error("Begin the encounter before advancing turns.")
		var current := 0
		for i in range(entries.size()):
			if _at(entries, i).actor == encounter.current:
				current = i
		current += 1 if kind == "next" else -1
		if current >= entries.size():
			current = 0
			encounter.round = int(encounter.round) + 1
		elif current < 0:
			if int(encounter.round) <= 1:
				return error("Already at the first turn.")
			current = entries.size() - 1
			encounter.round = int(encounter.round) - 1
		encounter.current = str(_at(entries, current).actor)
	elif kind == "correct":
		if typeof(input.get("round")) != TYPE_INT or int(input.round) < 1 or int(input.round) > 9999:
			return error("Round must be between 1 and 9999.")
		var current := str(input.get("current", ""))
		var found := false
		for raw_entry in entries:
			var entry: Dictionary = raw_entry
			found = found or str(entry.actor) == current
		if not found or not encounter.active:
			return error("Choose a current turn in the active encounter.")
		encounter.round = int(input.round)
		encounter.current = current
	elif kind == "mode":
		if not str(input.get("mode", "")) in ["group", "individual"]:
			return error("Choose group or individual initiative.")
		encounter.mode = str(input.mode)
		_sort(encounter)
	elif kind == "initiative":
		if index < 0 or typeof(input.get("value")) != TYPE_INT or int(input.value) < -99 or int(input.value) > 99:
			return error("Choose an Actor and an initiative between −99 and 99.")
		selected.initiative = int(input.value)
		_sort(encounter)
	elif kind == "move":
		var direction := int(input.get("direction", 0))
		if index < 0 or not direction in [-1, 1] or index + direction < 0 or index + direction >= entries.size():
			return error("Choose an adjacent position in the order.")
		if encounter.mode == "group" and selected.side != _at(entries, index + direction).side:
			return error("Group initiative keeps each side together.")
		var moved: Dictionary = entries.pop_at(index)
		entries.insert(index + direction, moved)
	else:
		return error("Choose a supported encounter control.")
	return save(context, world, encounter, "Encounter guidance updated.")

func _sort(encounter: Dictionary) -> void:
	var entries: Array = encounter.entries
	# Insertion sort preserves the GM's order on ties, which the source leaves open.
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
	if encounter.mode == "group" and a.side != b.side:
		return a.side == encounter.first_side
	if a.initiative == null:
		return false
	return b.initiative == null or int(a.initiative) > int(b.initiative)

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
		if not kind in ["group", "reaction", "morale", "individual"]:
			return error("Choose a supported encounter roll.")
		if kind == "group" and encounter.entries.is_empty():
			return error("Add Actors before rolling initiative.")
		var label := ""
		var morale := 0
		var modifier := 0
		if kind != "group":
			var actor := context.read_actor(SDK.ActorId.new(str(input.get("actor", ""))))
			if not actor.ok:
				return error("Choose an available Actor.")
			label = _public_label(actor.actor)
			var actor_data: Dictionary = actor.actor.data
			if kind == "individual":
				var abilities: Dictionary = actor_data.get("abilities", {})
				var agility: Dictionary = abilities.get("Agility", {})
				if typeof(agility.get("modifier")) != TYPE_INT:
					return error("This Actor has no Agility. Enter its table-agreed initiative or use group initiative.")
				modifier = int(agility.modifier)
				var included := false
				for raw_entry in entries:
					var entry: Dictionary = raw_entry
					included = included or entry.actor == actor.actor.id.value
				if not included:
					return error("Add this Actor to the encounter first.")
			if kind == "morale":
				var raw_profile: Variant = actor_data.get("morale")
				if typeof(raw_profile) != TYPE_DICTIONARY:
					return error("This Creature has no numeric Morale. Resolve its printed rule with the table.")
				var profile: Dictionary = raw_profile
				if str(profile.get("kind", "")) != "fixed" or typeof(profile.get("value")) != TYPE_INT:
					return error("This Creature has no numeric Morale. Resolve its printed rule with the table.")
				morale = int(profile.value)

		var action := {"state": "pending", "message": "Throw %s in the Dice Tray." % ("initiative" if kind in ["group", "individual"] else kind), "request": id, "participant": str(caller.participant_id), "session": str(caller.session_id), "revision": int(encounter.revision), "kind": kind, "label": label, "morale": morale, "phase": "check", "actor": str(input.get("actor", "")), "modifier": modifier}
		var terms: Array[SDK.DiceTerm] = []
		terms.append(SDK.DiceTerm.new("Initiative", 6) if kind in ["group", "individual"] else SDK.DiceTerm.new("Morale" if kind == "morale" else "Reaction", 6, 2))
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
		message = "Enemies go first." if face <= 3 else "PCs go first."
	elif action.kind == "individual":
		for raw_entry in entries:
			var entry: Dictionary = raw_entry
			if entry.actor == action.actor:
				entry.initiative = face + int(action.modifier)
		_sort(encounter)
		message = "%s: initiative %d." % [str(action.label), face + int(action.modifier)]
	elif action.kind == "morale":
		if action.phase == "check":
			var total: int = face + int(rolled.terms[0].results[1])
			if total > int(action.morale):
				action.phase = "response"
				action["first_roll"] = rolled.sequence
				action.request = context.new_request_id()
				action.message = "Demoralized. Throw d6 for flee or surrender."
				var requested := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), str(action.participant), [SDK.DiceTerm.new("Flee or surrender", 6)]))
				return _outcome(action) if requested.ok else _end_roll(context, action)
			message = "%s: Holds." % str(action.label)
		else:
			message = "%s: %s. Morale Raw Roll #%d." % [str(action.label), "Flees" if face <= 3 else "Surrenders", int(action.first_roll)]
	else:
		var total: int = face + int(rolled.terms[0].results[1])
		var reaction := "Kill!" if total <= 3 else "Angered" if total <= 6 else "Indifferent" if total <= 8 else "Almost friendly" if total <= 10 else "Helpful"
		message = "%s: %s (reaction %d)." % [str(action.label), reaction, total]
	message += " Raw Roll #%d." % rolled.sequence
	encounter["last_outcome"] = message
	var result := save(context, world, encounter, message)
	action.state = result.state
	action.message = result.message
	return _outcome(action)

func _end_roll(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	context.cancel_throw(str(action.request))
	action.state = "ended"
	action.message = "Roll ended. Completed dice remain; correct current guidance or start a new roll."
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
