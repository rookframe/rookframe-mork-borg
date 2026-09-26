extends RefCounted
## World-local defaults never mutate Package Actor Definitions.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")

func handle(context: SDK.SystemActionContext, sdk: SDK, operation: String, payload: Variant) -> Dictionary:
	var caller := context.caller()
	var identity: Dictionary = caller.value if caller.ok else {}
	if not caller.ok or not bool(identity.get("is_gm", false)):
		return _error("Only the GM changes library Miniatures or creates Creatures.")
	if typeof(payload) != TYPE_DICTIONARY:
		return _error("Miniature choices are malformed.")
	var input: Dictionary = payload
	var definition := str(input.get("definition", ""))
	if not CREATURES.CORE_DEFINITIONS.has(definition):
		return _error("Choose a Creature definition.")
	var saved := context.read_world_data()
	if not saved.ok:
		return _error(saved.message)
	if saved.value != null and typeof(saved.value) != TYPE_DICTIONARY:
		return _error("Miniature defaults are unavailable.")
	var world: Dictionary = {} if saved.value == null else saved.value.duplicate(true)
	var defaults: Dictionary = world.get("creature_miniatures", {}).duplicate(true)
	if operation == "miniature.default":
		var package_id := str(input.get("package_id", ""))
		var local_id := str(input.get("local_id", ""))
		var reference: Dictionary = {} if package_id.is_empty() and local_id.is_empty() else {"package_id": package_id, "local_id": local_id}
		if not reference.is_empty() and not _available(sdk, reference):
			return _error("This Miniature is unavailable. Choose another.")
		if reference.is_empty():
			defaults.erase(definition)
		else:
			defaults[definition] = {"package_id": str(reference.package_id), "local_id": str(reference.local_id)}
		world["creature_miniatures"] = defaults
		var result := context.commit_world_data(world)
		return {"state": "resolved", "message": "Library Miniature saved."} if result.ok else _error(result.message)
	if operation == "miniature.create":
		# Snapshot the current World default on Authority, never a client's stale copy.
		var preferred: Dictionary = defaults.get(definition, CREATURES.new().default_miniature(definition)).duplicate(true)
		var created := context.create_actors([{"package_id": sdk.package_id(), "local_id": definition, "choices": {"preferred_miniature": preferred}}], str(identity.get("participant_id", "")))
		if not created.ok:
			return _error(created.message)
		return {"state": "resolved", "actor": created.items[0].id.value, "message": "Creature created."}
	return _error("Choose a supported Miniature operation.")

func _available(sdk: SDK, reference: Dictionary) -> bool:
	var found := sdk.content.read(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))))
	return found.ok and found.content_entry.available and found.content_entry.kind == SDK.ContentKind.Value.MINIATURE

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}
