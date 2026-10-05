extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const REQUEST = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/action_request.gd")

## Creature inventory is carried loot. Snapshot an older Actor's effective
## capabilities before editing its saved items through the ordinary SDK.
func _read() -> SDK.ActorResult:
	var result := super._read()
	if not result.ok:
		return result
	var current: Dictionary = result.actor.data
	if str(current.get("schema", "")) != "mork-borg-adversary/v1":
		return _failure("Creature data is unavailable.")
	result.actor.data = CREATURES.new().stat_block(current)
	return result

func change_item(id: String, field: String, text: String) -> SDK.ActorResult:
	if field == "equipped":
		return _failure("Creature loot has no equipment state.")
	return await super.change_item(id, field, text)

func set_portrait(image: PackedByteArray) -> SDK.ActorResult:
	return await _appearance("portrait", {"image": image})

func set_miniature(reference: Dictionary) -> SDK.ActorResult:
	return await _appearance("miniature", {"reference": reference})

func _appearance(operation: String, payload: Dictionary) -> SDK.ActorResult:
	payload["actor"] = _id.value
	var response := await _sdk.system_actions.submit("creature-appearance." + operation, payload)
	return SDK.ActorResult.new(response.value) if response.ok else _failure(response.message)

func prepare_corrections() -> SDK.ActorResult:
	return await _submit_corrections("prepare", {})

func correct_many(fields: Dictionary, entry_ids: Dictionary = {}) -> SDK.ActorResult:
	var corrections: Array = []
	for field in fields.keys():
		corrections.append({"field": str(field), "text": fields.get(str(field))})
	var identities: Array = []
	for entry in entry_ids.keys():
		identities.append({"entry": str(entry), "identity": str(entry_ids.get(str(entry)))})
	return await _submit_corrections("correct", {"fields": corrections, "entry_ids": identities})

func _submit_corrections(operation: String, payload: Dictionary) -> SDK.ActorResult:
	payload["actor"] = _id.value
	var response := await _sdk.system_actions.submit("creature." + operation, payload)
	invalid_field = ""
	if not response.ok:
		return _failure(response.message)
	var result: Dictionary = response.value
	invalid_field = str(result.get("field", ""))
	return SDK.ActorResult.new(result)

## Keep id and choices unchanged when retrying a relative adjustment.
func adjust_health(id: String, operation: String, amount: String, transport: REQUEST = null) -> SDK.ActorResult:
	var payload := {"id": id, "actor": _id.value, "operation": operation, "amount": amount}
	var response: SDK.DataResult = await _sdk.system_actions.submit("creature-health.adjust", payload) if transport == null else await transport.submit("creature-health.adjust", payload)
	invalid_field = ""
	if not response.ok:
		return _failure(response.message)
	var result: Dictionary = response.value
	invalid_field = str(result.get("field", ""))
	return SDK.ActorResult.new(result)
