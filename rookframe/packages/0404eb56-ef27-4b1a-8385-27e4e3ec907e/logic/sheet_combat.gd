extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_authority.gd"

## Separate, target-free sheet interactions reuse the current own consequences.
var _attacks: Dictionary = {}

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	var source := context.read_actor(SDK.ActorId.new(str(input.get("source", ""))))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Owner access is required to roll this Character.")
	var data: Dictionary = source.actor.data
	if not _valid_character(data):
		return _error("Character data is malformed. Correct the sheet first.")
	if str(input.get("part", "attack")) == "attack" and not BROKEN.new().can_act(data):
		return _error("This Character cannot act. Rules references remain available.")
	var part := str(input.get("part", "attack"))
	if part not in ["attack", "damage"]:
		return _error("Choose Attack or Damage.")
	var items := _inventory(source.actor.id, data)
	var item_id := str(input.get("item", ""))
	var weapon := _weapon(items, item_id)
	var bite := item_id == "class:bite" and str(data.get("class_id", "")) == "fanged-deserter"
	if bite:
		weapon = {"inventory_id": item_id, "source_item_id": "bite", "name": "Bite", "damage": "d6", "range_feet": 5, "attack_dr": 10, "quantity": 1, "equipped": true}
	var preceding: Dictionary = _attacks.get(source.actor.id.value, {})
	var matching := part == "damage" and str(preceding.get("item", "")) == item_id
	if matching:
		var remembered: Dictionary = preceding.get("weapon_data", {})
		weapon = remembered.duplicate(true)
	if weapon.is_empty() or not weapon.get("equipped", false) or int(weapon.get("quantity", 0)) < 1 or weapon.get("broken", false):
		return _error("Choose a ready, usable weapon.")
	var formula := str(weapon.get("damage", ""))
	var damage := _dice(formula, "Damage")
	if damage == null:
		return _error("This weapon's damage requires a table ruling.")
	var special := str(weapon.get("source_item_id", ""))
	var jab := str(input.get("mode", "")) == "jab"
	if jab:
		var permitted := false
		var traits: Array = data.get("traits", [])
		for trait_entry in traits:
			var feature: Dictionary = trait_entry
			permitted = permitted or str(feature.get("id", "")) == "cowards-jab"
		if not permitted or int(weapon.get("range_feet", 0)) != 5 or weapon.get("two_handed", false) or special == "zweihander":
			return _error("Coward's jab requires its specialty and a light one-handed weapon.")
	var ability_name := "Agility" if jab else str(weapon.get("attack_ability", "Strength"))
	var abilities: Dictionary = data.get("abilities", {})
	var ability: Dictionary = abilities.get(ability_name, {})
	var difficulty := int(input.get("difficulty", 0))
	if difficulty == 0:
		difficulty = 10 if jab else int(weapon.get("attack_dr", 12))
		if ability_name == "Presence" and str(data.get("class_id", "")) == "gutterborn-scum":
			difficulty -= 2
	var modifier := int(input.get("modifier", 0))
	if difficulty < 1 or difficulty > 30 or modifier < -20 or modifier > 20:
		return _error("Use DR 1–30 and a situational modifier from −20 to +20.")
	var ammunition: Dictionary = {}
	if part == "attack" and not str(weapon.get("ammunition", "")).is_empty():
		var available := AMMUNITION.new().available(items, str(weapon.ammunition))
		if available.is_empty():
			return _error("No usable ammunition remains.")
		ammunition = available[0] if str(input.get("ammunition", "")).is_empty() else _ammunition(items, weapon, str(input.ammunition))
		if ammunition.is_empty():
			return _error("Choose available ammunition.")
	var action := {"id": str(input.id), "participant": str(caller.participant_id), "session": str(caller.session_id), "owner": str(caller.participant_id), "owner_session": str(caller.session_id), "source": source.actor.id.value, "item": item_id, "weapon": _short_name(str(weapon.name), 16), "weapon_data": weapon.duplicate(true), "name": _short_name(str(data.get("name", "Character")), 12), "phase": part, "state": "pending", "request": str(input.id), "raw": 0, "sequence": 0, "modifier": int(ability.get("modifier", 0)) + modifier, "difficulty": difficulty, "damage": formula, "jab": jab, "natural": bite, "special": special, "fumble": str(input.get("fumble", "break")), "resource_spent": false, "ammunition": str(ammunition.get("inventory_id", "")), "ammunition_kind": str(weapon.get("ammunition", "")), "message": "Rolling " + part + "…", "attack_context": preceding.duplicate(true) if matching else {}}
	var terms: Array[SDK.DiceTerm] = [SDK.DiceTerm.new("Attack", 20)] if part == "attack" else [damage]
	if part == "attack" and (bite or special == "eurekia"):
		terms.append(SDK.DiceTerm.new("Free attack chance" if bite else "Eurekia consequence", 6))
	if part == "damage" and special in ["brown-scimitar-of-galgenbeck", "shoe-of-deaths-horse"]:
		terms.append(SDK.DiceTerm.new("Special consequence", 6))
	var request := context.request_throw(SDK.HumanThrowRequest.new(action.id, action.owner, terms))
	if not request.ok:
		return _error(request.message)
	_actions[action.id] = action
	return _public(action)

func _existing(context: SDK.SystemActionContext, caller: Dictionary, id: String) -> Dictionary:
	var action: Dictionary = _actions.get(id, {})
	if str(action.participant) != str(caller.participant_id) or str(action.session) != str(caller.session_id):
		return _error("This action belongs to another Participant session.")
	if action.state != "pending":
		return _public(action)
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok or source.actor.access_level != "Owner" or str(action.phase) == "attack" and not BROKEN.new().can_act(source.actor.data):
		return _end(context, action)
	var roll := context.read_throw(str(action.request))
	if not roll.ok or roll.status == "cancelled":
		return _end(context, action)
	if roll.status == "pending":
		return _public(action)
	if action.phase == "attack":
		action.raw = roll.terms[0].results[0]
		action.sequence = roll.sequence
		if not _spend_ammunition(context, action, source.actor):
			return _end(context, action)
		if action.special == "eurekia" and not _eurekia(context, action, source.actor, roll.terms[1].results[0]):
			return _end(context, action)
		var face := int(action.raw)
		var text := "Attack: d20 %d %+d = %d, DR%d. Raw Roll #%d." % [face, int(action.modifier), face + int(action.modifier), int(action.difficulty), roll.sequence]
		if action.special == "bite" and roll.terms[1].results[0] <= 2:
			text += " The enemy gains a free attack; resolve it at the table."
		var result: Dictionary
		if face == 1 and not action.jab:
			result = _fumble(context, action, source.actor) if not action.get("vanished", false) else _complete(context, action, [], "Fumble", text + " Eurekia vanishes.")
		else:
			var hit := face == 20 or face + int(action.modifier) >= int(action.difficulty)
			result = _complete(context, action, [], "Critical" if face == 20 and not action.jab else ("Hit" if hit else "Miss"), text)
		if action.state == "resolved":
			_attacks[str(action.source)] = {"id": action.id, "item": action.item, "weapon_data": action.weapon_data, "critical": face == 20 and not action.jab, "jab": action.jab}
		return result
	var preceding: Dictionary = action.attack_context
	var still_matching: Dictionary = _attacks.get(str(action.source), {})
	if not preceding.is_empty() and str(still_matching.get("id", "")) != str(preceding.id):
		preceding = {}
	var damage := 0
	for face in roll.terms[0].results:
		damage += _face_value(str(action.damage), face)
	if str(action.damage).contains("+"):
		damage += int(str(action.damage).split("+")[1])
	if preceding.get("jab", false):
		damage += 3
	if preceding.get("critical", false):
		damage *= 2
	var text := "Damage: %s = %d%s. Raw Roll #%d. Resolve target protection and consequences at the table." % [str(action.damage), damage, " (critical doubled)" if preceding.get("critical", false) else "", roll.sequence]
	if roll.terms.size() > 1:
		text += " Special consequence d6: %d." % roll.terms[1].results[0]
	var result := _complete(context, action, [], "%d damage" % damage, text)
	if action.state == "resolved" and not preceding.is_empty():
		_attacks[str(action.source)] = {}
	return result
