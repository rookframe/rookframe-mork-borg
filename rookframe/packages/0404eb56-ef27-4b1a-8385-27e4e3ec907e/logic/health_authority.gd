extends RefCounted

## Bare Bones pp. 29, 31, 33, 49. Eligibility and delayed consequences stay at the table.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const PARTICIPANTS = preload(ROOT + "logic/action_participants.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const CLASSES = preload(ROOT + "logic/creation_classes.gd")
const ITEMS = preload(ROOT + "logic/actor_inventory.gd")
const ABILITIES := ["Agility", "Presence", "Strength", "Toughness"]
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Array[Dictionary] = []

func handle(context: SDK.SystemActionContext, operation: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("The health action is malformed.")
	var input: Dictionary = payload
	if typeof(input.get("id")) != TYPE_STRING or str(input.id).is_empty() or str(input.id).length() > 64:
		return _error("Choose a new action identity.")
	var caller_result := context.caller()
	if not caller_result.ok:
		return _error(caller_result.message)
	var caller: Dictionary = caller_result.value
	var action: Dictionary = {}
	for entry in _actions:
		if entry.id == input.id:
			action = entry
			break
	if action.is_empty():
		if operation != "health.start" or context.read_throw(str(input.id)).ok:
			return {"state": "ended", "message": ENDED}
		action = _start(context, caller, input)
		action["id"] = input.id
		action["participant"] = caller.participant_id
		action["session"] = caller.session_id
		_actions.append(action)
		return _public(action)
	if action.participant != caller.participant_id or action.session != caller.session_id:
		return _error("This action belongs to another Participant session.")
	if not str(action.state) in ["pending", "scroll", "specialties"]:
		return _public(action)
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if operation == "health.cancel" or not PARTICIPANTS.new().alive(context, action) or not source.ok or source.actor.access_level != "Owner" or not _valid(source.actor.data):
		return _end(context, action)
	if str(action.state) in ["scroll", "specialties"]:
		return _choose(context, action, input, source.actor.data) if operation == "health.choose" else _public(action)
	if operation in ["health.advance", "health.start"]:
		return _public(_advance(context, action, source.actor.data))
	return _error("Unsupported health action.")

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	if typeof(input.get("source")) != TYPE_STRING or typeof(input.get("kind")) != TYPE_STRING or typeof(input.get("eligible")) != TYPE_BOOL:
		return _error("The health options are malformed.")
	var source := context.read_actor(SDK.ActorId.new(str(input.source)))
	if not source.ok or source.actor.access_level != "Owner":
		return _error("Owner access is required to use this Character.")
	if not _valid(source.actor.data):
		return _error("Character data is malformed. Correct the sheet first.")
	var data: Dictionary = source.actor.data
	if not input.eligible:
		return _error("Confirm eligibility with the table before rolling.")
	for active in _actions:
		if str(active.get("source", "")) == str(input.source) and str(active.state) in ["pending", "scroll", "specialties"]:
			if PARTICIPANTS.new().alive(context, active):
				return _error("Finish or cancel this Character's current recovery or improvement first.")
			_end(context, active)
	if str(input.kind) == "authorize":
		if not caller.is_gm:
			return _error("Only the GM can authorize improvement.")
		if not str(data.get("improvement_grant", "")).is_empty():
			return _error("This Character already has an unused improvement authorization.")
		var granted := data.duplicate(true)
		granted["improvement_grant"] = str(input.id)
		return _finish(context, {"state": "ready", "message": ""}, [SDK.ActorChange.new(source.actor.id, granted)], "GM authorized one improvement. The Character's Owner may begin Getting better.", "Authorized")
	var owner := PARTICIPANTS.new().owner(context, caller, source.actor.id)
	if owner.has("error"):
		return _error(str(owner.error))
	var action := {"id": str(input.id), "source": source.actor.id.value, "participant": str(caller.participant_id), "session": str(caller.session_id), "owner": str(owner.id), "owner_session": str(owner.session), "kind": str(input.kind), "request": str(input.id), "phase": "rest", "state": "pending", "message": "Complete the requested Throw in the Dice Tray."}
	if str(input.kind) == "broken":
		var hp: int = data.hit_points
		if hp > 0:
			return _error("Broken requires zero HP; negative HP means dead.")
		if hp < 0:
			return _finish(context, action, [], "Dead: negative HP. No Broken roll or restored HP. Resolve any applicable class exception with the table.", "Dead", "attention")
		return _request(context, action, "broken", [SDK.DiceTerm.new("Broken", 4)], true)
	if str(input.kind) == "improve":
		if not _improvable(data):
			return _error("Correct abilities, Silver and improvement history on the sheet first.")
		if str(data.get("improvement_grant", "")).is_empty():
			return _error("The GM must authorize this improvement first.")
		var history: int = data.get("improvements", 0)
		var traits: Array = data.get("traits", [])
		if str(data.get("class_id", "")) == "gutterborn-scum" and traits.size() != (1 if history == 0 else 2):
			return _error("Correct the Scum's specialty history before improving.")
		var improved := data.duplicate(true)
		improved["improvement_grant"] = ""
		var count: int = data.get("improvements", 0)
		improved["improvements"] = count + 1
		action["first_improvement"] = count == 0
		if not _record(context, [SDK.ActorChange.new(source.actor.id, improved)], "Improvement begun with GM authorization. Accepted changes remain if interrupted; resolve unfinished steps manually."):
			return _end(context, action)
		return _request(context, action, "more_hp", [SDK.DiceTerm.new("More HP", 10, 6)], true)
	if str(input.kind) != "rest":
		return _error("Choose a supported health action.")
	if typeof(input.get("food_and_drink")) != TYPE_BOOL or typeof(input.get("infected")) != TYPE_BOOL or not str(input.get("rest", "")) in ["breath", "sleep"]:
		return _error("Choose the rest and confirm food, drink and infection with the table.")
	var hp: int = data.hit_points
	if hp < 0:
		return _error("Negative HP means dead. Rest does not resurrect a Character.")
	if not input.food_and_drink or input.infected:
		return _finish(context, action, [], "No HP restored: resting requires food and drink and does not heal an infected Character. Resolve daily starvation or infection HP loss manually; no time has been advanced.", "0 HP")
	var faces := 4 if str(input.rest) == "breath" else 6
	var request := context.request_throw(SDK.HumanThrowRequest.new(str(input.id), str(owner.id), [SDK.DiceTerm.new("Recovery", faces)]))
	return action if request.ok else _error(request.message)

func _advance(context: SDK.SystemActionContext, action: Dictionary, current: Dictionary) -> Dictionary:
	var roll := context.read_throw(str(action.request))
	if not roll.ok or roll.status == "cancelled":
		return _end(context, action)
	if roll.status == "pending":
		return _public(action)
	if str(action.kind) == "broken":
		return _broken(context, action, current, roll)
	if str(action.kind) == "improve":
		return _improve(context, action, current, roll)
	var hp: int = current.hit_points
	var maximum: int = current.maximum_hit_points
	if hp < 0:
		return _end(context, action)
	var data := current.duplicate(true)
	var recovered: int = roll.terms[0].results[0]
	if recovered > maximum - hp:
		recovered = maximum - hp
	if recovered < 0:
		recovered = 0
	data["hit_points"] = hp + recovered
	return _finish(context, action, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], "Recovery: regained %d HP; now %d / %d. Raw Roll #%d. Omens and timed consequences remain table-managed." % [recovered, hp + recovered, maximum, roll.sequence], "+%d HP" % recovered, "success")

func _valid(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = value
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return false
	if typeof(data.get("hit_points")) != TYPE_INT or typeof(data.get("maximum_hit_points")) != TYPE_INT:
		return false
	if typeof(data.get("improvement_grant", "")) != TYPE_STRING:
		return false
	var maximum: int = data.maximum_hit_points
	return maximum > 0

func _finish(context: SDK.SystemActionContext, action: Dictionary, changes: Array[SDK.ActorChange], text: String, result: String = "Resolved", tone: String = "info") -> Dictionary:
	if not _record(context, changes, text, result, tone):
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return action

func _record(context: SDK.SystemActionContext, changes: Array[SDK.ActorChange], text: String, result: String = "", tone: String = "info") -> bool:
	var report := SDK.ActionLogMessage.new("Recovery and improvement")
	report.text = [SDK.ActionLogText.new(text)]
	report.result = result
	report.tone = tone
	return context.commit(changes, report).ok

func _end(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	action["state"] = "ended"
	action["message"] = ENDED
	context.cancel_throw(str(action.get("request", "")))
	_record(context, [], ENDED, "Ended", "attention")
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	return {"state": action.state, "message": action.message, "request": action.get("request", ""), "phase": action.get("phase", ""), "family": action.get("family", ""), "specialties": action.get("specialties", [])}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _improvable(data: Dictionary) -> bool:
	for key in ["silver", "improvements", "inventory_serial"]:
		if typeof(data.get(key, 0)) != TYPE_INT:
			return false
	if typeof(data.get("abilities")) != TYPE_DICTIONARY or typeof(data.get("inventory", [])) != TYPE_ARRAY or typeof(data.get("traits", [])) != TYPE_ARRAY:
		return false
	var history: int = data.get("improvements", 0)
	if history < 0:
		return false
	var inventory: Array = data.get("inventory", [])
	for raw in inventory:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = raw
		if typeof(item.get("inventory_id", "")) != TYPE_STRING or typeof(item.get("source_item_id", "")) != TYPE_STRING:
			return false
	var traits: Array = data.get("traits", [])
	for raw in traits:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
	var abilities: Dictionary = data.abilities
	for key in ABILITIES:
		if typeof(abilities.get(key)) != TYPE_DICTIONARY:
			return false
		var ability: Dictionary = abilities[key]
		if typeof(ability.get("modifier")) != TYPE_INT:
			return false
		var modifier: int = ability.modifier
		if modifier < -3 or modifier > 6:
			return false
	return true

func _request(context: SDK.SystemActionContext, action: Dictionary, phase: String, terms: Array[SDK.DiceTerm], first: bool = false) -> Dictionary:
	action["phase"] = phase
	action["state"] = "pending"
	action["request"] = str(action.id) if first else context.new_request_id()
	action["message"] = "Complete the requested Throw in the Dice Tray."
	var request := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), str(action.owner), terms))
	return action if request.ok else _end(context, action)

func _improve(context: SDK.SystemActionContext, action: Dictionary, current: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	if not _improvable(current):
		return _end(context, action)
	if str(action.phase) == "specialty_roll":
		return _specialty_result(context, action, current, roll)
	var data := current.duplicate(true)
	var value: int = roll.terms[0].results[0]
	var phase := str(action.phase)
	var suffix := " Raw Roll #%d." % roll.sequence
	var text := ""
	if phase == "more_hp":
		var total := 0
		for die in roll.terms[0].results:
			total += die
		var maximum: int = current.maximum_hit_points
		if not _record(context, [], "More HP: 6d10 = %d against maximum HP %d.%s" % [total, maximum, suffix]):
			return _end(context, action)
		return _request(context, action, "hp_increase", [SDK.DiceTerm.new("Maximum HP increase", 6)]) if total >= maximum else _debris(context, action)
	if phase == "hp_increase":
		var maximum: int = current.maximum_hit_points
		data["maximum_hit_points"] = maximum + value
		text = "Maximum HP increases by %d to %d. Current HP is unchanged.%s" % [value, maximum + value, suffix]
	elif phase == "debris":
		if value == 4:
			if not _record(context, [], "Debris: roll 3d10 Silver." + suffix):
				return _end(context, action)
			return _request(context, action, "silver", [SDK.DiceTerm.new("Silver", 10, 3)])
		if value in [5, 6]:
			action["family"] = "unclean" if value == 5 else "sacred"
			action["state"] = "scroll"
			action["message"] = "Choose the found %s scroll with the table; its identity is not specified by the debris rule." % str(action.family)
			if not _record(context, [], str(action.message) + suffix):
				return _end(context, action)
			return action
		text = "Nothing found in the debris." + suffix
	elif phase == "silver":
		var total := 0
		for die in roll.terms[0].results:
			total += die
		var silver: int = current.silver
		data["silver"] = silver + total
		text = "Silver: found %d; now %d.%s" % [total, silver + total, suffix]
	elif phase == "abilities":
		var abilities: Dictionary = data.abilities
		for index in range(ABILITIES.size()):
			var key: String = ABILITIES[index]
			var ability: Dictionary = abilities[key]
			var before: int = ability.modifier
			var face: int = roll.terms[index].results[0]
			var increase := face >= before
			if before <= 1:
				increase = face != 1
			var after := before + (1 if increase else -1)
			if after < -3:
				after = -3
			elif after > 6:
				after = 6
			ability["modifier"] = after
			text += "%s: d6 %d, %+d → %+d. " % [key, face, before, after]
		text += suffix
	else:
		return _end(context, action)
	if not _record(context, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], text):
		return _end(context, action)
	if phase == "hp_increase":
		return _debris(context, action)
	if phase in ["debris", "silver"]:
		return _ability_roll(context, action)
	if str(data.get("class_id", "")) == "gutterborn-scum":
		var traits: Array = data.get("traits", [])
		if action.first_improvement:
			if traits.size() != 1:
				return _end(context, action)
			action["reroll"] = [1]
			return _request(context, action, "specialty_roll", [SDK.DiceTerm.new("New specialty", 6)])
		if traits.size() != 2:
			return _end(context, action)
		action["state"] = "specialties"
		action["message"] = "Keep both specialties, or choose either or both to reroll."
		action["specialties"] = traits.duplicate(true)
		return action
	return _finish(context, action, [], "Improvement complete. " + text)

func _debris(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	return _request(context, action, "debris", [SDK.DiceTerm.new("Debris", 6)])

func _ability_roll(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	var terms: Array[SDK.DiceTerm] = []
	for key in ABILITIES:
		terms.append(SDK.DiceTerm.new(key, 6))
	return _request(context, action, "abilities", terms)

func _choose(context: SDK.SystemActionContext, action: Dictionary, input: Dictionary, current: Dictionary) -> Dictionary:
	if not _improvable(current):
		return _end(context, action)
	if str(action.state) == "specialties":
		if typeof(input.get("reroll")) != TYPE_ARRAY:
			return _public(action)
		var selected: Array = input.reroll
		if selected.size() > 2 or not _valid_rerolls(selected) or (selected.size() == 2 and selected[0] == selected[1]):
			return _public(action)
		if selected.is_empty():
			return _public(_finish(context, action, [], "Improvement complete. Both specialties retained."))
		action["reroll"] = selected.duplicate()
		return _public(_request(context, action, "specialty_roll", [SDK.DiceTerm.new("Specialty rerolls", 6, selected.size())]))
	var options: Array = SCROLLS.TABLES.get(str(action.family), [])
	var addition: Dictionary = {}
	for raw in options:
		var scroll: Dictionary = raw
		if str(scroll.source_item_id) == str(input.get("scroll", "")):
			addition = scroll.duplicate(true)
	if addition.is_empty():
		action["message"] = "Choose one %s scroll with the table." % str(action.family)
		return _public(action)
	var data := current.duplicate(true)
	var items := ITEMS.new(null, SDK.ActorId.new(str(action.source))).inventory(data)
	var serial: int = data.get("inventory_serial", 0)
	for raw in items:
		var item: Dictionary = raw
		var number := int(str(item.inventory_id))
		if number > serial:
			serial = number
	serial += 1
	addition["inventory_id"] = str(serial)
	addition["quantity"] = 1
	items.append(addition)
	data["inventory"] = items
	data["inventory_serial"] = serial
	if not _record(context, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], "Debris: found " + str(addition.name) + ". Added to Inventory. Casting restrictions still apply."):
		return _end(context, action)
	return _public(_ability_roll(context, action))

func _specialty_result(context: SDK.SystemActionContext, action: Dictionary, current: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var data := current.duplicate(true)
	var traits: Array = data.get("traits", [])
	var selected: Array = action.reroll
	if str(data.get("class_id", "")) != "gutterborn-scum" or traits.size() != (1 if action.first_improvement else 2):
		return _end(context, action)
	var text := "Improvement complete. "
	for index in range(selected.size()):
		var face: int = roll.terms[0].results[index]
		var feature := CLASSES.new().feature("gutterborn-scum", face)
		# 'Begin with lockpicks' is starting equipment, not an improvement grant.
		feature.erase("item")
		if action.first_improvement:
			traits = [traits[0], feature]
		else:
			var slot: int = selected[index]
			traits = [feature, traits[1]] if slot == 0 else [traits[0], feature]
		text += "Specialty d6 %d: %s. " % [face, str(feature.name)]
	data["traits"] = traits
	return _finish(context, action, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], text + "Raw Roll #%d. Omen benefits and delayed effects remain manual." % roll.sequence)

func _broken(context: SDK.SystemActionContext, action: Dictionary, current: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var hp: int = current.hit_points
	if hp != 0:
		return _end(context, action)
	var phase := str(action.phase)
	var face: int = roll.terms[0].results[0]
	var suffix := " Raw Roll #%d." % roll.sequence
	if phase == "broken":
		if face == 4:
			return _finish(context, action, [], "Dead. Resolve any applicable class exception with the table; no restored HP or automatic resurrection." + suffix, "Dead", "attention")
		var branch := "Unconscious" if face == 1 else ("Injury" if face == 2 else "Hemorrhage")
		if not _record(context, [], "Broken: " + branch + suffix):
			return _end(context, action)
		if face == 1:
			return _request(context, action, "unconscious", [SDK.DiceTerm.new("Unconscious rounds", 4), SDK.DiceTerm.new("Awakening HP", 4)])
		if face == 2:
			return _request(context, action, "injury", [SDK.DiceTerm.new("Injury", 6), SDK.DiceTerm.new("Unable to act rounds", 4), SDK.DiceTerm.new("Recovery HP", 4)])
		return _request(context, action, "hemorrhage", [SDK.DiceTerm.new("Death in hours (d2)", 4)])
	var text := ""
	if phase == "unconscious":
		text = "Unconscious: awaken with %d HP after %d rounds." % [roll.terms[1].results[0], face]
	elif phase == "injury":
		text = "%s. Cannot act for %d rounds, then become active with %d HP." % ["Lost eye" if face == 6 else "Broken or severed limb (table decides)", roll.terms[1].results[0], roll.terms[2].results[0]]
	else:
		var hours := int((face + 1) / 2)
		text = "Hemorrhage: death in %d hours unless treated. All tests DR16 the first hour, DR18 the last hour. Physical d4 %d → d2 %d." % [hours, face, hours]
	return _finish(context, action, [], text + " Apply delayed recovery, restrictions and death manually; current HP is unchanged." + suffix, "Broken", "attention")

func _valid_rerolls(selected: Array) -> bool:
	for index in selected:
		if typeof(index) != TYPE_INT or not index in [0, 1]:
			return false
	return true
