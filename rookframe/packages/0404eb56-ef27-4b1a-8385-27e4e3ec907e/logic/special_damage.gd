extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATURE_ITEMS = preload(ROOT + "logic/creature_actions.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")

func plan(actor: SDK.Actor, faces: int, infection: bool) -> Dictionary:
	var data: Dictionary = actor.data
	if typeof(data.get("hit_points")) != TYPE_INT:
		return {"error": "Recipient HP is malformed."}
	var protection := ""
	var shield := 0
	var shield_id := ""
	if str(data.get("schema", "")) == "mork-borg-adversary/v1" and not data.get("creature_inventory", false):
		if typeof(data.get("armor", {})) != TYPE_DICTIONARY:
			return {"error": "Recipient armor is malformed."}
		var armor: Dictionary = data.get("armor", {})
		protection = str(armor.get("reduction", ""))
	else:
		if typeof(data.get("inventory", [])) != TYPE_ARRAY:
			return {"error": "Recipient equipment is malformed."}
		for raw in ITEMS.new(null, actor.id).inventory(data):
			var item: Dictionary = raw
			var quantity: int = item.get("quantity", 0)
			if not item.get("equipped", false) or item.get("broken", false) or quantity < 1:
				continue
			if str(item.get("kind", "")) == "Armor":
				protection = str(item.get("reduction", ""))
			if str(item.get("kind", "")) == "Shield":
				shield = 1
				shield_id = str(item.inventory_id)
	if not protection in ["", "d2", "d4", "d6", "d8", "d10", "d12"]:
		return {"error": "Recipient protection dice are unsupported."}
	return {"faces": faces, "protection": protection, "shield": shield, "shield_id": shield_id, "infection": infection, "bonus": 0, "critical": false}

func terms(plan: Dictionary) -> Array[SDK.DiceTerm]:
	var damage_faces: int = plan.faces
	var result: Array[SDK.DiceTerm] = [SDK.DiceTerm.new("Damage", damage_faces)]
	if not str(plan.protection).is_empty():
		var faces: int = {"d2": 4, "d4": 4, "d6": 6, "d8": 8, "d10": 10, "d12": 12}.get(str(plan.protection), 0)
		result.append(SDK.DiceTerm.new("Protection", 4 if faces == 2 else faces))
	if plan.infection:
		result.append(SDK.DiceTerm.new("Infection chance", 6))
	return result

func apply(actor: SDK.Actor, plan: Dictionary, roll: SDK.HumanThrowResult) -> Dictionary:
	var current: Dictionary = actor.data
	if typeof(current.get("hit_points")) != TYPE_INT:
		return {"error": "Recipient HP is malformed."}
	var data := current.duplicate(true)
	var bonus: int = plan.bonus
	var damage := roll.terms[0].results[0] + bonus
	if plan.critical:
		damage *= 2
	var protection := 0
	if not str(plan.protection).is_empty():
		protection = roll.terms[1].results[0]
		if str(plan.protection) == "d2":
			protection = int((protection + 1) / 2)
	var shield: int = plan.shield
	var loss := damage - protection - shield
	if loss < 0:
		loss = 0
	var hp: int = data.hit_points
	data["hit_points"] = hp - loss
	if plan.critical:
		CREATURE_ITEMS.new(null, actor.id).damage_armor(data)
	var text := "d2 protection uses a physical d4 halved, rounded up." if str(plan.protection) == "d2" else ""
	if plan.infection and roll.terms[-1].results[0] == 1:
		text += " Infection; handle this condition manually."
	return {"data": data, "loss": loss, "text": text}

func damage_armor(id: SDK.ActorId, data: Dictionary) -> void:
	CREATURE_ITEMS.new(null, id).damage_armor(data)
