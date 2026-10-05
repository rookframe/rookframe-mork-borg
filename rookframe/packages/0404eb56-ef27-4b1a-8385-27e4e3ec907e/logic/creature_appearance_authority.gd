extends RefCounted
## Appearance commits independently against current accepted Creature/World data.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")

func handle(context: SDK.SystemActionContext, sdk: SDK, operation: String, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("Appearance choices are malformed.")
	var input: Dictionary = payload
	if operation == "creature-appearance.default-portrait":
		return _default_portrait(context, sdk, input)
	if operation not in ["creature-appearance.portrait", "creature-appearance.miniature"]:
		return _error("Choose a supported Appearance operation.")
	var id := SDK.ActorId.new(str(input.get("actor", "")))
	var current := context.read_actor(id)
	if not current.ok or current.actor == null:
		return _error(current.message)
	if current.actor.access_level != "Owner":
		return _error("Owner access is required to change this Creature’s appearance.")
	var data: Dictionary = current.actor.data
	if str(data.get("schema", "")) != "mork-borg-adversary/v1":
		return _error("Creature data is unavailable.")
	# Freeze legacy effective capabilities on the first accepted appearance write.
	data = CREATURES.new().stat_block(data)
	if operation == "creature-appearance.portrait":
		if typeof(input.get("expected")) != TYPE_STRING or typeof(input.get("expected_revision")) != TYPE_INT or data.get("portrait", "") != input.expected or int(data.get("portrait_revision", 0)) != input.expected_revision:
			return _error("Portrait changed. Choose it again.")
		var portrait := _portrait(sdk, input.get("path"))
		if not portrait.ok:
			return portrait
		var path: String = portrait.path
		if path.is_empty():
			data.erase("portrait")
		else:
			data["portrait"] = path
		data["portrait_revision"] = int(input.expected_revision) + 1
	else:
		if typeof(input.get("reference")) != TYPE_DICTIONARY:
			return _error("Choose a Miniature.")
		var reference: Dictionary = input.reference
		var package_id := str(reference.get("package_id", ""))
		var local_id := str(reference.get("local_id", ""))
		if not package_id.is_empty() or not local_id.is_empty():
			var found := sdk.content.read(SDK.ContentReference.new(package_id, local_id))
			if not found.ok or not found.content_entry.available or found.content_entry.kind != SDK.ContentKind.Value.MINIATURE:
				return _error("This Miniature is unavailable. Choose another.")
		data["preferred_miniature"] = {} if package_id.is_empty() and local_id.is_empty() else {"package_id": package_id, "local_id": local_id}
	var committed := context.commit([SDK.ActorChange.new(id, data)])
	if not committed.ok:
		return _error(committed.message)
	var accepted := context.read_actor(id)
	if not accepted.ok or accepted.actor == null:
		return _error(accepted.message)
	var actor := accepted.actor
	return {"ok": true, "state": "resolved", "value": {"id": actor.id.value, "data": actor.data, "access_level": actor.access_level, "public_label": actor.public_label}}

func _default_portrait(context: SDK.SystemActionContext, sdk: SDK, input: Dictionary) -> Dictionary:
	var caller := context.caller()
	var identity: Dictionary = caller.value if caller.ok else {}
	if not caller.ok or not bool(identity.get("is_gm", false)):
		return _error("Only the GM changes library appearance.")
	var definition := str(input.get("definition", ""))
	if not CREATURES.CORE_DEFINITIONS.has(definition):
		return _error("Choose a Creature definition.")
	var portrait := _portrait(sdk, input.get("path"))
	if not portrait.ok:
		return portrait
	var saved := context.read_world_data()
	if not saved.ok:
		return _error(saved.message)
	if saved.value != null and typeof(saved.value) != TYPE_DICTIONARY:
		return _error("Appearance defaults are unavailable.")
	var world: Dictionary = {} if saved.value == null else saved.value.duplicate(true)
	if typeof(world.get("creature_portraits", {})) != TYPE_DICTIONARY or typeof(world.get("creature_portrait_revisions", {})) != TYPE_DICTIONARY:
		return _error("Appearance defaults are unavailable.")
	var defaults: Dictionary = world.get("creature_portraits", {}).duplicate(true)
	var revisions: Dictionary = world.get("creature_portrait_revisions", {}).duplicate(true)
	if typeof(input.get("expected")) != TYPE_STRING or typeof(input.get("expected_revision")) != TYPE_INT or defaults.get(definition, "") != input.expected or int(revisions.get(definition, 0)) != input.expected_revision:
		return _error("Portrait changed. Choose it again.")
	var path: String = portrait.path
	if path.is_empty():
		defaults.erase(definition)
	else:
		defaults[definition] = path
	world["creature_portraits"] = defaults
	revisions[definition] = int(input.expected_revision) + 1
	world["creature_portrait_revisions"] = revisions
	var committed := context.commit_world_data(world)
	return {"ok": true, "state": "resolved", "message": "Library portrait saved."} if committed.ok else _error(committed.message)

func _portrait(sdk: SDK, value: Variant) -> Dictionary:
	if typeof(value) != TYPE_STRING:
		return _error("Choose a portrait image.")
	var path: String = value
	if path.is_empty():
		return {"ok": true, "path": path}
	var decoded := sdk.portraits.decode(path)
	return {"ok": true, "path": decoded.path} if decoded.ok else _error(decoded.message)

func _error(message: String) -> Dictionary:
	return {"ok": false, "state": "error", "message": message}
