extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")

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
