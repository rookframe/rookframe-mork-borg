extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"
## Character mutations submit semantic choices; Authority reads the current Actor.

func correct(field: String, text: String) -> SDK.ActorResult:
	var fields: Dictionary = {}
	fields[field] = text
	return await correct_many(fields)

func correct_many(fields: Dictionary, entry_ids: Dictionary = {}) -> SDK.ActorResult:
	var corrections: Array = []
	for field in fields.keys():
		corrections.append({"field": str(field), "text": fields.get(str(field))})
	var identities: Array = []
	for entry in entry_ids.keys():
		identities.append({"entry": str(entry), "identity": str(entry_ids.get(str(entry)))})
	return await _submit("correct", {"fields": corrections, "entry_ids": identities})

func spend_omen() -> SDK.ActorResult:
	return await adjust_omens(-1)

func adjust_omens(delta: int) -> SDK.ActorResult:
	return await _submit("omens", {"delta": delta})

func set_portrait(image: PackedByteArray) -> SDK.ActorResult:
	return await _submit("portrait", {"image": image})

func prepare_favorites(companions: Array[String] = []) -> SDK.ActorResult:
	return await _submit("identify", {"companions": companions})

func set_favorite(key: String, starred: bool) -> SDK.ActorResult:
	return await _submit("favorite", {"key": key, "starred": starred})

func add_equipment(source_id: String) -> SDK.ActorResult:
	return await _submit("add", {"source": source_id})

func add_custom(fields: Dictionary) -> SDK.ActorResult:
	return await _submit("custom", {"fields": fields})

func change_item(id: String, field: String, text: String) -> SDK.ActorResult:
	return await _submit("item", {"item": id, "field": field, "text": text})

func remove_item(id: String) -> SDK.ActorResult:
	return await _submit("remove", {"item": id})

func set_miniature(reference: Dictionary) -> SDK.ActorResult:
	return await _submit("miniature", {"reference": reference})

func _submit(operation: String, payload: Dictionary) -> SDK.ActorResult:
	payload["actor"] = _id.value
	var response := await _sdk.system_actions.submit("sheet." + operation, payload)
	invalid_field = ""
	if not response.ok:
		return _failure(response.message)
	var result: Dictionary = response.value
	invalid_field = str(result.get("field", ""))
	return SDK.ActorResult.new(result)
