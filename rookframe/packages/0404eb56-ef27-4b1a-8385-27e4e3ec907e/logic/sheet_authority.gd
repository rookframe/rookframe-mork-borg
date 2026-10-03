extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/character_edits.gd")

func handle(context: SDK.SystemActionContext, sdk: SDK, name: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Character choices are malformed."}
	var input: Dictionary = payload
	var actions := ACTIONS.new(SDK.ActorId.new(str(input.get("actor", ""))), context)
	var result: SDK.ActorResult
	if name == "sheet.identify":
		if typeof(input.get("companions", [])) != TYPE_ARRAY:
			return {"ok": false, "message": "Companion identities are malformed."}
		var companions: Array[String] = []
		var requested: Array = input.get("companions", [])
		for id in requested:
			companions.append(str(id))
		result = await actions.prepare_favorites(companions)
	elif name == "sheet.favorite":
		if typeof(input.get("starred")) != TYPE_BOOL:
			return {"ok": false, "message": "Choose a favorite state."}
		result = await actions.set_favorite(str(input.get("key", "")), input.starred)
	elif name == "sheet.correct":
		if typeof(input.get("fields")) != TYPE_ARRAY or typeof(input.get("entry_ids", [])) != TYPE_ARRAY:
			return {"ok": false, "message": "Character corrections must be text fields."}
		var fields: Dictionary = {}
		var corrections: Array = input.get("fields", [])
		for raw in corrections:
			if typeof(raw) != TYPE_DICTIONARY:
				return {"ok": false, "message": "Character corrections must be text fields."}
			var correction: Dictionary = raw
			if typeof(correction.get("field")) != TYPE_STRING or typeof(correction.get("text")) != TYPE_STRING:
				return {"ok": false, "message": "Character corrections must be text fields."}
			fields[str(correction.field)] = str(correction.text)
		var identities: Dictionary = {}
		var entries: Array = input.get("entry_ids", [])
		for raw in entries:
			if typeof(raw) != TYPE_DICTIONARY:
				return {"ok": false, "message": "Character entry identities are malformed."}
			var entry: Dictionary = raw
			identities[str(entry.get("entry", ""))] = str(entry.get("identity", ""))
		result = await actions.correct_many(fields, identities)
	elif name == "sheet.omens":
		result = await actions.adjust_omens(int(input.get("delta", 0)))
	elif name == "sheet.miniature":
		if typeof(input.get("reference")) != TYPE_DICTIONARY:
			return {"ok": false, "message": "Choose a Miniature."}
		var reference: Dictionary = input.reference
		if not str(reference.get("package_id", "")).is_empty() or not str(reference.get("local_id", "")).is_empty():
			var found := sdk.content.read(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))))
			if not found.ok or not found.content_entry.available or found.content_entry.kind != SDK.ContentKind.Value.MINIATURE:
				return {"ok": false, "message": "This Miniature is unavailable. Choose another."}
		result = await actions.set_miniature(reference)
	elif name == "sheet.portrait":
		if typeof(input.get("image")) != typeof(PackedByteArray()):
			return {"ok": false, "message": "Choose a portrait image."}
		result = await actions.set_portrait(input.image)
	elif name == "sheet.add":
		result = await actions.add_equipment(str(input.get("source", "")))
	elif name == "sheet.custom":
		if typeof(input.get("fields")) != TYPE_DICTIONARY:
			return {"ok": false, "message": "Item fields are malformed."}
		var submitted: Dictionary = input.fields
		var fields: Dictionary = {}
		for field in ["name", "kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			if submitted.get(str(field)) != null:
				fields[str(field)] = str(submitted.get(str(field)))
		result = await actions.add_custom(fields)
	elif name == "sheet.item":
		result = await actions.change_item(str(input.get("item", "")), str(input.get("field", "")), str(input.get("text", "")))
	elif name == "sheet.remove":
		result = await actions.remove_item(str(input.get("item", "")))
	else:
		return {"ok": false, "message": "Unknown Character action."}
	if not result.ok:
		return {"ok": false, "state": "error", "message": result.message, "field": actions.invalid_field}
	var actor := result.actor
	return {"ok": true, "state": "resolved", "value": {"id": actor.id.value, "data": actor.data, "access_level": actor.access_level, "public_label": actor.public_label}}
