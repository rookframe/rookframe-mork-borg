extends RefCounted

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const CLASSES = preload(ROOT + "logic/creation_classes.gd")
const RULES = preload(ROOT + "logic/special_rules.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const PARTICIPANTS = preload(ROOT + "logic/action_participants.gd")
const DAMAGE = preload(ROOT + "logic/special_damage.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Array[Dictionary] = []

func handle(context: SDK.SystemActionContext, operation: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("The use options are malformed.")
	var input: Dictionary = payload
	if typeof(input.get("id")) != TYPE_STRING or str(input.id).is_empty() or str(input.id).length() > 64:
		return _error("Choose a new action identity.")
	var caller := context.caller()
	if not caller.ok:
		return _error(caller.message)
	var participant: Dictionary = caller.value
	var id: String = input.id
	var action := _find(id)
	if action.is_empty():
		if operation != "special.start" or context.read_throw(id).ok:
			return {"state": "ended", "message": ENDED}
		action = _start(context, participant, input)
		action.merge({"id": id, "participant": participant.participant_id, "session": participant.session_id})
		_actions.append(action)
		return _public(action)
	var shield_owner: Dictionary = action.get("shield_owner", {})
	var defender := str(shield_owner.get("id", "")) == str(participant.participant_id) and str(shield_owner.get("session", "")) == str(participant.session_id)
	if not defender and (action.participant != participant.participant_id or action.session != participant.session_id):
		return _error("This action belongs to another Participant session.")
	if not str(action.state) in ["pending", "scrolls", "witnesses", "shield"]:
		return _public(action)
	if operation == "special.cancel" or not _current(context, action):
		return _end(context, action)
	if str(action.state) == "shield":
		if defender and operation == "special.choose":
			return _choose_shield(context, action, input)
		return _shield_public(context, action) if defender else {"state": "pending", "message": "Waiting for the recipient's shield decision."}
	if str(action.state) == "witnesses":
		return _witnesses(context, action, participant, input) if operation == "special.witnesses" else _public(action)
	if str(action.state) == "scrolls":
		return _choose_scrolls(context, action, input) if operation == "special.scrolls" else _public(action)
	if operation in ["special.advance", "special.start"]:
		return _advance(context, action)
	return _error("Unsupported item action.")

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	for key in ["source", "rook", "item"]:
		if typeof(input.get(key, "")) != TYPE_STRING:
			return _error("The use options are malformed.")
	if typeof(input.get("adjustment", 0)) != TYPE_INT:
		return _error("Enter a whole-number DR adjustment agreed with the table.")
	for key in ["self", "eligible", "new_fight"]:
		if typeof(input.get(key, false)) != TYPE_BOOL:
			return _error("The use options are malformed.")
	for active in _actions:
		if str(active.get("source", "")) == str(input.get("source", "")) and str(active.state) in ["pending", "scrolls", "witnesses", "shield"]:
			if PARTICIPANTS.new().alive(context, active):
				return _error("Finish or cancel this Character's current item action first.")
			_end(context, active)
	var source := context.read_actor(SDK.ActorId.new(str(input.get("source", ""))))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Owner access is required to use this Character's equipment.")
	var data: Dictionary = source.actor.data
	if not _valid(data):
		return _error("Character data is malformed. Correct the sheet first.")
	var item := RULES.new().owned(data, str(input.get("item", "")))
	var rule := RULES.new().definition(str(item.get("source_item_id", "")))
	if item.is_empty() or rule.is_empty():
		return _error("Choose a supported item in Inventory.")
	if rule.get("brew", false) and str(data.get("class_id", "")) != "occult-herbmaster":
		return _error("Only the Occult Herbmaster can brew daily decoctions.")
	if not input.get("eligible", false):
		return _error("Confirm the item's fictional requirements with the table.")
	if rule.get("ability_choice", false):
		var chosen := str(input.get("ability", ""))
		if not chosen in ["Agility", "Presence", "Strength", "Toughness"]:
			return _error("The source leaves the ability unspecified. Choose it with the table.")
		rule["ability"] = chosen
	if str(item.source_item_id) == "stolen-mitre" and not item.get("equipped", false):
		return _error("Wear the mitre and confirm that its ears are covered outside battle.")
	var teeth := str(item.get("source_item_id", "")) == "wizard-teeth"
	var healing: bool = rule.get("healing", false)
	var consumes: bool = rule.get("consume", false) or rule.has("uses")
	var resource := _resource(data, item)
	var uses: int = resource.get("uses", rule.get("uses", 0))
	if consumes and uses < 1 and not (rule.get("gob", false) and input.get("new_fight", false)):
		return _error("No uses remain. Correct remaining uses on the item when the table agrees.")
	var target := _target(context, caller, input, source.actor.id, rule.range_feet)
	if target.has("error"):
		return _error(str(target.error))
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	if healing and (not recipient.ok or not _healable(recipient.actor.data)):
		return _error("Healing requires a living target with valid maximum HP.")
	var owner := PARTICIPANTS.new().owner(context, caller, source.actor.id)
	if owner.has("error"):
		return _error(str(owner.error))
	var action := {"id": str(input.id), "source": source.actor.id.value, "participant": str(caller.participant_id), "session": str(caller.session_id), "owner": str(owner.id), "owner_session": str(owner.session), "item": str(input.item), "kind": str(item.source_item_id), "target": target, "rook": str(input.get("rook", "")), "resource": str(resource.get("inventory_id", "")), "rule": rule, "adjustment": input.get("adjustment", 0), "request": str(input.id), "state": "pending", "message": "Throw healing in the Dice Tray."}
	var terms: Array[SDK.DiceTerm] = []
	if rule.get("poison", false) or rule.get("book", false) or rule.get("resistance", false):
		if rule.get("book", false) and str(target.actor) == source.actor.id.value:
			return _error("Choose an enemy to resist the Book.")
		var ability_name := str(rule.get("ability", "Toughness"))
		var recipient_data: Dictionary = recipient.actor.data
		if rule.get("book", false) and str(recipient_data.get("schema", "")) == "mork-borg-character/v1":
			ability_name = str(input.get("ability", ""))
			if not ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
				return _error("Choose the enemy Character's resistance ability with the table; the Book does not specify one.")
		var resisting := _resister(context, recipient.actor, ability_name)
		if resisting.has("error"):
			return _error(str(resisting.error))
		action["resistance_ability"] = ability_name
		action["resister"] = resisting
		action["resister_session"] = str(resisting.session)
		action["phase"] = "resistance"
		terms.append(SDK.DiceTerm.new("Resistance", 20))
		var request := context.request_throw(SDK.HumanThrowRequest.new(action.id, str(resisting.id), terms))
		return action if request.ok else _error(request.message)
	if rule.get("supply", false):
		var updated := data.duplicate(true)
		if not _consume(updated, action):
			return _error("No remaining supply. Correct the sheet when the table agrees.")
		var copy: String = {"dried-food": "Consumed one day of food.", "waterskin": "Drank one day of water.", "lard": "Consumed one meal.", "torch": "Burns; track light and expiry manually."}.get(str(action.kind), "")
		if str(action.kind) == "lantern-oil":
			var abilities: Dictionary = data.get("abilities", {})
			var presence: Dictionary = abilities.get("Presence", {})
			var modifier: int = presence.get("modifier", 0)
			copy = "Oil supplies %d hours of light; track expiry manually." % (modifier + 6)
		return _resolve(context, action, [SDK.ActorChange.new(source.actor.id, updated)], str(copy))
	if rule.get("blade", false):
		if not item.get("equipped", false):
			return _error("Wield the blade before checking its treachery.")
		action["phase"] = "treachery"
		terms = [SDK.DiceTerm.new("Blade treachery", 6)]
	elif rule.get("damage", false):
		var faces: int = rule.die
		var plan := DAMAGE.new().plan(recipient.actor, faces, str(action.kind) == "caltrops")
		if plan.has("error"):
			return _error(str(plan.error))
		action["damage_plan"] = plan
		terms = DAMAGE.new().terms(plan)
	elif rule.get("gob", false):
		action["phase"] = "allowance" if input.get("new_fight", false) else "spit"
		terms.append(SDK.DiceTerm.new("Spits this fight (d2)", 4) if input.get("new_fight", false) else SDK.DiceTerm.new("Spit accuracy", 20))
	elif rule.get("morale", false):
		var sign_value: Variant = input.get("presence_sign", 0)
		if typeof(sign_value) != TYPE_INT or not sign_value in [-1, 1]:
			return _error("Choose whether to add or subtract Presence, and confirm the eligible creature with the table.")
		var target_data: Dictionary = recipient.actor.data
		var morale: Variant = target_data.get("morale")
		if typeof(morale) != TYPE_INT:
			morale = input.get("morale")
		if typeof(morale) != TYPE_INT:
			return _error("Agree a numeric Morale with the table.")
		var morale_value: int = morale
		if morale_value < 2 or morale_value > 12:
			return _error("This creature has no numeric Morale. Agree a Morale from 2 to 12 with the table.")
		action["morale"] = morale_value
		action["presence_sign"] = sign_value
		terms = [SDK.DiceTerm.new("Morale", 6, 2)]
	elif rule.get("college", false):
		terms = [SDK.DiceTerm.new("Scrolls (d2)", 4), SDK.DiceTerm.new("Sacred or unclean", 4)]
	elif rule.get("brew", false):
		terms = [SDK.DiceTerm.new("Decoctions", 8, 2), SDK.DiceTerm.new("Shared doses", 4)]
	elif rule.get("manual", false):
		if not rule.has("die"):
			return _manual(context, action, [], 0)
		var faces: int = rule.die
		var count: int = rule.get("count", 1)
		terms.append(SDK.DiceTerm.new("Class parameters", faces, count))
	elif rule.has("ability"):
		terms.append(SDK.DiceTerm.new(str(rule.ability) + " test", 20))
	else:
		terms.append(SDK.DiceTerm.new("Wizard teeth", 6, 4) if teeth else SDK.DiceTerm.new("Healing", 6))
	var requested := context.request_throw(SDK.HumanThrowRequest.new(action.id, action.owner, terms))
	return action if requested.ok else _error(requested.message)

func _advance(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	var source := context.read_actor(SDK.ActorId.new(action.source))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var current: Dictionary = source.actor.data
	if not _valid(current) or RULES.new().owned(current, str(action.item)).is_empty():
		return _end(context, action)
	var roll := context.read_throw(str(action.request))
	if not roll.ok or roll.status == "cancelled":
		return _end(context, action)
	if roll.status == "pending":
		return _public(action)
	var rule: Dictionary = action.rule
	if rule.get("blade", false) or rule.get("damage", false):
		return _damage_item(context, action, roll, current)
	if rule.get("gob", false):
		return _gob(context, action, roll, current)
	if rule.get("morale", false):
		if not _target_current(context, action):
			return _end(context, action)
		var abilities: Dictionary = current.get("abilities", {})
		var presence: Dictionary = abilities.get("Presence", {})
		var modifier: int = presence.get("modifier", 0)
		var sign_value: int = action.presence_sign
		var total: int = roll.terms[0].results[0] + roll.terms[0].results[1] + modifier * sign_value
		var morale: int = action.morale
		var target: Dictionary = action.target
		return _resolve(context, action, [], "%s: Morale %d %+d = %d vs %d. %s Raw Roll #%d." % [str(target.label), roll.terms[0].results[0] + roll.terms[0].results[1], modifier * sign_value, total, morale, "Bows and kindly removes itself; move or remove its Rook manually." if total > morale else "Does not bow or leave.", roll.sequence])
	if rule.get("college", false):
		return _college(context, action, roll, current)
	if rule.get("brew", false):
		return _brew(context, action, roll, current)
	if rule.get("poison", false) or rule.get("book", false) or rule.get("resistance", false):
		return _poison(context, action, roll)
	if rule.get("manual", false):
		return _manual(context, action, roll.terms[0].results, roll.sequence)
	if rule.has("ability"):
		var item := RULES.new().owned(current, str(action.item))
		if item.is_empty() or not _target_current(context, action):
			return _end(context, action)
		var ability_data: Dictionary = current.get("abilities", {})
		var ability: Dictionary = ability_data.get(str(rule.ability), {})
		var modifier: int = ability.get("modifier", 0)
		var face: int = roll.terms[0].results[0]
		var printed: int = rule.dr
		var adjustment: int = action.get("adjustment", 0)
		var difficulty := _test_difficulty(current, str(rule.ability), printed) + adjustment
		var success := face + modifier >= difficulty
		var text := "%s: d20 %d %+d vs DR%d. %s Raw Roll #%d." % [str(item.get("name", action.kind)), face, modifier, difficulty, str(rule.success if success else rule.failure), roll.sequence]
		var changes: Array[SDK.ActorChange] = []
		if rule.has("uses") and (str(action.kind) != "stones-taken-from-thel-emas-lost-temple" or not success):
			var uses: int = item.get("uses", rule.uses)
			if uses < 1:
				return _end(context, action)
			var data := current.duplicate(true)
			var items := ITEMS.new(null, source.actor.id).inventory(data)
			for raw in items:
				var entry: Dictionary = raw
				if str(entry.inventory_id) == str(action.item):
					entry["uses"] = uses - 1
			data["inventory"] = items
			changes.append(SDK.ActorChange.new(source.actor.id, data))
			text += " One use spent."
		var report := SDK.ActionLogMessage.new("Class ability")
		report.text = [SDK.ActionLogText.new(text)]
		if not context.commit(changes, report).ok:
			return _end(context, action)
		action["state"] = "resolved"
		action["message"] = text
		return _public(action)
	if str(action.kind) == "wizard-teeth":
		var sixes := 0
		for face in roll.terms[0].results:
			if face == 6:
				sixes += 1
		var text := "Wizard teeth: %d attacks deal maximum damage. Apply and track these benefits manually. Raw Roll #%d." % [sixes, roll.sequence]
		var report := SDK.ActionLogMessage.new("Wizard teeth")
		report.text = [SDK.ActionLogText.new(text)]
		if not context.commit([], report).ok:
			return _end(context, action)
		action["state"] = "resolved"
		action["message"] = text
		return _public(action)
	var data := current.duplicate(true)
	var inventory := ITEMS.new(null, source.actor.id).inventory(data)
	data["inventory"] = inventory
	var item := RULES.new().owned(data, str(action.item))
	var resource := RULES.new().owned(data, str(action.resource))
	var uses: int = resource.get("uses", 0)
	if item.is_empty() or uses < 1 or not _target_current(context, action):
		return _end(context, action)
	var target: Dictionary = action.target
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	if not recipient.ok or not _healable(recipient.actor.data):
		return _end(context, action)
	var target_data: Dictionary = data if target.actor == action.source else recipient.actor.data.duplicate(true)
	var hp: int = target_data.hit_points
	var maximum: int = target_data.maximum_hit_points
	var amount := mini(roll.terms[0].results[0], maxi(0, maximum - hp))
	target_data["hit_points"] = hp + amount
	for raw in inventory:
		var entry: Dictionary = raw
		if str(entry.inventory_id) == str(action.resource):
			entry["uses"] = uses - 1
	var changes: Array[SDK.ActorChange] = [SDK.ActorChange.new(source.actor.id, data)]
	if target.actor != action.source:
		changes.append(SDK.ActorChange.new(recipient.actor.id, target_data))
	var text := "%s · %s: regained %d HP. One use spent. %s; update these narrative conditions at the table. Raw Roll #%d." % [str(item.get("name", "Elixir")), str(target.label), amount, "Stops bleeding and infection" if str(action.kind) == "medicine-box" else "Stops infection", roll.sequence]
	var report := SDK.ActionLogMessage.new("Use item")
	report.result = "Healing applied"
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit(changes, report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _valid(data: Dictionary) -> bool:
	if str(data.get("schema", "")) != "mork-borg-character/v1" or typeof(data.get("inventory")) != TYPE_ARRAY:
		return false
	for key in ["hit_points", "maximum_hit_points", "inventory_serial"]:
		if typeof(data.get(key, 0)) != TYPE_INT:
			return false
	if typeof(data.get("abilities", {})) != TYPE_DICTIONARY or typeof(data.get("traits", [])) != TYPE_ARRAY:
		return false
	var abilities: Dictionary = data.get("abilities", {})
	for key in ["Agility", "Presence", "Strength", "Toughness"]:
		if typeof(abilities.get(key, {})) != TYPE_DICTIONARY:
			return false
		var ability: Dictionary = abilities.get(key, {})
		if typeof(ability.get("modifier", 0)) != TYPE_INT:
			return false
	var traits: Array = data.get("traits", [])
	for raw in traits:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var feature: Dictionary = raw
		if typeof(feature.get("id", "")) != TYPE_STRING or typeof(feature.get("uses", 0)) != TYPE_INT:
			return false
	var items: Array = data.inventory
	for raw in items:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = raw
		for key in ["uses", "quantity"]:
			if typeof(item.get(key, 0)) != TYPE_INT:
				return false
		for key in ["equipped", "broken"]:
			if typeof(item.get(key, false)) != TYPE_BOOL:
				return false
		for key in ["inventory_id", "source_item_id", "name", "dose_pool"]:
			if typeof(item.get(key, "")) != TYPE_STRING:
				return false
	return true

func _end(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	action["state"] = "ended"
	action["message"] = ENDED
	context.cancel_throw(str(action.get("request", "")))
	_record(context, [], ENDED)
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	return {"state": action.state, "message": action.message, "request": action.get("request", ""), "count": action.get("count", 0), "family": action.get("family", "")}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _resource(data: Dictionary, item: Dictionary) -> Dictionary:
	if not item.has("dose_pool"):
		return item
	for raw in ITEMS.new(null, SDK.ActorId.new("")).inventory(data):
		var entry: Dictionary = raw
		var quantity: int = entry.get("quantity", 0)
		if str(entry.get("source_item_id", "")) == str(item.dose_pool) and quantity > 0:
			return entry
	return {}

func _healable(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = value
	if typeof(data.get("hit_points")) != TYPE_INT or typeof(data.get("maximum_hit_points")) != TYPE_INT:
		return false
	var hp: int = data.hit_points
	var maximum: int = data.maximum_hit_points
	return hp >= 0 and maximum > 0

func _target(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary, source: SDK.ActorId, reach: int = 5) -> Dictionary:
	if reach == 0 or input.get("self", false):
		return {"actor": source.value, "rook": "", "label": "Self"}
	var rook_id := SDK.RookId.new(str(input.get("rook", "")))
	var rook := context.read_rook(rook_id)
	if not rook.ok or rook.rook.actor == null or rook.rook.actor.value != source.value or rook.rook.scene.value != "main":
		return {"error": "Select this Character's source Rook."}
	var ids: PackedStringArray = caller.targets
	var outside := ""
	var selected: Dictionary = {}
	var target_count := 0
	for id in ids:
		target_count += 1
		var other := context.read_rook(SDK.RookId.new(id))
		if not other.ok or other.rook.actor == null:
			return {"error": "Choose a Character or Creature recipient."}
		var actor := context.read_actor(other.rook.actor)
		if not actor.ok or typeof(actor.actor.data) != TYPE_DICTIONARY:
			return {"error": "Recipient data is unavailable."}
		var data: Dictionary = actor.actor.data
		if not str(data.get("schema", "")) in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
			return {"error": "Choose a Character or Creature recipient."}
		var label := actor.actor.public_label if not actor.actor.public_label.is_empty() else "Creature"
		var distance := context.distance(rook_id, SDK.RookId.new(id))
		if not distance.ok:
			return {"error": distance.message}
		if distance.distance > float(reach) * 0.3048 + 0.000001:
			outside += ("\n" if not outside.is_empty() else "") + "target %s not in range" % label
		selected = {"actor": actor.actor.id.value, "rook": id, "label": label}
	if not outside.is_empty():
		var report := SDK.ActionLogMessage.new("Item out of range")
		report.text = [SDK.ActionLogText.new(outside)]
		context.commit([], report)
		return {"error": outside}
	if target_count != 1:
		return {"error": "Choose exactly one recipient within %d ft, or choose Self." % reach}
	return selected

func _target_current(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	var target: Dictionary = action.target
	if str(target.rook).is_empty():
		return true
	var ids: PackedStringArray = [str(target.rook)]
	var rule: Dictionary = action.rule
	var reach: int = rule.range_feet
	var selected := _target(context, {"targets": ids}, {"rook": action.rook}, SDK.ActorId.new(str(action.source)), reach)
	return not selected.has("error") and selected.actor == target.actor

func _consume(data: Dictionary, action: Dictionary) -> bool:
	var rule: Dictionary = action.rule
	var item := RULES.new().owned(data, str(action.item))
	if item.is_empty():
		return false
	if rule.get("quantity_use", false):
		var items := ITEMS.new(null, SDK.ActorId.new("")).inventory(data)
		for raw in items:
			var entry: Dictionary = raw
			if str(entry.inventory_id) == str(action.item):
				var quantity: int = entry.quantity
				if quantity < 1:
					return false
				entry["quantity"] = quantity - 1
				data["inventory"] = items
				return true
		return false
	if not rule.get("consume", false) and not rule.has("uses"):
		return true
	var resource := _resource(data, item)
	var uses: int = resource.get("uses", rule.get("uses", 0))
	if uses < 1:
		return false
	var items := ITEMS.new(null, SDK.ActorId.new("")).inventory(data)
	for raw in items:
		var entry: Dictionary = raw
		if str(entry.inventory_id) == str(resource.get("inventory_id", "")):
			entry["uses"] = uses - 1
			data["inventory"] = items
			return true
	if str(action.item).begins_with("feature:"):
		var traits: Array = data.get("traits", [])
		for raw in traits:
			var feature: Dictionary = raw
			if "feature:" + str(feature.get("id", "")) == str(action.item):
				feature["uses"] = uses - 1
				return true
	return false

func _manual(context: SDK.SystemActionContext, action: Dictionary, values: Array[int], sequence: int) -> Dictionary:
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok or source.actor.access_level != "Owner" or not _target_current(context, action):
		return _end(context, action)
	var current: Dictionary = source.actor.data
	var data := current.duplicate(true)
	if not action.get("resource_spent", false) and not _consume(data, action):
		return _end(context, action)
	var rule: Dictionary = action.rule
	var text := str(rule.text)
	if str(action.kind) == "blasphemous-nechrubel-bible":
		if str(action.get("phase", "")) == "hallucinations":
			text = "The GM invents %d hallucinations only the Priest sees until sunrise (physical d6 halved, rounded up). Handle them manually." % int((values[0] + 1) / 2)
		elif values[0] % 2 == 0:
			text = "Even: PCs heal d4 HP after five minutes of rest for the rest of the day. Establish rests and resolve that later healing manually."
		else:
			if not _record(context, [SDK.ActorChange.new(source.actor.id, data)], "Bible: odd result; one daily use spent. Raw Roll #%d." % sequence):
				return _end(context, action)
			action["resource_spent"] = true
			action["phase"] = "hallucinations"
			action["request"] = context.new_request_id()
			action["message"] = "Odd: throw d3 hallucinations (physical d6 halved, rounded up)."
			var requested := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), str(action.owner), [SDK.DiceTerm.new("Hallucinations (d3)", 6)]))
			return _public(action) if requested.ok else _end(context, action)
	elif str(action.kind) == "dodging-death":
		text = "Survived: after 10 rounds return with %d HP and an unlikely explanation. Apply that delayed recovery manually." % values[1] if values[0] <= 2 else "Did not escape death. No HP change."
		text += " Survival chance uses physical d4: 1–2 succeeds."
	elif rule.has("die"):
		text = text % values[0]
	text += " One use spent." if not action.get("resource_spent", false) and (rule.get("consume", false) or rule.has("uses")) else ""
	if sequence > 0:
		text += " Raw Roll #%d." % sequence
	var report := SDK.ActionLogMessage.new("Use item")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit([SDK.ActorChange.new(source.actor.id, data)], report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _resister(context: SDK.SystemActionContext, actor: SDK.Actor, ability_name: String = "Toughness") -> Dictionary:
	var data: Dictionary = actor.data
	var character := str(data.get("schema", "")) == "mork-borg-character/v1"
	var modifier := 0
	if character:
		if typeof(data.get("abilities", {})) != TYPE_DICTIONARY:
			return {"error": "Recipient ability data is malformed."}
		var abilities: Dictionary = data.get("abilities", {})
		if typeof(abilities.get(ability_name, {})) != TYPE_DICTIONARY:
			return {"error": "Recipient ability data is malformed."}
		var ability: Dictionary = abilities.get(ability_name, {})
		if typeof(ability.get("modifier", 0)) != TYPE_INT:
			return {"error": "Recipient ability data is malformed."}
		modifier = ability.get("modifier", 0)
		var caller := context.caller()
		var info: Dictionary = caller.value
		if actor.access_level == "Owner" and not info.is_gm:
			return {"id": str(info.participant_id), "session": str(info.session_id), "modifier": modifier}
		var access := context.actor_access(actor.id)
		if not access.ok:
			return {"error": access.message}
		var owner: Dictionary = {}
		for entry in access.items:
			if entry.access_level != "Owner":
				continue
			if not owner.is_empty():
				return {"error": "Several Players own this recipient. Agree one responsible Owner before starting."}
			if not entry.is_connected:
				return {"error": "The recipient's Player is not connected."}
			owner = {"id": entry.participant_id, "session": entry.session_id, "modifier": modifier}
		if not owner.is_empty():
			return owner
	var sessions := context.participant_sessions()
	if not sessions.ok:
		return {"error": sessions.message}
	var participants: Array = sessions.value
	for raw in participants:
		var participant: Dictionary = raw
		if participant.is_gm:
			return {"id": str(participant.participant_id), "session": str(participant.session_id), "modifier": modifier}
	return {"error": "The GM must be connected to resolve this target's test."}

func _poison(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	if str(action.get("phase", "")) == "duration":
		var rule: Dictionary = action.rule
		var copy := str(rule.text)
		if str(action.kind) == "southern-frog-stew" and action.get("resisted", false):
			copy = "Vomit for %d hours, but can still act. Handle vomiting manually."
		return _resolve(context, action, [], copy % roll.terms[0].results[0] + " Raw Roll #%d." % roll.sequence)
	if str(action.get("phase", "")) == "book-summons":
		return _book_summons(context, action, roll)
	if not _target_current(context, action):
		return _end(context, action)
	var target: Dictionary = action.target
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	if not recipient.ok or typeof(recipient.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var current: Dictionary = recipient.actor.data
	var now_resisting := _resister(context, recipient.actor, str(action.get("resistance_ability", "Toughness")))
	var original: Dictionary = action.resister
	if now_resisting.has("error") or now_resisting.id != original.id or now_resisting.session != original.session:
		return _end(context, action)
	if typeof(current.get("hit_points")) != TYPE_INT:
		return _end(context, action)
	var rule: Dictionary = action.rule
	var description := str(target.label) + ": "
	var changes: Array[SDK.ActorChange] = []
	if str(action.phase) == "resistance":
		var source := context.read_actor(SDK.ActorId.new(str(action.source)))
		var source_data: Dictionary = source.actor.data
		var spent := source_data.duplicate(true)
		if not _consume(spent, action):
			return _end(context, action)
		changes.append(SDK.ActorChange.new(source.actor.id, spent))
		var face: int = roll.terms[0].results[0]
		var resister: Dictionary = action.resister
		var modifier: int = now_resisting.modifier
		var printed: int = rule.dr
		var adjustment: int = action.get("adjustment", 0)
		var difficulty := _test_difficulty(current, str(action.get("resistance_ability", "Toughness")), printed) + adjustment
		var passed := face + modifier >= difficulty
		description += "resisted" if passed else "failed resistance"
		description += " (DR%d). One use spent. Raw Roll #%d." % [difficulty, roll.sequence]
		if not passed or str(action.kind) == "southern-frog-stew":
			action["resisted"] = passed
			var report := SDK.ActionLogMessage.new("Book opened" if rule.get("book", false) else "Poison applied")
			report.text = [SDK.ActionLogText.new(description)]
			if not context.commit(changes, report).ok:
				return _end(context, action)
			action["phase"] = "book-summons" if rule.get("book", false) else "duration" if rule.get("resistance", false) else "poison-hp"
			action["request"] = context.new_request_id()
			action["message"] = "Resistance failed. Throw the prescribed HP loss."
			var terms: Array[SDK.DiceTerm] = []
			if rule.get("book", false):
				terms = [SDK.DiceTerm.new("Berserker-slayers (d2)", 4), SDK.DiceTerm.new("Disposition", 6)]
				action["message"] = "Throw summoned count and disposition. d2 uses physical d4 halved, rounded up."
			else:
				var faces: int = rule.die
				terms.append(SDK.DiceTerm.new("Duration (hours)" if rule.get("resistance", false) else "Poison HP loss", faces))
			var requested := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), str(action.owner) if rule.get("book", false) else str(resister.id), terms))
			return _public(action) if requested.ok else _end(context, action)
	else:
		var data := current.duplicate(true)
		var hp: int = data.hit_points
		var loss: int = roll.terms[0].results[0]
		data["hit_points"] = hp - loss
		changes.append(SDK.ActorChange.new(recipient.actor.id, data))
		description += "lost %d HP. %s Raw Roll #%d." % [loss, str(rule.text), roll.sequence]
	var report := SDK.ActionLogMessage.new("Book resisted" if rule.get("book", false) else "Poison outcome")
	report.text = [SDK.ActionLogText.new(description)]
	if not context.commit(changes, report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = description
	return _public(action)

func _book_summons(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var count := int((roll.terms[0].results[0] + 1) / 2)
	var friendly: bool = roll.terms[1].results[0] <= 4
	var requests: Array = []
	for index in range(count):
		requests.append({"package_id": "0404eb56-ef27-4b1a-8385-27e4e3ec907e", "local_id": "zukuma-berserker", "choices": {"name": "Berserker-slayer %d" % (index + 1), "summoner_actor": str(action.source), "summon_action": str(action.id), "grant_source": "Book of boiling blood"}})
	var text := "Book of boiling blood: %d Berserker-slayers appear. %s They return to imprisonment after battle; resolve disposition and departure manually. Place each Rook from Companions. Count uses physical d4 halved, rounded up. Raw Roll #%d." % [count, "They fight alongside you." if friendly else "They turn on you, trying to kill you and destroy the Book.", roll.sequence]
	var report := SDK.ActionLogMessage.new("Book of boiling blood")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.create_actors(requests, str(action.owner), report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _brew(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult, current: Dictionary) -> Dictionary:
	if RULES.new().owned(current, str(action.item)).is_empty():
		return _end(context, action)
	var data := current.duplicate(true)
	var items := ITEMS.new(null, SDK.ActorId.new(str(action.source))).inventory(data)
	var kept: Array = []
	var serial: int = data.get("inventory_serial", 0)
	for raw in items:
		var item: Dictionary = raw
		var id_text: String = item.inventory_id
		var id := int(id_text)
		if id > serial:
			serial = id
		if str(item.inventory_id) == str(action.item):
			item["uses"] = roll.terms[1].results[0]
		if not item.has("dose_pool"):
			kept.append(item)
	var traits: Array = []
	var prior_traits: Array = data.get("traits", [])
	for raw in prior_traits:
		var feature: Dictionary = raw
		var item: Dictionary = feature.get("item", {})
		if not item.has("dose_pool"):
			traits.append(feature)
	var names := ""
	for face in roll.terms[0].results:
		var feature := CLASSES.new().decoction(face)
		traits.append(feature)
		var original: Dictionary = feature.item
		var item := original.duplicate(true)
		serial += 1
		item["inventory_id"] = str(serial)
		item["quantity"] = 1
		item["rules"] = str(feature.rules)
		kept.append(item)
		names += (", " if not names.is_empty() else "") + str(feature.name)
	data["inventory"] = kept
	data["inventory_serial"] = serial
	data["traits"] = traits
	var text := "Brewed %s; %d shared doses. Unused decoctions lose vitality after 24 hours; establish daily eligibility and track expiry manually. Raw Roll #%d." % [names, roll.terms[1].results[0], roll.sequence]
	var report := SDK.ActionLogMessage.new("Daily decoctions")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit([SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _college(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult, current: Dictionary) -> Dictionary:
	var data := current.duplicate(true)
	if not _consume(data, action):
		return _end(context, action)
	var count := int((roll.terms[0].results[0] + 1) / 2)
	var family := "sacred" if roll.terms[1].results[0] <= 2 else "unclean"
	var text := "Invisible College: %d %s scrolls, each usable once. The source does not select their identities; choose them with the table. Unused scrolls turn to ash at sunrise; track expiry manually. One daily use spent. Raw Roll #%d." % [count, family, roll.sequence]
	var report := SDK.ActionLogMessage.new("Invisible College")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit([SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], report).ok:
		return _end(context, action)
	action["count"] = count
	action["family"] = family
	action["state"] = "scrolls"
	action["message"] = text
	return _public(action)

func _choose_scrolls(context: SDK.SystemActionContext, action: Dictionary, input: Dictionary) -> Dictionary:
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok or source.actor.access_level != "Owner" or not _valid(source.actor.data):
		return _end(context, action)
	if typeof(input.get("scrolls")) != TYPE_ARRAY:
		return _public(action)
	var selected: Array = input.scrolls
	var count: int = action.count
	if selected.size() != count:
		return _public(action)
	var options: Array = SCROLLS.TABLES.get(str(action.family), [])
	var additions: Array = []
	for id in selected:
		var found := false
		for raw in options:
			var scroll: Dictionary = raw
			if str(scroll.source_item_id) == str(id):
				additions.append(scroll.duplicate(true))
				found = true
		if not found:
			action["message"] = "Choose %d %s scrolls with the table." % [count, str(action.family)]
			return _public(action)
	var current: Dictionary = source.actor.data
	var data := current.duplicate(true)
	var items := ITEMS.new(null, source.actor.id).inventory(data)
	var serial: int = data.get("inventory_serial", 0)
	for raw in items:
		var item: Dictionary = raw
		var id_text: String = item.inventory_id
		var number := int(id_text)
		if number > serial:
			serial = number
	for raw in additions:
		var item: Dictionary = raw
		serial += 1
		item["inventory_id"] = str(serial)
		item["quantity"] = 1
		item["single_use"] = true
		items.append(item)
	data["inventory"] = items
	data["inventory_serial"] = serial
	var text := "%d single-use scrolls added to Inventory. Unused scrolls become ash at sunrise; remove them manually when the table agrees." % count
	var report := SDK.ActionLogMessage.new("Scrolls summoned")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit([SDK.ActorChange.new(source.actor.id, data)], report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _resolve(context: SDK.SystemActionContext, action: Dictionary, changes: Array[SDK.ActorChange], text: String) -> Dictionary:
	var report := SDK.ActionLogMessage.new("Use item")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit(changes, report).ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = text
	return _public(action)

func _next_throw(context: SDK.SystemActionContext, action: Dictionary, phase: String, owner: String, terms: Array[SDK.DiceTerm], message: String) -> Dictionary:
	action["phase"] = phase
	action["state"] = "pending"
	action["request"] = context.new_request_id()
	action["message"] = message
	var requested := context.request_throw(SDK.HumanThrowRequest.new(str(action.request), owner, terms))
	return _public(action) if requested.ok else _end(context, action)

func _record(context: SDK.SystemActionContext, changes: Array[SDK.ActorChange], text: String) -> bool:
	var report := SDK.ActionLogMessage.new("Class ability")
	report.text = [SDK.ActionLogText.new(text)]
	return context.commit(changes, report).ok

func _gob(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult, current: Dictionary) -> Dictionary:
	var phase := str(action.phase)
	if phase == "allowance":
		var count := int((roll.terms[0].results[0] + 1) / 2)
		var data := current.duplicate(true)
		var traits: Array = data.get("traits", [])
		for raw in traits:
			var feature: Dictionary = raw
			if str(feature.get("id", "")) == str(action.kind):
				feature["uses"] = count
		if not _record(context, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], "%d spits available this fight (physical d4 halved, rounded up). Raw Roll #%d." % [count, roll.sequence]):
			return _end(context, action)
		return _next_throw(context, action, "spit", str(action.owner), [SDK.DiceTerm.new("Spit accuracy", 20)], "Throw Presence DR8 for accuracy.")
	if phase == "spit":
		if not _target_current(context, action):
			return _end(context, action)
		var data := current.duplicate(true)
		if not _consume(data, action):
			return _end(context, action)
		var abilities: Dictionary = data.get("abilities", {})
		var presence: Dictionary = abilities.get("Presence", {})
		var modifier: int = presence.get("modifier", 0)
		var face: int = roll.terms[0].results[0]
		var success := face + modifier >= 8
		var text := "Gob Lobber: d20 %d %+d vs DR8. %s One spit spent. Raw Roll #%d." % [face, modifier, "Hit." if success else "Miss.", roll.sequence]
		if not _record(context, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], text):
			return _end(context, action)
		if success:
			return _next_throw(context, action, "gob-duration", str(action.owner), [SDK.DiceTerm.new("Blind and vomiting (rounds)", 4)], "Throw d4 rounds; ongoing consequences are manual.")
		action["state"] = "witnesses"
		action["message"] = text + " Select all witnesses, friend and foe, then confirm. The table determines who witnessed this."
		return _public(action)
	if phase == "gob-duration":
		var target: Dictionary = action.target
		var text := "%s: blinded, retching and vomiting for %d rounds. Handle these consequences manually. Raw Roll #%d." % [str(target.label), roll.terms[0].results[0], roll.sequence]
		if not _record(context, [], text):
			return _end(context, action)
		action["state"] = "witnesses"
		action["message"] = text + " Select all witnesses, friend and foe, then confirm."
		return _public(action)
	if phase == "witness":
		var witnesses: Array = action.witnesses
		var index: int = action.witness_index
		var witness: Dictionary = witnesses[index]
		var actor := context.read_actor(SDK.ActorId.new(str(witness.actor)))
		if not actor.ok or typeof(actor.actor.data) != TYPE_DICTIONARY:
			return _end(context, action)
		var resister := _resister(context, actor.actor)
		if resister.has("error") or resister.id != witness.owner or resister.session != witness.session:
			return _end(context, action)
		var modifier: int = resister.modifier
		var dr: int = witness.dr
		var face: int = roll.terms[0].results[0]
		var text := "%s: Toughness d20 %d %+d vs DR%d. %s Raw Roll #%d." % [str(witness.label), face, modifier, dr, "Does not vomit." if face + modifier >= dr else "Also vomits; handle the consequence manually.", roll.sequence]
		if not _record(context, [], text):
			return _end(context, action)
		action["witness_index"] = index + 1
		return _next_witness(context, action)
	return _end(context, action)

func _witnesses(context: SDK.SystemActionContext, action: Dictionary, caller: Dictionary, input: Dictionary) -> Dictionary:
	if input.get("confirmed") != true:
		return _public(action)
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok or source.actor.access_level != "Owner":
		return _end(context, action)
	var ids: PackedStringArray = caller.targets
	var seen: Array[String] = []
	var witnesses: Array = []
	for id in ids:
		var rook := context.read_rook(SDK.RookId.new(id))
		if not rook.ok or rook.rook.actor == null:
			action["message"] = "Select only Character or Creature witnesses."
			return _public(action)
		var actor := context.read_actor(rook.rook.actor)
		if not actor.ok or typeof(actor.actor.data) != TYPE_DICTIONARY:
			return _end(context, action)
		var schema := str(actor.actor.data.get("schema", ""))
		if not schema in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
			action["message"] = "Select only Character or Creature witnesses."
			return _public(action)
		if actor.actor.id.value in seen:
			continue
		seen.append(actor.actor.id.value)
		var resister := _resister(context, actor.actor)
		if resister.has("error"):
			action["message"] = str(resister.error)
			return _public(action)
		witnesses.append({"actor": actor.actor.id.value, "label": actor.actor.public_label if not actor.actor.public_label.is_empty() else "Character", "owner": resister.id, "session": resister.session, "dr": 10 if schema == "mork-borg-character/v1" else 12})
	action["witnesses"] = witnesses
	action["witness_index"] = 0
	return _next_witness(context, action)

func _next_witness(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	var witnesses: Array = action.witnesses
	var index: int = action.witness_index
	if index >= witnesses.size():
		return _resolve(context, action, [], "Gob Lobber resolved. All confirmed witnesses tested; ongoing blindness and vomiting remain manual.")
	var witness: Dictionary = witnesses[index]
	action["resister_session"] = str(witness.session)
	var difficulty: int = witness.dr
	return _next_throw(context, action, "witness", str(witness.owner), [SDK.DiceTerm.new("Witness Toughness", 20)], "%s: throw Toughness DR%d." % [str(witness.label), difficulty])

func _damage_item(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult, current: Dictionary) -> Dictionary:
	if not _target_current(context, action):
		return _end(context, action)
	var target: Dictionary = action.target
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	if not recipient.ok or typeof(recipient.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var rule: Dictionary = action.rule
	var phase := str(action.get("phase", ""))
	if phase == "treachery":
		var face: int = roll.terms[0].results[0]
		if face != 1:
			return _resolve(context, action, [], "Blade treachery: d6 %d. The blade does not attack an ally. Raw Roll #%d." % [face, roll.sequence])
		if not _record(context, [], "Blade treachery: d6 1. It attacks the table-chosen victim. Raw Roll #%d." % roll.sequence):
			return _end(context, action)
		return _next_throw(context, action, "blade-attack", str(action.owner), [SDK.DiceTerm.new("Blade attack", 20)], "The blade attacks its chosen victim: Strength DR10.")
	if phase == "blade-attack":
		var abilities: Dictionary = current.get("abilities", {})
		var strength: Dictionary = abilities.get("Strength", {})
		var modifier: int = strength.get("modifier", 0)
		var face: int = roll.terms[0].results[0]
		if face == 1:
			var data := current.duplicate(true)
			var items := ITEMS.new(null, SDK.ActorId.new(str(action.source))).inventory(data)
			for raw in items:
				var item: Dictionary = raw
				if str(item.inventory_id) == str(action.item):
					item["broken"] = true
					item["equipped"] = false
			data["inventory"] = items
			return _resolve(context, action, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), data)], "The treacherous blade fumbles and breaks. Raw Roll #%d." % roll.sequence)
		if face != 20 and face + modifier < 10:
			return _resolve(context, action, [], "The treacherous blade misses. Raw Roll #%d." % roll.sequence)
		var plan := DAMAGE.new().plan(recipient.actor, 6, false)
		if plan.has("error"):
			return _end(context, action)
		plan["bonus"] = 1
		plan["critical"] = face == 20
		action["damage_plan"] = plan
		return _next_throw(context, action, "blade-damage", str(action.owner), DAMAGE.new().terms(plan), "Throw d6+1 damage and protection.")
	var plan: Dictionary = action.damage_plan
	var outcome := DAMAGE.new().apply(recipient.actor, plan, roll)
	if outcome.has("error"):
		return _end(context, action)
	if not str(plan.get("shield_id", "")).is_empty():
		var owner := _resister(context, recipient.actor)
		if owner.has("error"):
			return _end(context, action)
		if rule.get("quantity_use", false):
			var spent := current.duplicate(true)
			if not _consume(spent, action) or not _record(context, [SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), spent)], "One item consumed after accepted damage. Raw Roll #%d." % roll.sequence):
				return _end(context, action)
			action["resource_spent"] = true
		action["shield_owner"] = owner
		action["resister_session"] = str(owner.session)
		action["loss"] = outcome.loss
		action["damage_sequence"] = roll.sequence
		action["damage_text"] = str(outcome.text)
		action["state"] = "shield"
		action["message"] = "Waiting for the recipient's shield decision."
		var caller := context.caller()
		var info: Dictionary = caller.value
		return _shield_public(context, action) if str(info.participant_id) == str(owner.id) else {"state": "pending", "message": action.message}
	var source_data: Dictionary = outcome.data if str(target.actor) == str(action.source) else current.duplicate(true)
	if not _consume(source_data, action):
		return _end(context, action)
	var changes: Array[SDK.ActorChange] = []
	if str(target.actor) == str(action.source):
		var damaged: Dictionary = outcome.data
		source_data["hit_points"] = damaged.hit_points
		changes.append(SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), source_data))
	else:
		changes.append(SDK.ActorChange.new(SDK.ActorId.new(str(action.source)), source_data))
		changes.append(SDK.ActorChange.new(recipient.actor.id, outcome.data))
	var text := "%s: %s damage after protection. %s Raw Roll #%d." % [str(target.label), str(outcome.loss), str(outcome.text), roll.sequence]
	if rule.get("quantity_use", false):
		text += " One item consumed."
	return _resolve(context, action, changes, text)

func _find(id: String) -> Dictionary:
	for action in _actions:
		if str(action.id) == id:
			return action
	return {}

func shield_inbox(context: SDK.SystemActionContext) -> Array:
	var caller := context.caller()
	if not caller.ok:
		return []
	var info: Dictionary = caller.value
	var inbox: Array = []
	for action in _actions:
		if str(action.state) != "shield":
			continue
		var owner: Dictionary = action.get("shield_owner", {})
		if str(owner.get("id", "")) != str(info.participant_id) or str(owner.get("session", "")) != str(info.session_id):
			continue
		if not _current(context, action):
			_end(context, action)
			continue
		inbox.append(_shield_public(context, action))
	return inbox

func _shield_public(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	if not _current(context, action):
		return _end(context, action)
	var target: Dictionary = action.target
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	if not recipient.ok:
		return _end(context, action)
	var owner := _resister(context, recipient.actor)
	var original: Dictionary = action.shield_owner
	if owner.has("error") or owner.id != original.id or owner.session != original.session:
		return _end(context, action)
	var plan: Dictionary = action.damage_plan
	if not DAMAGE.new().protection_current(recipient.actor, plan):
		return _end(context, action)
	var data: Dictionary = recipient.actor.data
	return {"operation": "special", "id": action.id, "initiator": action.participant, "defender": owner.id, "state": "shield", "target": str(target.actor), "character": str(target.label), "hp": data.get("hit_points", 0), "loss": action.loss, "message": action.message}

func _choose_shield(context: SDK.SystemActionContext, action: Dictionary, input: Dictionary) -> Dictionary:
	if typeof(input.get("choice")) != TYPE_STRING or not str(input.choice) in ["take", "break"]:
		return _shield_public(context, action)
	var current_offer := _shield_public(context, action)
	if str(current_offer.state) != "shield":
		return current_offer
	var target: Dictionary = action.target
	var recipient := context.read_actor(SDK.ActorId.new(str(target.actor)))
	var current: Dictionary = recipient.actor.data
	var data := current.duplicate(true)
	var plan: Dictionary = action.damage_plan
	var items := ITEMS.new(null, recipient.actor.id).inventory(data)
	var available := false
	for raw in items:
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.inventory_id) == str(plan.shield_id) and item.get("equipped", false) and not item.get("broken", false) and quantity > 0:
			available = true
			if str(input.choice) == "break":
				item["broken"] = true
				item["equipped"] = false
	if not available:
		return _end(context, action)
	data["inventory"] = items
	var loss: int = action.loss
	var hp: int = data.hit_points
	if str(input.choice) == "take":
		data["hit_points"] = hp - loss
	if plan.get("critical", false):
		DAMAGE.new().damage_armor(recipient.actor.id, data)
	var sequence: int = action.damage_sequence
	return _resolve(context, action, [SDK.ActorChange.new(recipient.actor.id, data)], "%s: %s Raw Roll #%d." % [str(target.label), "Shield broken; no damage taken." if str(input.choice) == "break" else "Takes %d damage after shield protection. %s" % [loss, str(action.get("damage_text", ""))], sequence])

func _current(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	if not PARTICIPANTS.new().alive(context, action):
		return false
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok or not _valid(source.actor.data):
		return false
	var data: Dictionary = source.actor.data
	var item := RULES.new().owned(data, str(action.item))
	var rule: Dictionary = action.rule
	if item.is_empty() and action.get("resource_spent", false) and rule.get("quantity_use", false):
		for raw in ITEMS.new(null, source.actor.id).inventory(data):
			var entry: Dictionary = raw
			if str(entry.inventory_id) == str(action.item) and str(entry.get("source_item_id", "")) == str(action.kind):
				item = entry
	if item.is_empty():
		return false
	if (rule.get("blade", false) or str(action.kind) == "stolen-mitre") and not item.get("equipped", false):
		return false
	return _target_current(context, action)

func _test_difficulty(data: Dictionary, ability: String, printed: int) -> int:
	if ability != "Agility":
		return printed
	var penalty := 0
	for raw in ITEMS.new(null, SDK.ActorId.new("")).inventory(data):
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("kind", "")) != "Armor" or not item.get("equipped", false) or quantity < 1:
			continue
		var tier: int = item.get("penalty_tier", item.get("armor_tier", 0))
		if tier == 2 and penalty < 2:
			penalty = 2
		elif tier >= 3:
			penalty = 4
	return printed + penalty
