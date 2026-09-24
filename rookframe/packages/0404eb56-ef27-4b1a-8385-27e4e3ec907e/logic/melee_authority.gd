extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/implementation.gd"

## One live System action per supplied UUID, resolved on World Authority.
## World data is shared in full; Actor privacy applies only to UI display.
## Reopening has no actions to resume; durable session Throw IDs cannot restart one.
const AMMUNITION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/ammunition.gd")
const CREATURE_ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_actions.gd")
const ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/character_actions.gd")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const TARGETING = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/attack_targeting.gd")
const ENDED := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
var _actions: Dictionary = {}

func handle_system_intent(context: SDK.SystemActionContext, name: String, payload: Variant) -> Variant:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("The melee action is malformed.")
	var input: Dictionary = payload
	if name == "attack.validate":
		return TARGETING.new().validate_creature(context, input)
	if typeof(input.get("id", "")) != TYPE_STRING:
		return _error("The action identity must be text.")
	if name == "melee.start" and not _valid_options(input):
		return _error("The melee action options are malformed.")
	var caller_result := context.caller()
	if not caller_result.ok:
		return _error(caller_result.message)
	var caller: Dictionary = caller_result.value
	var id: String = str(input.get("id", ""))
	if id.is_empty() or id.length() > 64:
		return _error("Choose a new action identity.")
	if name == "melee.start":
		if _actions.has(id):
			return _existing(context, caller, id)
		if context.read_throw(id).ok:
			return {"state": "ended", "message": ENDED}
		var started := _start(context, caller, input)
		if started.state == "error":
			started["participant"] = caller.participant_id
			started["session"] = caller.session_id
			started["request"] = ""
			_actions[id] = started
		return _public(started)
	if not _actions.has(id):
		return {"state": "ended", "message": ENDED}
	var action: Dictionary = _actions.get(id, {})
	if action.participant != caller.participant_id or action.session != caller.session_id:
		return _error("This action belongs to another Participant session.")
	if name == "melee.cancel":
		return _end(context, action)
	if name == "melee.advance":
		return _existing(context, caller, id)
	return _error("Unsupported System action.")

func _start(context: SDK.SystemActionContext, caller: Dictionary, input: Dictionary) -> Dictionary:
	var source := context.read_actor(SDK.ActorId.new(str(input.get("source", ""))))
	if not source.ok or source.actor.access_level != "Owner":
		return _error("Owner access is required to attack with this Actor.")
	if typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Character data is malformed.")
	var data: Dictionary = source.actor.data
	if not _valid_source(data):
		return _error("Actor combat data is malformed.")
	var creature_source := str(data.get("schema", "")) == "mork-borg-adversary/v1"
	var rook_id := SDK.RookId.new(str(input.get("rook", "")))
	var rook := context.read_rook(rook_id)
	if not rook.ok or rook.rook.actor == null or rook.rook.actor.value != source.actor.id.value or rook.rook.scene.value != "main":
		return _error("Select this Actor’s source Rook in the current Scene.")
	var items := _inventory(source.actor.id, data)
	var weapon := _weapon(items, str(input.get("item", "")))
	var bite := str(input.get("item", "")) == "class:bite" and str(data.get("class_id", "")) == "fanged-deserter"
	if bite:
		weapon = {"inventory_id": "class:bite", "source_item_id": "bite", "name": "Bite", "kind": "Weapon", "damage": "d6", "range_feet": 5, "attack_dr": 10, "equipped": true, "quantity": 1}
	var jab := str(input.get("mode", "")) == "jab"
	if jab:
		var permitted := false
		var traits: Array = data.get("traits", [])
		for raw in traits:
			var feature: Dictionary = raw
			if str(feature.get("id", "")) == "cowards-jab":
				permitted = true
		if not permitted or not input.get("eligible", false) or int(weapon.get("range_feet", 0)) != 5 or weapon.get("two_handed", false) or str(weapon.get("source_item_id", "")) == "zweihander":
			return _error("Coward's jab requires surprise and a light one-handed equipped weapon, confirmed with the table.")
		weapon["attack_dr"] = 10
		weapon["attack_ability"] = "Agility"
	var equipped: bool = weapon.get("equipped", false)
	var quantity: int = weapon.get("quantity", 0)
	var broken: bool = weapon.get("broken", false)
	if weapon.is_empty() or not equipped or quantity < 1 or broken:
		return _error("Choose an equipped, usable weapon in Inventory.")
	var special := str(weapon.get("source_item_id", ""))
	if special in ["shoe-of-deaths-horse", "sacred-shepherds-crook"] and not input.get("eligible", false):
		return _error("Confirm the target's size or faithless-human status with the table.")
	if special == "sacred-shepherds-crook" and input.get("faithless_human", false):
		weapon["damage"] = "d4"
	if special == "eurekia" and (not input.get("eligible", false) or (not weapon.get("drawn", false) and int(weapon.get("uses", 0)) < 1)):
		return _error("Find Hamfund and confirm drawing Eurekia once this combat; correct the sword's remaining draws when the table agrees.")
	var reach: int = weapon.get("range_feet", 0)
	var damage := _dice(str(weapon.get("damage", "")), "Damage")
	if str(weapon.get("kind", "")) != "Weapon" or reach <= 0 or damage == null:
		return _error("This item has no supported attack with an authored range.")
	if not creature_source and not weapon.has("attack_ability") and not reach in [5, 10]:
		return _error("This weapon needs explicit attack rules. Choose a core ranged weapon from the catalogue.")
	var ammunition := _ammunition(items, weapon, str(input.get("ammunition", "")))
	if not str(weapon.get("ammunition", "")).is_empty() and ammunition.is_empty():
		return _error("Choose available %s ammunition in Inventory." % str(weapon.ammunition))
	var profile: Dictionary = {}
	if creature_source:
		for raw_option in CREATURES.new().attack_options(data):
			var option: Dictionary = raw_option
			if str(option.get("inventory_id", "creature:" + str(option.id))) == str(weapon.inventory_id):
				profile = option
	var ability_name := str(weapon.get("attack_ability", "Strength"))
	if not ability_name in ["Strength", "Presence", "Agility"]:
		return _error("Choose a supported attack ability.")
	var difficulty: int = input.get("difficulty", 0)
	var modifier: int = input.get("modifier", 0)
	var fumble := str(input.get("fumble", "break"))
	if difficulty < 0 or difficulty > 30 or modifier < -20 or modifier > 20 or not fumble in ["break", "lose"]:
		return _error("Choose source difficulty (0) or an override 1–30, a modifier from −20 to +20, and a fumble choice.")
	var target_ids: PackedStringArray = caller.targets
	var targets: Array[SDK.Actor] = []
	var outside: Array[String] = []
	for target_id in target_ids:
		var target_rook := context.read_rook(SDK.RookId.new(target_id))
		if not target_rook.ok or target_rook.rook.actor == null:
			return _error("Every target must be a Creature Rook.")
		var target := context.read_actor(target_rook.rook.actor)
		if not target.ok:
			return _error("A targeted Creature is unavailable.")
		if typeof(target.actor.data) != TYPE_DICTIONARY:
			return _error("Creature data is malformed.")
		var creature: Dictionary = target.actor.data
		if not _valid_creature(creature):
			return _error("Creature combat data is malformed.")
		if str(creature.get("schema", "")) != "mork-borg-adversary/v1" or target.actor.id.value == source.actor.id.value:
			return _error("Choose a Creature target for this attack.")
		if creature_source and TARGETING.new().resolution_for(context, target.actor) != "attack":
			return _error("Request this Actor’s defence instead of a second attack test.")
		var distance := context.distance(rook_id, SDK.RookId.new(target_id))
		if not distance.ok:
			return _error(distance.message)
		if distance.distance > float(reach) * 0.3048 + 0.000001:
			outside.append("target %s not in range" % _public_name(target.actor))
		targets.append(target.actor)
	if not outside.is_empty():
		var weapon_name: String = str(weapon.name)
		var report := SDK.ActionLogMessage.new("%s attack" % _short_name(weapon_name, 16))
		for line in outside:
			report.text.append(SDK.ActionLogText.new(line))
		report.result = "Stopped"
		report.tone = "attention"
		context.commit([], report)
		var text := ""
		for line in outside:
			text += ("\n" if not text.is_empty() else "") + line
		return _error(text)
	if targets.size() != 1:
		return _error("Choose exactly one Creature target. Nothing has been rolled.")
	var owner := str(caller.participant_id)
	var owner_session := str(caller.session_id)
	var game_master: bool = caller.is_gm
	if game_master:
		var access := context.actor_access(source.actor.id)
		if not access.ok:
			return _error(access.message)
		var owners: Array[SDK.ActorAccessEntry] = []
		for entry in access.items:
			if entry.access_level == "Owner":
				owners.append(entry)
		if owners.size() > 1:
			return _error("Several Players own this Character. The responsible Player can attack from their sheet.")
		if owners.size() == 1:
			if not owners[0].is_connected:
				return _error("This Character’s Player is not connected.")
			owner = owners[0].participant_id
			owner_session = owners[0].session_id
	var target_data: Dictionary = targets[0].data
	var definition: Dictionary = CREATURES.CORE_DEFINITIONS.get(str(target_data.get("definition_id", "")), {})
	if difficulty == 0:
		difficulty = CREATURES.new().target_attack_difficulty(target_data, input.get("piercing", false))
		if creature_source:
			difficulty += CREATURES.new().attack_test_difficulty(profile) - 12
	if difficulty == 0:
		return _error("Attack difficulty is unavailable.")
	var specified_dr: int = input.get("difficulty", 0)
	if not creature_source and specified_dr == 0:
		var weapon_dr: int = weapon.get("attack_dr", 12)
		difficulty += weapon_dr - 12
	if not creature_source and ability_name == "Presence" and str(data.get("class_id", "")) == "gutterborn-scum":
		var presence_difficulty: int = difficulty
		difficulty = presence_difficulty - 2
	var armor: Dictionary = target_data.get("armor", {})
	var protection_text := str(armor.get("reduction", ""))
	if not protection_text in ["", "d2", "d4", "d6"]:
		return _error("This Creature's protection requires a table ruling.")
	var abilities: Dictionary = data.get("abilities", {})
	var ability: Dictionary = abilities.get(ability_name, {})
	var ability_modifier: int = 0 if creature_source else ability.get("modifier", 0)
	var destruction: int = target_data.get("destroy_at_damage", definition.get("destroy_at_damage", 0))
	var action := {"id": str(input.id), "participant": str(caller.participant_id), "session": str(caller.session_id), "source": source.actor.id.value, "target": targets[0].id.value, "item": str(weapon.inventory_id), "weapon": _short_name(str(weapon.name), 16), "name": _short_name(str(data.get("name", "Character")), 12), "label": _public_name(targets[0]), "owner": owner, "owner_session": owner_session, "destroy_at_damage": destruction, "ammunition": str(ammunition.get("inventory_id", "")), "ammunition_kind": str(weapon.get("ammunition", "")), "resource_spent": false, "modifier": ability_modifier + modifier, "difficulty": difficulty, "fumble": fumble, "jab": jab, "natural": bite or profile.get("natural", false), "automatic_hit": profile.get("always_hits", false), "damage": str(weapon.damage), "special": special, "small_medium": input.get("small_medium", false), "faithless_human": input.get("faithless_human", false), "protection": protection_text, "shield": CREATURE_ITEMS.new(null, targets[0].id).shield_reduction(target_data), "state": "pending", "phase": "attack", "request": str(input.id), "raw": 0, "sequence": 0, "message": "Waiting for the attack Throw in the Dice Tray."}
	var initial_terms: Array[SDK.DiceTerm] = [SDK.DiceTerm.new("Attack", 20)]
	if bite or special == "eurekia":
		initial_terms.append(SDK.DiceTerm.new("Free attack chance" if bite else "Eurekia consequence", 6))
	if action.automatic_hit:
		action.phase = "damage"
		action.message = "This attack always hits. Waiting for damage and protection in the Dice Tray."
		initial_terms = [damage]
		if not protection_text.is_empty():
			initial_terms.append(_dice(protection_text, "Protection"))
	var requested := context.request_throw(SDK.HumanThrowRequest.new(action.id, owner, initial_terms))
	if not requested.ok:
		return _error(requested.message)
	_actions[action.id] = action
	return _public(action)

func _existing(context: SDK.SystemActionContext, caller: Dictionary, id: String) -> Dictionary:
	var action: Dictionary = _actions.get(id, {})
	if action.participant != caller.participant_id or action.session != caller.session_id:
		return _error("This action belongs to another Participant session.")
	if action.state != "pending":
		return _public(action)
	var sessions := context.participant_sessions()
	var present := false
	if sessions.ok:
		var entries: Array = sessions.value
		for raw in entries:
			var entry: Dictionary = raw
			if entry.participant_id == action.participant and entry.session_id == action.session:
				present = true
	if not present:
		return _end(context, action)
	var source := context.read_actor(SDK.ActorId.new(action.source))
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var current_source: Dictionary = source.actor.data
	if not _valid_source(current_source):
		return _end(context, action)
	if action.owner != action.participant:
		var access := context.actor_access(source.actor.id)
		var connected := false
		if access.ok:
			for entry in access.items:
				if entry.participant_id == action.owner and entry.access_level == "Owner" and entry.is_connected and entry.session_id == action.owner_session:
					connected = true
		if not connected:
			return _end(context, action)
	var result := context.read_throw(action.request)
	if not result.ok or result.status == "cancelled":
		return _end(context, action)
	if result.status == "pending":
		return _public(action)
	if action.phase == "attack":
		action.raw = result.terms[0].results[0]
		action.sequence = result.sequence
		if not _spend_ammunition(context, action, source.actor):
			return _end(context, action)
		if str(action.special) == "bite":
			action["free_attack"] = result.terms[1].results[0] <= 2
		if str(action.special) == "eurekia" and not _eurekia(context, action, source.actor, result.terms[1].results[0]):
			return _end(context, action)
		if action.raw == 1 and action.get("vanished", false):
			return _complete(context, action, [], "Fumble", "Eurekia vanishes; the attack misses.")
		if action.raw == 1 and not action.jab:
			return _fumble(context, action, source.actor)
		var raw_face: int = action.raw
		var modifier: int = action.modifier
		var difficulty: int = action.difficulty
		var sequence: int = action.sequence
		if raw_face != 20 and raw_face + modifier < difficulty:
			return _complete(context, action, [], "Miss", "%s misses %s. d20 %d %+d. Raw Roll #%d." % [str(action.name), str(action.label), raw_face, modifier, sequence] + (" The enemy gains a free attack; resolve it from its sheet." if action.get("free_attack", false) else ""))
		var terms: Array[SDK.DiceTerm] = [_dice(action.damage, "Damage")]
		if not str(action.protection).is_empty():
			terms.append(_dice(action.protection, "Protection"))
		if str(action.special) in ["brown-scimitar-of-galgenbeck", "shoe-of-deaths-horse"]:
			terms.append(SDK.DiceTerm.new("Special consequence", 6))
		action.phase = "damage"
		action.request = context.new_request_id()
		var damage_request := context.request_throw(SDK.HumanThrowRequest.new(action.request, action.owner, terms))
		if not damage_request.ok:
			return _end(context, action)
		action.message = "Hit. Waiting for damage and protection in the Dice Tray."
		return _public(action)
	if action.automatic_hit:
		action.sequence = result.sequence
		if not _spend_ammunition(context, action, source.actor):
			return _end(context, action)
	return _damage(context, action, result)

func _damage(context: SDK.SystemActionContext, action: Dictionary, result: SDK.HumanThrowResult) -> Dictionary:
	var target := context.read_actor(SDK.ActorId.new(action.target))
	if not target.ok or typeof(target.actor.data) != TYPE_DICTIONARY:
		return _end(context, action)
	var data: Dictionary = target.actor.data
	if not _valid_creature(data):
		return _end(context, action)
	data = data.duplicate(true)
	var damage := 0
	for value in result.terms[0].results:
		damage += _face_value(action.damage, value)
	if str(action.damage).contains("+"):
		damage += int(str(action.damage).split("+")[1])
	if action.jab:
		damage += 3
	if action.raw == 20 and not action.jab:
		damage *= 2
	var protection := 0
	if not str(action.protection).is_empty():
		for value in result.terms[1].results:
			protection += _face_value(action.protection, value)
	var shield: int = action.get("shield", 0)
	var lost: int = damage - protection - shield
	if lost < 0:
		lost = 0
	var hit_points: int = data.get("hit_points", 0)
	data["hit_points"] = hit_points - lost
	var threshold: int = action.get("destroy_at_damage", 0)
	if threshold > 0 and lost >= threshold and hit_points - lost > 0:
		data["hit_points"] = 0
	var poisoned := str(action.get("special", "")) == "snake-skin-gift" and result.terms[0].results[0] == 1
	var secondary := 0
	if str(action.special) in ["brown-scimitar-of-galgenbeck", "shoe-of-deaths-horse"]:
		secondary = result.terms[-1].results[0]
	var skull: bool = str(action.special) == "shoe-of-deaths-horse" and action.small_medium and secondary == 1
	if poisoned or skull:
		data["hit_points"] = 0
	if action.raw == 20 and not action.jab:
		CREATURE_ITEMS.new(null, target.actor.id).damage_armor(data)
	var sequence: int = action.sequence
	var text := "%s hits %s for %d damage after protection. Raw Rolls #%d and #%d." % [str(action.name), str(action.label), lost, sequence, result.sequence]
	if action.get("free_attack", false):
		text += " The enemy gains a free attack; resolve it from its sheet."
	if str(action.special) == "sacred-shepherds-crook" and action.faithless_human:
		text += " Against a faithless human, use ordinary staff d4 damage."
	if skull:
		text += " The shoe smashes the skull, instantly killing the small-to-medium creature."
	if str(action.special) == "brown-scimitar-of-galgenbeck" and lost > 0 and secondary == 1:
		text += " Sepsis: the wounded enemy dies in 10 minutes. Resolve this delayed consequence manually."
	if poisoned:
		text += " The snake-skin gift: damage die 1; the target dies immediately from poison."
	if action.automatic_hit:
		text = "%s hits %s for %d damage after protection. This attack always hits. Raw Roll #%d." % [str(action.name), str(action.label), lost, result.sequence]
	if str(action.damage).ends_with("d2") or str(action.protection).ends_with("d2"):
		text += " d2 uses each physical d4 halved, rounded up."
	if action.raw == 20 and not action.jab:
		text += " Critical: double damage and protection reduced one tier."
	return _complete(context, action, [SDK.ActorChange.new(target.actor.id, data)], str(lost) + " damage", text)

func _fumble(context: SDK.SystemActionContext, action: Dictionary, source: SDK.Actor) -> Dictionary:
	if action.natural:
		var roll_sequence: int = action.sequence
		return _complete(context, action, [], "Fumble", "%s: natural-weapon fumble. The GM determines the consequence. Natural 1; Raw Roll #%d." % [str(action.name), roll_sequence] + (" The enemy gains a free attack; resolve it from its sheet." if action.get("free_attack", false) else ""))
	var data: Dictionary = source.data
	data = data.duplicate(true)
	var items := _inventory(source.id, data)
	var item := _weapon(items, action.item)
	if item.is_empty():
		return _end(context, action)
	if action.fumble == "lose":
		var quantity: int = item.get("quantity", 1)
		item["quantity"] = quantity - 1 if quantity > 0 else 0
		if item.quantity == 0:
			var kept: Array = []
			for entry in items:
				if entry != item:
					kept.append(entry)
			items = kept
	else:
		item["broken"] = true
		item["equipped"] = false
	data["inventory"] = items
	if str(data.get("schema", "")) == "mork-borg-adversary/v1":
		data["creature_inventory"] = true
	var sequence: int = action.sequence
	return _complete(context, action, [SDK.ActorChange.new(source.id, data)], "Fumble", "%s: %s %s. Natural 1; Raw Roll #%d." % [str(action.name), str(action.weapon), "lost" if action.fumble == "lose" else "broken", sequence])

func _complete(context: SDK.SystemActionContext, action: Dictionary, changes: Array[SDK.ActorChange], outcome: String, text: String) -> Dictionary:
	var report := SDK.ActionLogMessage.new("%s · %s attack" % [str(action.name), str(action.weapon)])
	report.text = [SDK.ActionLogText.new(text)]
	report.result = outcome
	var saved := context.commit(changes, report)
	if not saved.ok:
		return _end(context, action)
	action.state = "resolved"
	action.message = text
	return _public(action)

func _end(context: SDK.SystemActionContext, action: Dictionary) -> Dictionary:
	if action.state != "pending":
		return _public(action)
	action.state = "ended"
	action.message = ENDED
	context.cancel_throw(action.request)
	var report := SDK.ActionLogMessage.new("%s · %s attack ended" % [str(action.name), str(action.weapon)])
	report.text = [SDK.ActionLogText.new(ENDED)]
	report.result = "ENDED"
	report.tone = "attention"
	context.commit([], report)
	return _public(action)

func _public(action: Dictionary) -> Dictionary:
	return {"state": action.state, "message": action.message, "request": action.request}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}

func _public_name(actor: SDK.Actor) -> String:
	return actor.public_label if not actor.public_label.is_empty() else "Creature"

func _weapon(items: Array, id: String) -> Dictionary:
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == id:
			return item
	return {}

func _dice(formula: String, name: String) -> SDK.DiceTerm:
	var base := formula.to_lower().split("+")[0]
	var parts := base.split("d")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var count := 1 if parts[0].is_empty() else int(parts[0])
	var faces := int(parts[1])
	if count < 1 or count > 15 or not faces in [2, 4, 6, 8, 10, 12, 20]:
		return null
	return SDK.DiceTerm.new(name, 4 if faces == 2 else faces, count)

func _face_value(formula: String, value: int) -> int:
	return int((value + 1) / 2) if formula.ends_with("d2") else value

func _valid_options(input: Dictionary) -> bool:
	for key in ["source", "rook", "item", "fumble", "ammunition"]:
		if typeof(input.get(key, "")) != TYPE_STRING:
			return false
	for key in ["difficulty", "modifier"]:
		if typeof(input.get(key, 0)) != TYPE_INT:
			return false
	for key in ["piercing", "eligible", "small_medium", "faithless_human"]:
		if typeof(input.get(key, false)) != TYPE_BOOL:
			return false
	return true

func _valid_character(data: Dictionary) -> bool:
	if str(data.get("schema", "")) != "mork-borg-character/v1" or typeof(data.get("inventory", [])) != TYPE_ARRAY or typeof(data.get("inventory_serial", 0)) != TYPE_INT or typeof(data.get("abilities", {})) != TYPE_DICTIONARY:
		return false
	var abilities: Dictionary = data.get("abilities", {})
	for name in ["Strength", "Presence"]:
		if typeof(abilities.get(name, {})) != TYPE_DICTIONARY:
			return false
		var ability: Dictionary = abilities.get(name, {})
		if typeof(ability.get("modifier", 0)) != TYPE_INT:
			return false
	var items: Array = data.get("inventory", [])
	for raw in items:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = raw
		for key in ["inventory_id", "source_item_id", "name", "kind", "damage", "attack_ability", "ammunition", "resource_field"]:
			if typeof(item.get(key, "")) != TYPE_STRING:
				return false
		for key in ["quantity", "range_feet", "uses"]:
			if typeof(item.get(key, 0)) != TYPE_INT:
				return false
		for key in ["equipped", "broken"]:
			if typeof(item.get(key, false)) != TYPE_BOOL:
				return false
	return true

func _valid_creature(data: Dictionary) -> bool:
	if str(data.get("schema", "")) != "mork-borg-adversary/v1" or typeof(data.get("armor", {})) != TYPE_DICTIONARY:
		return false
	for key in ["hit_points", "defence_dr", "piercing_defence_dr", "destroy_at_damage"]:
		if typeof(data.get(key, 0)) != TYPE_INT:
			return false
	var armor: Dictionary = data.get("armor", {})
	return typeof(armor.get("reduction", "")) == TYPE_STRING

## Reserve two UTF-16 units per character for the host report title limit,
## including supplementary Unicode names and the longest ended suffix.
func _short_name(text: String, limit: int) -> String:
	var result := ""
	for character in text.split(""):
		if result.length() >= limit:
			break
		result += character
	return result

func _ammunition(items: Array, weapon: Dictionary, id: String) -> Dictionary:
	for item in AMMUNITION.new().available(items, str(weapon.get("ammunition", ""))):
		if str(item.get("inventory_id", "")) == id:
			return item
	return {}

func _spend_ammunition(context: SDK.SystemActionContext, action: Dictionary, source: SDK.Actor) -> bool:
	if str(action.ammunition).is_empty() or action.resource_spent:
		return true
	var current: Dictionary = source.data
	var data := current.duplicate(true)
	var items := _inventory(source.id, data)
	var resource := _ammunition(items, {"ammunition": action.ammunition_kind}, action.ammunition)
	if resource.is_empty():
		return false
	var field := str(resource.get("resource_field", "quantity"))
	var remaining: int = resource.get(field, 0)
	if field == "uses":
		resource["uses"] = remaining - 1
	else:
		resource["quantity"] = remaining - 1
	data["inventory"] = items
	if str(data.get("schema", "")) == "mork-borg-adversary/v1":
		data["creature_inventory"] = true
	var report := SDK.ActionLogMessage.new("Ammunition used")
	var sequence: int = action.sequence
	report.text = [SDK.ActionLogText.new("%s fired one %s. Raw Roll #%d." % [str(action.name), str(action.ammunition_kind), sequence])]
	report.result = "1 spent"
	var saved := context.commit([SDK.ActorChange.new(source.id, data)], report)
	if not saved.ok:
		return false
	action.resource_spent = true
	# The same callback can resolve a fumble; keep its source snapshot current.
	source.data = data
	return true

func _valid_source(data: Dictionary) -> bool:
	return _valid_creature(data) if str(data.get("schema", "")) == "mork-borg-adversary/v1" else _valid_character(data)

func _inventory(id: SDK.ActorId, data: Dictionary) -> Array:
	if str(data.get("schema", "")) == "mork-borg-adversary/v1":
		return CREATURE_ITEMS.new(null, id).inventory(data)
	return ITEMS.new(null, id).inventory(data)

func _eurekia(context: SDK.SystemActionContext, action: Dictionary, source: SDK.Actor, face: int) -> bool:
	var current: Dictionary = source.data
	var data := current.duplicate(true)
	var items := _inventory(source.id, data)
	var item := _weapon(items, str(action.item))
	if item.is_empty():
		return false
	if not item.get("drawn", false):
		var uses: int = item.get("uses", 0)
		if uses < 1:
			return false
		item["uses"] = uses - 1
		item["drawn"] = true
	var text := "Eurekia drawn for this combat. Reset its remaining draw manually for a later combat."
	if face == 1:
		action["vanished"] = true
		item["quantity"] = 0
		item["equipped"] = false
		var companions: Array = data.get("companion_sheets", [])
		for raw in companions:
			var companion: Dictionary = raw
			if str(companion.get("id", "")) == "hamfund-the-squire":
				companion["slain"] = true
		text = "Eurekia consequence 1: Hamfund is slain and Eurekia vanishes forever."
	data["inventory"] = items
	var report := SDK.ActionLogMessage.new("Eurekia")
	report.text = [SDK.ActionLogText.new(text)]
	if not context.commit([SDK.ActorChange.new(source.id, data)], report).ok:
		return false
	source.data = data
	return true
