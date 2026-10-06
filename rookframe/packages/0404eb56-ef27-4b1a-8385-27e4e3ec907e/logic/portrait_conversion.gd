extends RefCounted
## Convert saved inline portraits into retained files before Authority startup.
## Return copies; the host commits one candidate only after every callback succeeds.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")

func actor_data(sdk: SDK, value: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		return value
	var data: Dictionary = value
	if str(data.get("schema", "")) not in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
		return value
	if typeof(data.get("portrait")) != typeof(PackedByteArray()):
		return value
	var retained := _retain(sdk, data.portrait)
	if not retained.ok:
		push_error("Saved portrait conversion failed: " + str(retained.message))
		return value
	var replacement := data.duplicate(true)
	var path: String = retained.path
	if path.is_empty():
		replacement.erase("portrait")
	else:
		replacement["portrait"] = path
	return replacement

func world_data(sdk: SDK, value: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		return value
	var data: Dictionary = value
	if typeof(data.get("creature_portraits")) != TYPE_DICTIONARY:
		return value
	var replacement := data.duplicate(true)
	var original_defaults: Dictionary = data.creature_portraits
	var defaults := original_defaults.duplicate(true)
	for definition in defaults.keys():
		if typeof(definition) != TYPE_STRING:
			continue
		var key: String = definition
		var saved_portrait: Variant = defaults.get(key)
		if typeof(saved_portrait) != typeof(PackedByteArray()):
			continue
		var retained := _retain(sdk, saved_portrait)
		if not retained.ok:
			push_error("Saved portrait conversion failed: " + str(retained.message))
			return value
		var path: String = retained.path
		if path.is_empty():
			defaults.erase(key)
		else:
			defaults[key] = path
	replacement["creature_portraits"] = defaults
	return replacement

func _retain(sdk: SDK, image: PackedByteArray) -> Dictionary:
	if image.is_empty():
		return {"ok": true, "path": ""}
	var retained := sdk.portraits.retain(image)
	if not retained.ok:
		return {"ok": false, "message": retained.message}
	if retained.path.is_empty():
		return {"ok": false, "message": "Portrait retention returned no filepath."}
	return {"ok": true, "path": retained.path}
