extends "res://tests/melee_sdk_boundary.gd"

func SelectedRookContext() -> Dictionary:
	return {"id": "hero-rook"}

func ReadActor(id: String) -> Dictionary:
	return SystemIntentReadActor("", id)

func TargetingSnapshot() -> Dictionary:
	return {"ok": true, "value": {"participant_id": participant, "session_id": session, "display_name": "Player", "scene_id": "main", "revision": 1, "rook_ids": targets}}

func ReadPublicIdentity(id: String) -> Dictionary:
	return {"ok": true, "value": {"rookId": id, "label": "Hooded stranger"}}

func RookDistance(from: String, to: String) -> Dictionary:
	return SystemIntentDistance("", from, to)
