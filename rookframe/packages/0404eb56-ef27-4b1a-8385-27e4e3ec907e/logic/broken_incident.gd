extends RefCounted

## The approved Broken incident only. Values belong to the shared Actor.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")

func sync(previous: Dictionary, current: Dictionary) -> Dictionary:
	var data := current.duplicate(true)
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return data
	var hp := int(data.get("hit_points", 1))
	var old_hp := int(previous.get("hit_points", 1))
	var incident: Dictionary = data.get("broken_incident", {})
	if hp == 0 and (old_hp > 0 or incident.is_empty()):
		var serial := int(data.get("broken_serial", 0)) + 1
		data["broken_serial"] = serial
		incident = {"id": serial, "outcome": 0, "elapsed": 0, "recovered": false, "treated": false, "dead": false}
	elif hp < 0:
		if incident.is_empty():
			incident = {"id": int(data.get("broken_serial", 0)), "outcome": 4, "elapsed": 0}
		incident["dead"] = true
		incident["negative_hp"] = true
	elif hp > 0 and not incident.is_empty():
		if incident.get("dead", false):
			if hp != old_hp:
				data.erase("broken_incident")
			return data
		if int(incident.get("outcome", 0)) == 3:
			# Recording external healing is distinct from recording treatment.
			incident["negative_hp"] = false
		elif int(incident.get("outcome", 0)) in [1, 2]:
			incident["recovered"] = true
			incident["dead"] = false
		else:
			data.erase("broken_incident")
			return data
	if not incident.is_empty():
		data["broken_incident"] = incident

	return data

func is_dead(data: Dictionary) -> bool:
	if int(data.get("hit_points", 1)) < 0:
		return true
	var incident: Dictionary = data.get("broken_incident", {})
	return bool(incident.get("dead", false))

func can_act(data: Dictionary) -> bool:
	if is_dead(data):
		return false
	var incident: Dictionary = data.get("broken_incident", {})
	return not (int(incident.get("outcome", 0)) in [1, 2] and not incident.get("recovered", false))

func can_complete_followup(data: Dictionary) -> bool:
	var incident: Dictionary = data.get("broken_incident", {})
	if is_dead(data) or incident.has("followup_sequence"):
		return false
	var outcome := int(incident.get("outcome", 0))
	if outcome == 3:
		return not incident.get("treated", false)
	return outcome in [1, 2] and int(data.get("hit_points", 1)) == 0 and not incident.get("recovered", false)

func commit(context: SDK.SystemActionContext, changes: Array[SDK.ActorChange], report: SDK.ActionLogMessage = null) -> SDK.OperationResult:
	var prepared: Array[SDK.ActorChange] = []
	for change in changes:
		if typeof(change.data) != TYPE_DICTIONARY:
			prepared.append(change)
			continue
		var source := context.read_actor(change.actor)
		if source.ok and typeof(source.actor.data) == TYPE_DICTIONARY:
			prepared.append(SDK.ActorChange.new(change.actor, sync(source.actor.data, change.data)))
		else:
			prepared.append(change)
	return context.commit(prepared, report)

func advance(current: Dictionary, operation: String) -> Dictionary:
	var data := current.duplicate(true)
	var incident: Dictionary = data.get("broken_incident", {})
	if incident.is_empty() or int(incident.get("outcome", 0)) == 0:
		return {"message": "Resolve this Broken incident first."}
	if not incident.has("followup_sequence"):
		return {"message": "Complete the retained Broken outcome’s follow-up dice first."}
	var outcome := int(incident.outcome)
	var elapsed := int(incident.get("elapsed", 0))
	var duration := int(incident.get("duration", 0))
	if operation == "treat":
		if outcome != 3 or incident.get("dead", false) or incident.get("treated", false):
			return {"message": "Treatment is unavailable for this incident."}
		incident["treated"] = true
	elif operation == "recover":
		if outcome not in [1, 2] or elapsed < duration or incident.get("recovered", false) or incident.get("dead", false):
			return {"message": "Recovery is not due."}
		incident["recovered"] = true
		data["hit_points"] = int(incident.recovery_hp)
	elif operation in ["next", "undo"]:
		if outcome not in [1, 2, 3] or incident.get("recovered", false) or incident.get("treated", false) or incident.get("negative_hp", false):
			return {"message": "This incident has no running counter."}
		if operation == "next" and elapsed >= duration or operation == "undo" and elapsed == 0:
			return {"message": "The counter is already at its boundary."}
		incident["elapsed"] = elapsed + (1 if operation == "next" else -1)
		if outcome == 3:
			incident["dead"] = int(incident.elapsed) >= duration
	else:
		return {"message": "Choose a supported Broken event."}
	data["broken_incident"] = incident
	return {"message": "", "data": data}
