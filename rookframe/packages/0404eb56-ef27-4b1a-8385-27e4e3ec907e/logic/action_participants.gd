extends RefCounted
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

func owner(context: SDK.SystemActionContext, caller: Dictionary, source: SDK.ActorId) -> Dictionary:
	var owner := {"id": str(caller.participant_id), "session": str(caller.session_id)}
	if caller.is_gm:
		var access := context.actor_access(source)
		if not access.ok:
			return {"error": access.message}
		var count := 0
		for entry in access.items:
			if entry.access_level == "Owner":
				count += 1
				if not entry.is_connected:
					return {"error": "This Character’s Player is not connected."}
				owner = {"id": entry.participant_id, "session": entry.session_id}
		if count > 1:
			return {"error": "Several Players own this Character. The responsible Player starts the action from their sheet."}
	return owner

func alive(context: SDK.SystemActionContext, action: Dictionary) -> bool:
	var sessions := context.participant_sessions()
	if not sessions.ok:
		return false
	var resister := not action.has("resister_session")
	var initiator := false
	var owner := false
	var owner_is_gm := false
	var participants: Array = sessions.value
	for raw in participants:
		var session: Dictionary = raw
		if session.session_id == action.get("resister_session", ""):
			resister = true
		if session.participant_id == action.participant and session.session_id == action.session:
			initiator = true
		if session.participant_id == action.owner and session.session_id == action.owner_session:
			owner = true
			owner_is_gm = session.is_gm
	if not initiator or not owner or not resister:
		return false
	var source := context.read_actor(SDK.ActorId.new(str(action.source)))
	if not source.ok:
		return false
	if owner_is_gm:
		return true
	var caller := context.caller()
	var info: Dictionary = caller.value
	if str(info.participant_id) == str(action.owner) and str(info.session_id) == str(action.owner_session):
		return source.actor.access_level == "Owner"
	var access := context.actor_access(SDK.ActorId.new(str(action.source)))
	if not access.ok:
		return false
	for entry in access.items:
		if entry.participant_id == action.owner and entry.access_level == "Owner" and entry.is_connected and entry.session_id == action.owner_session:
			return true
	return false
