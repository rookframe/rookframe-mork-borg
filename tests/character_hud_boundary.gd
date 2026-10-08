extends "res://tests/miniature_boundary.gd"

var hud_actor := "hero"
var dice_opened := 0

func CharacterHudContext() -> Dictionary:
	return {"ok": true, "value": {"actor_id": hud_actor, "rook_id": selected_rook}}

func OpenDiceTray() -> Dictionary:
	dice_opened += 1
	return {"ok": true}
