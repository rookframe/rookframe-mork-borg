extends RefCounted

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const POWERS = preload(ROOT + "logic/powers.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Array[Dictionary] = []

func handle(context: SDK.SystemActionContext, operation: String, payload: Variant) -> Variant:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("The casting action is malformed.")
	var input: Dictionary = payload
	if typeof(input.get("id")) != TYPE_STRING or str(input.id).is_empty() or str(input.id).length() > 64:
		return _error("Choose a new casting action identity.")
	var requester := context.caller()
	if not requester.ok:
		return _error(requester.message)
	var caller: Dictionary = requester.value
	var id: String = input.id
	var action := _find(id)
	if action.is_empty():
		if not operation in ["power.start", "power.daily"] or context.read_throw(id).ok:
			return {"state": "ended", "message": ENDED}
		var started := _start(context, caller, input, operation == "power.daily")
		if started.state == "error":
			started["id"] = id
			started["participant"] = str(caller.participant_id)
			started["session"] = str(caller.session_id)
			started["request"] = ""
			_actions.append(started)
		return _public(started)
	if action.participant != caller.participant_id or action.session != caller.session_id:
		return _error("This action belongs to another Participant session.")
	if not action.state in ["pending", "targets"]:
		return _public(action)
	if not _alive(context, action):
		return _end(context, action)
	if operation == "power.targets" and action["state"] == "targets":
		var source := context.read_actor(SDK.ActorId.new(action.source))
		if not source.ok or source.actor.access_level != "Owner":
			return _end(context, action)
		var count: int = action.count
		var selected := _targets(context, caller, action.rook, source.actor.id, action.scroll, count)
		if selected.state == "error":
			action["message"] = selected.message
			action["target_error"] = true
			return _public(action)
		action["target_error"] = false
		action["targets"] = selected.targets
		action["target_rooks"] = caller.targets
		action["label"] = selected.label
		var power: Dictionary = action.scroll
		if str(power.source_item_id) in ["grace-of-a-dead-saint", "roskoes-consuming-glare", "palms-open-the-southern-gate"]:
			var healing: bool = str(power.source_item_id) == "grace-of-a-dead-saint"
			var damage: bool = str(power.source_item_id) == "palms-open-the-southern-gate"
			var purpose := "healing" if healing else ("damage" if damage else "HP loss")
			var terms: Array[SDK.DiceTerm] = []
			var targets: Array = selected.targets
			for index in range(targets.size()):
				var target: Dictionary = targets[index]
				# Unique, bounded term names preserve the mapping even for identical public labels.
				var label := "%d. %s" % [index + 1, _dice_label(str(target.label))]
				terms.append(SDK.DiceTerm.new(label + " · " + purpose, 10 if healing else 8))
				if damage:
					var protection: Dictionary = target.protection
					var formula: String = protection.formula
					if not formula.is_empty():
						terms.append(_armor_die(formula, label + " · armor"))
			var message := "Throw %s for each confirmed target in the Dice Tray." % purpose
			if damage:
				message += " Armor and shield reduction apply. d2 armor uses a physical d4 halved, rounded up. Shield breaking stays at the table; close before applying damage if the table chooses it."
			return _request(context, action, "hp", terms, message)
		return _resist(context, action)
	if operation == "power.cancel":
		return _end(context, action)
	if action["state"] == "targets":
		return _public(action)
	if operation in ["power.advance", "power.start"]:
		return _advance(context, action)
	return _error("Unsupported Power action.")

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary, daily: bool) -> Dictionary:
	for key in ["source", "rook", "item"]:
		if typeof(input.get(key, "")) != TYPE_STRING:
			return _error("The casting options are malformed.")
	var source := context.read_actor(SDK.ActorId.new(str(input.get("source", ""))))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Owner access is required to cast from this Character.")
	var data: Dictionary = source.actor.data
	if not _valid_character(data):
		return _error("Character casting data is malformed.")
	var owner := _owner(context, caller, source.actor.id)
	if owner.has("error"):
		return _error(owner.error)
	for previous in _actions:
		if str(previous.state) in ["pending", "targets"] and previous.get("source", "") == source.actor.id.value:
			if _alive(context, previous):
				return _error("Finish the current Power action before starting another.")
			_end(context, previous)
	var abilities: Dictionary = data.abilities
	if daily:
		if typeof(input.get("morning_confirmed", false)) != TYPE_BOOL or not input.get("morning_confirmed", false):
			return _error("Confirm with the table that this is the morning allowance roll.")
		var ability: Dictionary = abilities.get("Presence", {})
		var daily_presence: int = ability.get("modifier", 0)
		var action := {"id": str(input.id), "participant": str(caller.participant_id), "session": str(caller.session_id), "owner": owner.id, "owner_session": owner.session, "source": source.actor.id.value, "phase": "daily", "presence": daily_presence, "request": str(input.id), "state": "pending", "message": "Throw today's Power allowance in the Dice Tray."}
		var requested := context.request_throw(SDK.HumanThrowRequest.new(action.id, action.owner, [SDK.DiceTerm.new("Daily uses + Presence", 4)]))
		if not requested.ok:
			return _error(requested.message)
		_actions.append(action)
		return action
	var scroll := _scroll(data, str(input.get("item", "")))
	if scroll.is_empty():
		return _error("Choose an owned core scroll in Inventory.")
	var uses: int = data.get("power_uses", 0)
	if uses <= 0:
		return _error("No daily Power uses remain. Establish today's allowance with the table.")
	if not scroll.playable:
		return _error("This Power's %s branch is not playable yet." % str(scroll.handling))
	if typeof(input.get("eligible", false)) != TYPE_BOOL or not input.get("eligible", false):
		return _error("Confirm with the table that you are not dizzy and the Power's fictional requirements are met. While dizzy, Powers fail in the worst possible way; the GM handles that outcome.")
	if typeof(input.get("modifier", 0)) != TYPE_INT:
		return _error("Enter a whole-number situational modifier.")
	var situation: int = input.get("modifier", 0)
	if situation < -20 or situation > 20:
		return _error("Enter a whole-number situational modifier from −20 to +20.")
	var restriction := _restriction(data)
	if not restriction.is_empty():
		return _error(restriction)
	var targeting := _targets(context, caller, str(input.get("rook", "")), source.actor.id, scroll)
	if targeting.state == "error":
		return targeting
	var presence: Dictionary = abilities.get("Presence", {})
	var modifier: int = presence.get("modifier", 0)
	var action := {"id": str(input.id), "participant": str(caller.participant_id), "session": str(caller.session_id), "source": source.actor.id.value, "owner": owner.id, "owner_session": owner.session, "item": str(input.item), "scroll": scroll, "presence": modifier, "phase": "casting", "sequence": 0, "modifier": modifier + situation, "difficulty": 10 if str(data.get("class_id", "")) == "gutterborn-scum" else 12, "label": targeting.label, "targets": targeting.get("targets", []), "rook": str(input.get("rook", "")), "request": str(input.id), "state": "pending", "message": "Waiting for the casting Throw in the Dice Tray."}
	var requested := context.request_throw(SDK.HumanThrowRequest.new(action.id, action.owner, [SDK.DiceTerm.new("Casting", 20)]))
	if not requested.ok:
		return _error(requested.message)
	_actions.append(action)
	return action

func _advance(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	if not _alive(context, action):
		return _end(context, action)
	var source := context.read_actor(SDK.ActorId.new(action.source))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var data: Dictionary = source.actor.data
	if not _valid_character(data):
		return _end(context, action)
	var result := context.read_throw(action.request)
	if not result.ok or result.status == "cancelled":
		return _end(context, action)
	if result.status == "pending":
		return _public(action)
	var presence: int = action.presence
	var sequence: int = action.get("sequence", 0)
	var power: Dictionary = action.get("scroll", {})
	if action["phase"] == "hp":
		return _hp_result(context, action, result)
	if action["phase"] == "daily":
		var daily_face: int = result.terms[0].results[0]
		var count: int = daily_face + presence
		data = data.duplicate(true)
		var usable: int = count if count > 0 else 0
		data["power_uses"] = usable
		return _complete(context, action, [SDK.ActorChange.new(source.actor.id, data)], "Daily allowance", "Morning allowance: Presence %+d + d4 %d = %d. %d usable Powers today. The table establishes the morning; no time or replenishment is automatic. Raw Roll #%d." % [presence, daily_face, count, usable, result.sequence])
	if action["phase"] == "casting" and (_scroll(data, action.item).is_empty() or not _restriction(data).is_empty()):
		return _end(context, action)
	if action["phase"] == "resistance":
		return _sleep_result(context, action, result.terms[0].results, result.sequence)
	if str(action.phase) in ["parameters", "bolts"]:
		var values: Array[int] = []
		for term in result.terms:
			for value in term.results:
				values.append(value)
		if action["phase"] == "parameters" and str(power.source_item_id) in ["grace-of-a-dead-saint", "roskoes-consuming-glare", "palms-open-the-southern-gate"]:
			var d2: bool = str(power.source_item_id) != "roskoes-consuming-glare"
			var count: int = int((values[0] + 1) / 2) if d2 else values[0]
			action["count"] = count
			action["quantity_sequence"] = result.sequence
			action["state"] = "targets"
			var message := "Choose exactly %d distinct creatures within 30 ft, then confirm targets." % count
			if d2:
				message += " d2 count used a physical d4 halved, rounded up."
			action["message"] = message
			return _public(action)
		if action["phase"] == "parameters" and str(power.source_item_id) == "eyelid-blinds-the-mind":
			action["count"] = values[0]
			action["quantity_sequence"] = result.sequence
			action["state"] = "targets"
			action["message"] = "Choose exactly %d distinct creatures within 30 ft, then confirm targets. Creature resistance is DR14; the source does not specify a PC ability." % values[0]
			return _public(action)
		if action["phase"] == "parameters" and str(power.source_item_id) == "nine-violet-signs-unknot-the-storm":
			return _request(context, action, "bolts", [SDK.DiceTerm.new("Bolt damage", 6, int((values[0] + 1) / 2))], "Throw damage for each bolt; allocation stays with the table.")
		return _manual_result(context, action, [], values, result.sequence)
	var face: int = result.terms[0].results[0]
	if action["phase"] == "failure":
		var loss := int((face + 1) / 2)
		var hp: int = data.get("hit_points", 0)
		data = data.duplicate(true)
		data["hit_points"] = hp - loss
		return _complete(context, action, [SDK.ActorChange.new(source.actor.id, data)], "Failed", "%s failed: lose %d HP (physical d4 halved, rounded up). No daily use spent. The caster is dizzy for one hour; Powers fail in the worst possible way during this time. Handle dizziness and expiry manually. Raw Rolls #%d and #%d." % [str(power.name), loss, sequence, result.sequence])
	action["sequence"] = result.sequence
	if face in [1, 20]:
		var kind := "critical" if face == 20 else "fumble"
		action["natural_face"] = face
		action["adjudication"] = kind
		return _complete(context, action, [], "GM adjudication", "Power %s: GM determines the outcome. %s · natural %d. Raw Roll #%d. Resolve the outcome and any resource changes with ordinary dice and sheet editing." % [kind, str(power.name), face, result.sequence])
	var modifier: int = action.modifier
	var difficulty: int = action.difficulty
	if face + modifier < difficulty:
		return _request(context, action, "failure", [SDK.DiceTerm.new("Failure HP loss (d2)", 4)], "Casting failed. Throw d2 HP loss in the Dice Tray (physical d4).")
	var uses: int = data.get("power_uses", 0)
	if uses <= 0:
		return _end(context, action)
	data = data.duplicate(true)
	data["power_uses"] = uses - 1
	var terms := POWERS.new().parameters(str(power.source_item_id))
	if terms.is_empty():
		return _manual_result(context, action, [SDK.ActorChange.new(source.actor.id, data)], [], result.sequence)
	var report := SDK.ActionLogMessage.new("Power activated")
	report.result = "1 use spent"
	report.text = [SDK.ActionLogText.new("%s activated. One daily use spent. Raw Roll #%d; stated parameters follow in the Dice Tray." % [str(power.name), result.sequence])]
	if not context.commit([SDK.ActorChange.new(source.actor.id, data)], report).ok:
		return _end(context, action)
	return _request(context, action, "parameters", terms, "Power activated. Throw its stated quantities in the Dice Tray.")

func _manual_result(context: SDK.SystemActionContext, action: Dictionary, changes: Array[SDK.ActorChange], values: Array[int], sequence: int) -> Dictionary:
	var power: Dictionary = action.scroll
	var presence: int = action.presence
	var casting_sequence: int = action.sequence
	var description := POWERS.new().report(str(power.source_item_id), values, presence)
	return _complete(context, action, changes, "Manual outcome", "%s · %s. %s Handle at the table; no effects or expiry are automated. One daily use spent. Raw Rolls #%d / #%d." % [str(power.name), str(action.label), description, casting_sequence, sequence])

func _hp_result(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var power: Dictionary = action.scroll
	var healing: bool = str(power.source_item_id) == "grace-of-a-dead-saint"
	var damage: bool = str(power.source_item_id) == "palms-open-the-southern-gate"
	var term_index := 0
	var changes: Array[SDK.ActorChange] = []
	var details := ""
	var targets: Array = action.targets
	var count: int = action.count
	var selected := _targets(context, {"targets": action.target_rooks}, action.rook, SDK.ActorId.new(action.source), power, count)
	if selected.state == "error":
		return _end(context, action)
	var checked: Array = selected.targets
	for index in range(targets.size()):
		var target: Dictionary = targets[index]
		var confirmed: Dictionary = checked[index]
		if target.actor != confirmed.actor or target.schema != confirmed.schema:
			return _end(context, action)
		var current := context.read_actor(SDK.ActorId.new(target.actor))
		if not current.ok or typeof(current.actor.data) != TYPE_DICTIONARY:
			return _end(context, action)
		var data: Dictionary = current.actor.data.duplicate(true)
		if typeof(data.get("hit_points")) != TYPE_INT or (healing and typeof(data.get("maximum_hit_points")) != TYPE_INT):
			return _end(context, action)
		var hp: int = data.hit_points
		var rolled: int = roll.terms[term_index].results[0]
		term_index += 1
		var amount := rolled
		var reduction: int = 0
		var shield: int = 0
		if damage:
			var protection: Dictionary = target.protection
			if protection != confirmed.protection:
				return _end(context, action)
			var formula: String = protection.formula
			shield = protection.shield
			if not formula.is_empty():
				for face in roll.terms[term_index].results:
					reduction += int((face + 1) / 2) if formula == "d2" else face
				if formula == "d4+1":
					reduction += 1
				term_index += 1
			amount = rolled - reduction - shield
			if amount < 0:
				amount = 0
		if healing:
			var maximum: int = data.maximum_hit_points
			if hp >= maximum:
				amount = 0
			elif amount > maximum - hp:
				amount = maximum - hp
		data["hit_points"] = hp + amount if healing else hp - amount
		changes.append(SDK.ActorChange.new(current.actor.id, data))
		if damage:
			details += "%s: lost %d HP (damage %d, armor %d, shield %d). " % [str(confirmed.label), amount, rolled, reduction, shield]
		else:
			details += "%s: %s %d HP (rolled %d). " % [str(confirmed.label), "regained" if healing else "lost", amount, rolled]
	var cast_sequence: int = action.sequence
	var count_sequence: int = action.quantity_sequence
	if damage:
		details += "d2 armor used a physical d4 halved, rounded up. "
	var outcome := "Healing applied" if healing else ("Damage applied" if damage else "HP loss applied")
	return _complete(context, action, changes, outcome, "%s. %sOne daily use spent. Raw Rolls #%d, #%d, #%d." % [str(power.name), details, cast_sequence, count_sequence, roll.sequence])

func _protection(data: Dictionary) -> Dictionary:
	var formula := ""
	var shield: int = 0
	if str(data.get("schema", "")) == "mork-borg-adversary/v1":
		if typeof(data.get("armor", {})) != TYPE_DICTIONARY:
			return {"error": "Target armor data is malformed. Correct its sheet before casting."}
		var armor: Dictionary = data.get("armor", {})
		if typeof(armor.get("reduction", "")) != TYPE_STRING:
			return {"error": "Target armor data is malformed. Correct its sheet before casting."}
		formula = str(armor.get("reduction", ""))
	else:
		if typeof(data.get("inventory", [])) != TYPE_ARRAY or typeof(data.get("inventory_serial", 0)) != TYPE_INT:
			return {"error": "Target inventory is malformed. Correct its sheet before casting."}
		var inventory: Array = data.get("inventory", [])
		for raw in inventory:
			if typeof(raw) != TYPE_DICTIONARY:
				return {"error": "Target inventory is malformed. Correct its sheet before casting."}
			var item: Dictionary = raw
			for key in ["equipped", "broken"]:
				if typeof(item.get(key, false)) != TYPE_BOOL:
					return {"error": "Target equipment is malformed. Correct its sheet before casting."}
			if typeof(item.get("quantity", 1)) != TYPE_INT:
				return {"error": "Target equipment is malformed. Correct its sheet before casting."}
			for key in ["kind", "source_item_id", "inventory_id", "reduction"]:
				if typeof(item.get(key, "")) != TYPE_STRING:
					return {"error": "Target equipment is malformed. Correct its sheet before casting."}
		for raw in ITEMS.new(null, SDK.ActorId.new("")).inventory(data):
			var item: Dictionary = raw
			var quantity: int = item.quantity
			if not item.equipped or item.get("broken", false) or quantity < 1:
				continue
			if str(item.get("kind", "")) == "Armor":
				formula = str(item.get("reduction", ""))
			elif str(item.get("kind", "")) == "Shield":
				shield = 1
	if not formula.is_empty() and _armor_die(formula, "Armor") == null:
		return {"error": "Target armor dice are unsupported. Correct its sheet before casting."}
	return {"formula": formula, "shield": shield}

func _armor_die(formula: String, label: String) -> SDK.DiceTerm:
	# These are the reduction formulas supported by ordinary item editing.
	var dice: Dictionary = {"d2": [4, 1], "d4": [4, 1], "d6": [6, 1], "d8": [8, 1], "d10": [10, 1], "d12": [12, 1], "2d6": [6, 2], "2d8": [8, 2], "d4+1": [4, 1]}
	if not dice.has(formula):
		return null
	var parts: Array = dice.get(formula, [])
	var faces: int = parts[0]
	var count: int = parts[1]
	return SDK.DiceTerm.new(label, faces, count)

func _dice_label(label: String) -> String:
	# Leave room for numbering and purpose within the host's 64 UTF-16-unit limit.
	var result := ""
	for character in label.split(""):
		if result.length() >= 16:
			break
		result += character
	return result

func _complete(context: SDK.SystemActionContext, action: Dictionary, changes: Array[SDK.ActorChange], outcome: String, text: String) -> Dictionary:
	var report := SDK.ActionLogMessage.new("Power casting")
	report.result = outcome
	report.text = [SDK.ActionLogText.new(text)]
	var saved := context.commit(changes, report)
	if not saved.ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	action["outcome"] = outcome
	return _public(action)

func _end(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	action["state"] = "ended"
	action["message"] = ENDED
	context.cancel_throw(action.request)
	var report := SDK.ActionLogMessage.new("Power action ended")
	report.result = "ENDED"
	report.text = [SDK.ActionLogText.new(ENDED)]
	context.commit([], report)
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	return {"state": action.state, "message": action.message, "request": action.get("request", ""), "natural_face": action.get("natural_face", 0), "adjudication": action.get("adjudication", ""), "outcome": action.get("outcome", ""), "target_error": action.get("target_error", false)}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _valid_character(data: Dictionary) -> bool:
	if str(data.get("schema", "")) != "mork-borg-character/v1" or typeof(data.get("inventory")) != TYPE_ARRAY or typeof(data.get("abilities")) != TYPE_DICTIONARY:
		return false
	for key in ["power_uses", "hit_points", "inventory_serial"]:
		if typeof(data.get(key, 0)) != TYPE_INT:
			return false
	var inventory: Array = data.inventory
	for raw in inventory:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = raw
		for key in ["quantity", "armor_tier", "penalty_tier"]:
			if typeof(item.get(key, 0)) != TYPE_INT:
				return false
		for key in ["equipped", "two_handed", "broken"]:
			if typeof(item.get(key, false)) != TYPE_BOOL:
				return false
		for key in ["inventory_id", "source_item_id", "kind"]:
			if typeof(item.get(key, "")) != TYPE_STRING:
				return false
	var abilities: Dictionary = data.abilities
	if typeof(abilities.get("Presence", {})) != TYPE_DICTIONARY:
		return false
	var presence: Dictionary = abilities.get("Presence", {})
	return typeof(presence.get("modifier", 0)) == TYPE_INT

func _scroll(data: Dictionary, id: String) -> Dictionary:
	var inventory: Array = data.inventory
	for raw in inventory:
		if typeof(raw) != TYPE_DICTIONARY:
			return {}
	var items := ITEMS.new(null, SDK.ActorId.new("")).inventory(data)
	for raw in items:
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("inventory_id", "")) != id or quantity <= 0:
			continue
		return POWERS.new().definition(str(item.get("source_item_id", "")))
	return {}

func _request(context: SDK.SystemActionContext, action: Dictionary, phase: String, terms: Array[SDK.DiceTerm], message: String, receiver: String = "") -> Dictionary:
	action["state"] = "pending"
	action["request"] = context.new_request_id()
	action["phase"] = phase
	var requested := context.request_throw(SDK.HumanThrowRequest.new(action.request, action.owner if receiver.is_empty() else receiver, terms))
	if not requested.ok:
		return _end(context, action)
	action["message"] = message
	return _public(action)

func _restriction(data: Dictionary) -> String:
	if str(data.get("class_id", "")) == "fanged-deserter":
		return "Fanged Deserters cannot understand scrolls."
	var inventory: Array = data.inventory
	for raw in inventory:
		if typeof(raw) != TYPE_DICTIONARY:
			return "Inventory data is malformed."
		var item: Dictionary = raw
		if not item.get("equipped", false):
			continue
		if str(item.get("source_item_id", "")) == "zweihander" or item.get("two_handed", false):
			return "Scrolls do not work while wielding zweihand weapons. Unequip the weapon first."
		if str(item.get("kind", "")) == "Armor":
			var tier: int = item.get("penalty_tier", item.get("armor_tier", 0))
			if tier >= 3 or (tier == 2 and str(data.get("class_id", "")) != "heretical-priest"):
				return "Scrolls do not work in medium/heavy armor. Only the Heretical Priest may cast in medium armor."
	return ""

func _targets(context: SDK.SystemActionContext, caller: Dictionary, source_rook: String, source: SDK.ActorId, power: Dictionary, count: int = 0) -> Dictionary:
	var mode: String = power.target_mode
	if mode == "self":
		return {"state": "ready", "label": "Self", "targets": []}
	var rook_id := SDK.RookId.new(source_rook)
	var rook := context.read_rook(rook_id)
	if not rook.ok or rook.rook.actor == null or rook.rook.actor.value != source.value or rook.rook.scene.value != "main":
		return _error("Select this Character’s source Rook in the current Scene.")
	var target_ids: PackedStringArray = caller.targets
	var targets: Array = []
	var labels := ""
	var outside := ""
	var invalid := ""
	var actors: Array[String] = []
	var reach: int = power.area_feet if mode == "area" else power.range_feet
	for id in target_ids:
		var target_rook := context.read_rook(SDK.RookId.new(id))
		if not target_rook.ok:
			invalid = "A target is unavailable."
			continue
		var label := "Object"
		var schema := ""
		var actor_id := ""
		var protection: Dictionary = {}
		if target_rook.rook.actor != null:
			var target := context.read_actor(target_rook.rook.actor)
			if not target.ok or typeof(target.actor.data) != TYPE_DICTIONARY:
				invalid = "A targeted Actor is unavailable."
				continue
			var target_data: Dictionary = target.actor.data
			schema = str(target_data.get("schema", ""))
			actor_id = target.actor.id.value
			label = target.actor.public_label if not target.actor.public_label.is_empty() else "Creature"
			if str(power.source_item_id) in ["grace-of-a-dead-saint", "roskoes-consuming-glare", "palms-open-the-southern-gate"]:
				if typeof(target_data.get("hit_points")) != TYPE_INT:
					invalid = "Target HP data is malformed. Correct its sheet before casting."
				if str(power.source_item_id) == "palms-open-the-southern-gate":
					protection = _protection(target_data)
					if protection.has("error"):
						invalid = str(protection.error)
				if str(power.source_item_id) == "grace-of-a-dead-saint":
					if typeof(target_data.get("maximum_hit_points")) != TYPE_INT:
						invalid = "Target maximum HP is malformed. Correct its sheet before casting."
					else:
						var maximum_hp: int = target_data.maximum_hit_points
						if maximum_hp < 1:
							invalid = "Target maximum HP must be positive. Correct its sheet before casting."
					if typeof(target_data.get("hit_points")) == TYPE_INT:
						var hp: int = target_data.hit_points
						if hp < 0:
							invalid = "Grace of a dead saint restores HP; it does not resurrect a dead target."
		if mode != "object" and not schema in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
			invalid = "Every target must be a Character or Creature."
		if not actor_id.is_empty() and actor_id in actors:
			invalid = "Choose each target Actor only once."
		actors.append(actor_id)
		var distance := context.distance(rook_id, SDK.RookId.new(id))
		if not distance.ok:
			invalid = distance.message
		elif distance.distance > float(reach) * 0.3048 + 0.000001:
			outside += ("\n" if not outside.is_empty() else "") + "target %s not in range" % label
		targets.append({"actor": actor_id, "schema": schema, "label": label, "protection": protection})
		labels += (", " if not labels.is_empty() else "") + label
	if not outside.is_empty():
		var report := SDK.ActionLogMessage.new("Power out of range")
		report.result = "Stopped"
		for line in outside.split("\n"):
			report.text.append(SDK.ActionLogText.new(line))
		context.commit([], report)
		return _error(outside)
	if not invalid.is_empty():
		return _error(invalid)
	if mode == "single" and targets.size() != 1:
		return _error("Choose exactly one creature target.")
	var maximum := 2 if str(power.source_item_id) in ["grace-of-a-dead-saint", "palms-open-the-southern-gate"] else 4
	if mode == "multiple" and ((count > 0 and targets.size() != count) or targets.size() > maximum):
		return _error("Choose exactly %d distinct creature targets." % count if count > 0 else "Choose up to %d creature targets; the Throw determines the count." % maximum)
	if mode == "object" and targets.size() > 1:
		return _error("Choose one object; describe an unrepresented object with the table.")
	return {"state": "ready", "label": labels if not labels.is_empty() else ("All creatures in the 30 ft area" if mode == "area" else "Table-selected object"), "targets": targets}

func _owner(context: SDK.SystemActionContext, caller: Dictionary, source: SDK.ActorId) -> Dictionary:
	var owner := {"id": str(caller.participant_id), "session": str(caller.session_id)}
	if caller.is_gm:
		var access := context.actor_access(source)
		if not access.ok:
			return {"error": access.message}
		var count := 0
		for entry in access.items:
			if entry.access_level == "Owner":
				count += 1
				if not entry.is_connected:
					return {"error": "This Character’s Player is not connected."}
				owner = {"id": entry.participant_id, "session": entry.session_id}
		if count > 1:
			return {"error": "Several Players own this Character. The responsible Player casts from their sheet."}
	return owner

func _alive(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	var sessions := context.participant_sessions()
	if not sessions.ok:
		return false
	var resister := not action.has("resister_session")
	var initiator := false
	var owner := false
	var participants: Array = sessions.value
	for raw in participants:
		var session: Dictionary = raw
		if session.session_id == action.get("resister_session", ""):
			resister = true
		if session.participant_id == action.participant and session.session_id == action.session:
			initiator = true
		if session.participant_id == action.owner and session.session_id == action.owner_session:
			owner = true
	if not initiator or not owner or not resister:
		return false
	if action.owner != action.participant:
		var access := context.actor_access(SDK.ActorId.new(action.source))
		if not access.ok:
			return false
		for entry in access.items:
			if entry.participant_id == action.owner and entry.access_level == "Owner" and entry.is_connected and entry.session_id == action.owner_session:
				return true
		return false
	return true

func _resist(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	var creatures := 0
	var targets: Array = action.targets
	for raw in targets:
		var target: Dictionary = raw
		if target.schema == "mork-borg-adversary/v1":
			creatures += 1
	if creatures == 0:
		var quantity_sequence: int = action.quantity_sequence
		return _sleep_result(context, action, [], quantity_sequence)
	var sessions := context.participant_sessions()
	if sessions.ok:
		var participants: Array = sessions.value
		for raw in participants:
			var participant: Dictionary = raw
			if participant.is_gm:
				action["resister_session"] = str(participant.session_id)
				return _request(context, action, "resistance", [SDK.DiceTerm.new("Creature resistance DR14", 20, creatures)], "Waiting for the GM's Creature resistance Throw (DR14).", str(participant.participant_id))
	action["message"] = "The GM must be connected to throw Creature resistance. Confirm targets when present, or close and finish manually."
	return _public(action)

func _sleep_result(context: SDK.SystemActionContext, action: Dictionary, values: Array[int], sequence: int) -> Dictionary:
	var count: int = action.count
	var casting_sequence: int = action.sequence
	var quantity_sequence: int = action.quantity_sequence
	var description := "Eyelid blinds the mind. %d creatures fall asleep for one hour unless they succeed a DR14 test. " % count
	var index := 0
	var targets: Array = action.targets
	for raw in targets:
		var target: Dictionary = raw
		if target.schema == "mork-borg-adversary/v1":
			var value: int = values[index]
			index += 1
			description += "%s: d20 %d, %s. " % [str(target.label), value, "resists" if value >= 14 else "asleep for one hour"]
		else:
			description += "%s: PC ability is unspecified; the table chooses and resolves the DR14 test. " % str(target.label)
	description += "Handle sleep and expiry manually; no conditions are stored. Raw Rolls #%d, #%d, #%d." % [casting_sequence, quantity_sequence, sequence]
	return _complete(context, action, [], "Manual sleep", description)

func _find(id: String) -> Dictionary:
	for action in _actions:
		if str(action.id) == id:
			return action
	return {}
