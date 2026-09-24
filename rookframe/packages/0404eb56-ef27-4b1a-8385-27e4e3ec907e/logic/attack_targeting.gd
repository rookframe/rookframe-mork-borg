extends RefCounted
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")

## Creature selection/range preparation. Defence and companion resolution use
## the chosen source action; preparation never invents a Creature attack roll.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

func validate_creature(context: SDK.SystemActionContext, input: Dictionary) -> Dictionary:
	for key in ["source", "rook", "attack"]:
		if typeof(input.get(key, "")) != TYPE_STRING:
			return _error("The selected attack is malformed.")
	var caller := context.caller()
	var source := context.read_actor(SDK.ActorId.new(str(input.get("source", ""))))
	if not caller.ok or not source.ok or source.actor.access_level != "Owner":
		return _error("Owner access is required to use this Creature’s attack.")
	if typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Creature data is malformed.")
	var data: Dictionary = source.actor.data
	if str(data.get("schema", "")) != "mork-borg-adversary/v1" or typeof(data.get("attacks", [])) != TYPE_ARRAY:
		return _error("Choose a Creature attack.")
	var selected: Dictionary = {}
	var attacks: Array = CREATURES.new().attack_options(data)
	for raw in attacks:
		if typeof(raw) != TYPE_DICTIONARY:
			return _error("Creature attack data is malformed.")
		var attack: Dictionary = raw
		if str(attack.get("id", "")) == str(input.get("attack", "")) and not str(attack.get("id", "")).is_empty():
			selected = attack
	if selected.is_empty() or typeof(selected.get("range_feet", 0)) != TYPE_INT:
		return _error("Select one attack with an authored range.")
	var quantity: int = selected.get("quantity", 1)
	if typeof(selected.get("equipped", true)) != TYPE_BOOL or not selected.get("equipped", true) or selected.get("broken", false) or quantity < 1:
		return _error("Choose an equipped, usable Creature attack in Inventory.")
	var reach: int = selected.get("range_feet", 0)
	if reach <= 0:
		return _error("Select one attack with an authored range.")
	var rook_id := SDK.RookId.new(str(input.get("rook", "")))
	var rook := context.read_rook(rook_id)
	if not rook.ok or rook.rook.actor == null or rook.rook.actor.value != source.actor.id.value or rook.rook.scene.value != "main":
		return _error("Select this Creature’s source Rook in the current Scene.")
	var values: Dictionary = caller.value
	var targets: PackedStringArray = values.targets
	var outside: Array[String] = []
	var target_count := 0
	var target_actor := ""
	for target_id in targets:
		target_count += 1
		var target_rook := context.read_rook(SDK.RookId.new(target_id))
		if not target_rook.ok or target_rook.rook.actor == null or target_rook.rook.actor.value == source.actor.id.value:
			return _error("Choose a Character or Creature target.")
		target_actor = target_rook.rook.actor.value
		var target := context.read_actor(target_rook.rook.actor)
		if not target.ok or typeof(target.actor.data) != TYPE_DICTIONARY:
			return _error("The target is unavailable.")
		var target_data: Dictionary = target.actor.data
		if not str(target_data.get("schema", "")) in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
			return _error("Choose a Character or Creature target.")
		var distance := context.distance(rook_id, SDK.RookId.new(target_id))
		if not distance.ok:
			return _error(distance.message)
		if distance.distance > float(reach) * 0.3048 + 0.000001:
			outside.append("target %s not in range" % (target.actor.public_label if not target.actor.public_label.is_empty() else "Creature"))
	if not outside.is_empty():
		var report := SDK.ActionLogMessage.new("Attack out of range")
		var message := ""
		for line in outside:
			report.text.append(SDK.ActionLogText.new(line))
			message += ("\n" if not message.is_empty() else "") + line
		report.result = "Stopped"
		report.tone = "attention"
		context.commit([], report)
		return _error(message)
	if target_count != 1:
		return _error("Choose exactly one target. Nothing has been rolled.")
	return {"state": "ready", "message": "Target in range. Attack selected.", "attack": selected.duplicate(true), "target": target_actor}

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}
