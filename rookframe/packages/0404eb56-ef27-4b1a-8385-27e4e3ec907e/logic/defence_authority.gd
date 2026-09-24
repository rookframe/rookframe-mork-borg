extends RefCounted

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const TARGETING = preload(ROOT + "logic/attack_targeting.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Array[Dictionary] = []

func handle(context: SDK.SystemActionContext, operation: String, payload: Variant) -> Variant:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("The defence action is malformed.")
	var input: Dictionary = payload
	var requester := context.caller()
	if not requester.ok:
		return _error(requester.message)
	var caller: Dictionary = requester.value
	if operation == "defence.inbox":
		var inbox: Array = []
		for action in _actions:
			if action.owner == caller.participant_id and action.owner_session == caller.session_id and str(action.state) in ["ready", "pending", "shield"]:
				if not _alive(context, action):
					_end(context, action)
				inbox.append(_public(action))
		return inbox
	if typeof(input.get("id")) != TYPE_STRING or str(input.id).is_empty() or str(input.id).length() > 64:
		return _error("Choose a new defence action identity.")
	var id: String = input.id
	var action := _find(id)
	if operation == "defence.start" and action.is_empty():
		return _start(context, caller, input)
	if action.is_empty():
		return {"state": "ended", "message": ENDED}
	var defender: bool = action.owner == caller.participant_id and action.owner_session == caller.session_id
	var initiator: bool = action.participant == caller.participant_id and action.session == caller.session_id
	if not defender and not initiator:
		return _error("This action belongs to another Participant session.")
	if str(action.state) in ["resolved", "ended", "error"]:
		return _public(action)
	if not _alive(context, action):
		return _end(context, action)
	if operation == "defence.cancel":
		return _end(context, action)
	if operation == "defence.choose" and action.state == "shield":
		if not defender or typeof(input.get("choice")) != TYPE_STRING or not str(input.choice) in ["take", "break"]:
			return _error("The defending Player chooses Take damage or Break shield.")
		return _apply_damage(context, action, str(input.choice) == "break")
	if operation == "defence.roll":
		if not defender:
			return _error("The defending Player chooses and rolls their defence.")
		if action.state == "ready":
			if typeof(input.get("difficulty", 0)) != TYPE_INT or typeof(input.get("modifier", 0)) != TYPE_INT:
				return _retry(action, "Enter whole numbers for difficulty and modifier.")
			var override_dr: int = input.get("difficulty", 0)
			var modifier: int = input.get("modifier", 0)
			if override_dr < 0 or override_dr > 30 or modifier < -20 or modifier > 20:
				return _retry(action, "Choose source difficulty (0) or 1–30, and a modifier from −20 to +20.")
			if override_dr > 0:
				action["difficulty"] = override_dr
			action["modifier"] = modifier
			if action.automatic_hit:
				return _request_damage(context, action)
			var requested := context.request_throw(SDK.HumanThrowRequest.new(id, action.owner, [SDK.DiceTerm.new("Defence", 20)]))
			if not requested.ok:
				return _end(context, action)
			action["state"] = "pending"
			action["request"] = id
			action["message"] = "Waiting for the defence Throw in the Dice Tray."
	if operation == "defence.advance" and action.state == "pending":
		var result := context.read_throw(action.request)
		if not result.ok or result.status == "cancelled":
			return _end(context, action)
		if result.ok and result.status == "rolled":
			if action.phase == "damage":
				return _damage_rolled(context, action, result)
			var raw: int = result.terms[0].results[0]
			var modifier: int = action.modifier
			var agility: int = action.agility
			agility += modifier
			var difficulty: int = action.difficulty
			if raw != 1 and (raw == 20 or raw + agility >= difficulty):
				var report := SDK.ActionLogMessage.new("Defence")
				report.result = "Free attack" if raw == 20 else "Defended"
				var text := "%s defends against %s. d20 %d %+d. Raw Roll #%d." % [str(action.character), str(action.attacker), raw, agility, result.sequence]
				if raw == 20:
					text += " Natural 20: gain a free attack. Choose an equipped weapon in Inventory."
				report.text = [SDK.ActionLogText.new(text)]
				var saved := context.commit([], report)
				if not saved.ok:
					return _end(context, action)
				action["state"] = "resolved"
				action["message"] = ""
			else:
				action["raw"] = raw
				action["sequence"] = result.sequence
				return _request_damage(context, action)
	return _public(action)

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	if not caller.is_gm:
		return _error("The GM starts a Creature attack against a Character.")
	if context.read_throw(str(input.id)).ok:
		return {"state": "ended", "message": ENDED}
	var validated := TARGETING.new().validate_creature(context, input)
	if validated.state != "ready":
		return validated
	var target := context.read_actor(SDK.ActorId.new(str(validated.target)))
	var data: Dictionary = target.actor.data
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return _error("Choose a Character to defend against this attack.")
	for previous in _actions:
		if str(previous.target) == target.actor.id.value and str(previous.state) in ["ready", "pending", "shield"]:
			if _alive(context, previous):
				return _error("Finish this Character’s current defence first.")
			_end(context, previous)
	var access := context.actor_access(target.actor.id)
	if not access.ok:
		return _error(access.message)
	var owners: Array[SDK.ActorAccessEntry] = []
	for entry in access.items:
		if entry.access_level == "Owner":
			owners.append(entry)
	if owners.size() > 1:
		var choices: Array = []
		var selected: Array[SDK.ActorAccessEntry] = []
		for owner in owners:
			if owner.is_connected:
				choices.append({"id": owner.participant_id, "name": owner.display_name})
			if owner.participant_id == str(input.get("owner", "")):
				selected.append(owner)
		if selected.is_empty():
			return {"state": "error", "message": "Choose the responsible Player for this Character.", "owners": choices}
		owners = selected
	if owners.size() == 1 and not owners[0].is_connected:
		return _error("This Character’s Player is not connected.")
	var source := context.read_actor(SDK.ActorId.new(input.source))
	var attack: Dictionary = validated.attack
	var abilities: Dictionary = data.get("abilities", {})
	var ability: Dictionary = abilities.get("Agility", {})
	var action := {"id": input.id, "source": input.source, "target": target.actor.id.value, "participant": caller.participant_id, "session": caller.session_id, "owner": owners[0].participant_id if owners.size() == 1 else caller.participant_id, "owner_session": owners[0].session_id if owners.size() == 1 else caller.session_id, "state": "ready", "request": "", "message": "", "attacker": source.actor.public_label if not source.actor.public_label.is_empty() else "Creature", "character": str(data.get("name", "Character")), "attack": attack.name, "damage": attack.dice, "agility": ability.get("modifier", 0), "difficulty": attack.get("defence_dr", 12), "automatic_hit": attack.get("always_hits", false), "phase": "defence", "modifier": 0, "raw": 0, "sequence": 0, "damage_sequence": 0, "loss": 0, "hp": data.get("hit_points", 0), "armor": "", "armor_damaged": false, "protection": "", "shield": ""}
	for raw_item in ITEMS.new(null, target.actor.id).inventory(data):
		var item: Dictionary = raw_item
		var equipped: bool = item.equipped
		var quantity: int = item.quantity
		if not equipped or quantity < 1:
			continue
		var penalty_tier: int = item.get("penalty_tier", item.get("armor_tier", 0))
		if str(item.get("kind", "")) == "Armor" and penalty_tier >= 2:
			var current_dr: int = action.difficulty
			action["difficulty"] = current_dr + 2
		if item.get("broken", false):
			continue
		if str(item.get("kind", "")) == "Armor":
			action["armor"] = str(item.inventory_id)
			action["protection"] = str(item.get("reduction", ""))
		elif str(item.get("kind", "")) == "Shield":
			action["shield"] = str(item.inventory_id)
	if _dice(action.damage, "Damage") == null or (not str(action.protection).is_empty() and _dice(action.protection, "Protection") == null):
		return _error("The attack or protection dice are unsupported.")
	_actions.append(action)
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	return {"initiator": action.participant, "defender": action.owner, "automatic_hit": action.automatic_hit, "id": action.id, "state": action.state, "request": action.request, "message": action.message, "target": action.target, "attacker": action.attacker, "character": action.character, "attack": action.attack, "damage": action.damage, "agility": action.agility, "difficulty": action.difficulty, "loss": action.loss, "hp": action.hp, "protection": action.protection, "has_shield": not str(action.shield).is_empty()}

func _retry(action: Dictionary, message: String) -> Dictionary:
	action["message"] = message
	return _public(action)

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _damage_rolled(context: SDK.SystemActionContext, action: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var damage := _total(action.damage, roll.terms[0].results)
	if action.raw == 1:
		damage *= 2
	var protection := _total(action.protection, roll.terms[1].results) if roll.terms.size() > 1 else 0
	var shield_reduction := 0 if str(action.shield).is_empty() else 1
	var loss: int = damage - protection - shield_reduction
	action["loss"] = loss if loss > 0 else 0
	action["damage_sequence"] = roll.sequence
	if action.raw == 1 and not str(action.armor).is_empty() and not action.armor_damaged:
		if not _damage_armor(context, action):
			return _end(context, action)
	if not str(action.shield).is_empty() and loss > 0:
		action["state"] = "shield"
		action["message"] = ""
		return _public(action)
	return _apply_damage(context, action, false)

func _damage_armor(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	var target := context.read_actor(SDK.ActorId.new(action.target))
	if not target.ok:
		return false
	var current: Dictionary = target.actor.data
	var data := current.duplicate(true)
	var items := ITEMS.new(null, target.actor.id).inventory(data)
	for raw_item in items:
		var item: Dictionary = raw_item
		if str(item.inventory_id) != str(action.armor):
			continue
		var tier: int = item.get("armor_tier", 0)
		if tier < 1:
			return true
		item["penalty_tier"] = item.get("penalty_tier", tier)
		item["armor_tier"] = tier - 1
		item["reduction"] = ["", "d2", "d4"][tier - 1]
		if tier == 1:
			item["broken"] = true
			item["ruined"] = true
		data.inventory = items
		var report := SDK.ActionLogMessage.new("Defence fumble")
		report.result = "Armor damaged"
		report.text = [SDK.ActionLogText.new("Natural 1: double damage; armor reduced one tier. Strength and Agility penalties remain. Armor below tier 1 is ruined and cannot be repaired.")]
		var saved := context.commit([SDK.ActorChange.new(target.actor.id, data)], report)
		if saved.ok:
			action["armor_damaged"] = true
		return saved.ok
	return false

func _apply_damage(context: SDK.SystemActionContext, action: Dictionary, break_shield: bool) -> Dictionary:
	var target := context.read_actor(SDK.ActorId.new(action.target))
	if not target.ok:
		return _end(context, action)
	var current: Dictionary = target.actor.data
	var data := current.duplicate(true)
	var items := ITEMS.new(null, target.actor.id).inventory(data)
	var shield_present := str(action.shield).is_empty()
	for raw_item in items:
		var item: Dictionary = raw_item
		var quantity: int = item.quantity
		if str(item.inventory_id) == str(action.shield) and item.equipped and quantity > 0 and not item.get("broken", false):
			shield_present = true
	if not shield_present:
		return _end(context, action)
	if break_shield:
		for raw_item in items:
			var item: Dictionary = raw_item
			if str(item.inventory_id) == str(action.shield):
				item["equipped"] = false
				var quantity: int = item.quantity
				if quantity > 1:
					item["quantity"] = quantity - 1
					var destroyed := item.duplicate(true)
					destroyed["inventory_id"] = "broken-" + str(action.id)
					destroyed["quantity"] = 1
					destroyed["broken"] = true
					items.append(destroyed)
				else:
					item["broken"] = true
				break
	var loss: int = 0 if break_shield else action.loss
	var hp: int = data.hit_points
	data.hit_points = hp - loss
	data.inventory = items
	var report := SDK.ActionLogMessage.new("Defence")
	report.result = "Shield broken" if break_shield else "%d damage" % loss
	var sequence: int = action.sequence
	var damage_sequence: int = action.damage_sequence
	var text := "%s takes %d damage from %s. Raw Roll #%d." % [str(action.character), loss, str(action.attacker), damage_sequence]
	if action.automatic_hit:
		text += " This source attack always hits; no defence test."
	else:
		text += " Defence Raw Roll #%d." % sequence
	if break_shield:
		text += " Shield destroyed; attack damage ignored."
	if str(action.damage).ends_with("d2") or str(action.protection).ends_with("d2"):
		text += " d2 uses each physical d4 halved, rounded up."
	report.text = [SDK.ActionLogText.new(text)]
	var saved := context.commit([SDK.ActorChange.new(target.actor.id, data)], report)
	if not saved.ok:
		return _end(context, action)
	action["state"] = "resolved"
	action["message"] = ""
	return _public(action)

func _dice(formula: String, label: String) -> SDK.DiceTerm:
	var parts := formula.to_lower().split("d")
	if parts.size() != 2 or not parts[1].is_valid_int() or (not parts[0].is_empty() and not parts[0].is_valid_int()):
		return null
	var faces := int(parts[1])
	var count := 1 if parts[0].is_empty() else int(parts[0])
	if not faces in [2, 4, 6, 8, 10, 12, 20] or count < 1 or count > 15:
		return null
	return SDK.DiceTerm.new(label, 4 if faces == 2 else faces, count)

func _total(formula: String, faces: Array[int]) -> int:
	var total := 0
	for face in faces:
		total += int((face + 1) / 2) if formula.ends_with("d2") else face
	return total

func _end(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	action["state"] = "ended"
	action["message"] = ENDED
	if not str(action.request).is_empty():
		context.cancel_throw(action.request)
	var report := SDK.ActionLogMessage.new("Defence ended")
	report.result = "ENDED"
	report.tone = "attention"
	report.text = [SDK.ActionLogText.new(ENDED)]
	context.commit([], report)
	return _public(action)

func _alive(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	var sessions := context.participant_sessions()
	if not sessions.ok:
		return false
	var initiator_present := false
	var defender_present := false
	var defender_is_gm := false
	var entries: Array = sessions.value
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		if entry.participant_id == action.participant and entry.session_id == action.session and entry.is_gm:
			initiator_present = true
		if entry.participant_id == action.owner and entry.session_id == action.owner_session:
			defender_present = true
			defender_is_gm = entry.is_gm
	if not initiator_present or not defender_present:
		return false
	var source := context.read_actor(SDK.ActorId.new(action.source))
	var target := context.read_actor(SDK.ActorId.new(action.target))
	if not source.ok or not target.ok:
		return false
	var target_data: Dictionary = target.actor.data
	action["hp"] = target_data.get("hit_points", 0)
	if defender_is_gm:
		return true
	var access := context.actor_access(target.actor.id)
	if access.ok:
		for entry in access.items:
			if entry.participant_id == action.owner and entry.access_level == "Owner":
				return true
	return false

func _request_damage(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	var terms: Array[SDK.DiceTerm] = [_dice(action.damage, "Damage")]
	if not str(action.protection).is_empty():
		terms.append(_dice(action.protection, "Protection"))
	action["request"] = context.new_request_id()
	var requested := context.request_throw(SDK.HumanThrowRequest.new(action.request, action.owner, terms))
	if not requested.ok:
		return _end(context, action)
	action["state"] = "pending"
	action["phase"] = "damage"
	action["message"] = "Waiting for damage and protection in the Dice Tray."
	return _public(action)

func _find(id: String) -> Dictionary:
	for action in _actions:
		if str(action.id) == id:
			return action
	return {}
