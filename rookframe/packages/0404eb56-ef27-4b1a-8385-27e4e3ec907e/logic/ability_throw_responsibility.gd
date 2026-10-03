extends RefCounted

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

## Resolve the existing Requested Throw responsibility for sheet or tabletop input.
func resolve(facade: SDK, actor: SDK.ActorId, sheet: bool = false) -> Dictionary:
	var context: SDK.WorldContext = facade.context()
	if not context.ok:
		return {"ok": false, "message": context.message}
	var participant := context.participant_id
	if context.is_gm and not sheet:
		var access: SDK.ActorAccessListResult = facade.actors.access(actor)
		if not access.ok:
			return {"ok": false, "message": access.message}
		var owners: Array[SDK.ActorAccessEntry] = []
		for entry in access.items:
			if entry.access_level == "Owner":
				owners.append(entry)
		if owners.size() > 1:
			return {"ok": false, "message": "Several Players own this Character. The responsible Player can roll from their sheet."}
		if owners.size() == 1:
			if not owners[0].is_connected:
				return {"ok": false, "message": "This Character’s Player is not connected."}
			participant = owners[0].participant_id
	return {"ok": true, "participant_id": participant}
