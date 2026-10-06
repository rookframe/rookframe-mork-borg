extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const EDITS = preload(ROOT + "logic/creature_edits.gd")

func handle(context: SDK.SystemActionContext, name: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Creature choices are malformed."}
	var input: Dictionary = payload
	var actions := EDITS.new(SDK.ActorId.new(str(input.get("actor", ""))), context)
	var result: SDK.ActorResult
	if name == "creature.prepare":
		result = await actions.prepare()
	elif name == "creature.correct":
		if typeof(input.get("fields")) != TYPE_ARRAY or typeof(input.get("entry_ids")) != TYPE_ARRAY:
			return {"ok": false, "message": "Creature corrections must be text fields."}
		var fields: Dictionary = {}
		var corrections: Array = input.get("fields", [])
		for raw in corrections:
			if typeof(raw) != TYPE_DICTIONARY:
				return {"ok": false, "message": "Creature corrections must be text fields."}
			var correction: Dictionary = raw
			if typeof(correction.get("field")) != TYPE_STRING or typeof(correction.get("text")) != TYPE_STRING:
				return {"ok": false, "message": "Creature corrections must be text fields."}
			fields[str(correction.field)] = str(correction.text)
		var identities: Dictionary = {}
		var entries: Array = input.get("entry_ids", [])
		for raw in entries:
			if typeof(raw) != TYPE_DICTIONARY:
				return {"ok": false, "message": "Creature entry identities are malformed."}
			var entry: Dictionary = raw
			if typeof(entry.get("entry")) != TYPE_STRING or typeof(entry.get("identity")) != TYPE_STRING:
				return {"ok": false, "message": "Creature entry identities are malformed."}
			identities[str(entry.entry)] = str(entry.identity)
		result = await actions.correct_many(fields, identities)
	else:
		return {"ok": false, "message": "Unknown Creature correction."}
	if not result.ok:
		return {"ok": false, "state": "error", "message": result.message, "field": actions.invalid_field}
	var actor := result.actor
	return {"ok": true, "state": "resolved", "value": {"id": actor.id.value, "data": actor.data, "access_level": actor.access_level, "public_label": actor.public_label}}
