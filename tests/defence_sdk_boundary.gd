extends "res://tests/melee_sdk_boundary.gd"

var sessions := [{"participant_id": "gm", "session_id": "gm-session", "is_gm": true}, {"participant_id": "player", "session_id": "player-session", "is_gm": false}]

func _init() -> void:
	participant = "gm"
	session = "gm-session"
	game_master = true
	targets = PackedStringArray(["hero-rook"])
	actors.hero.data["name"] = "Graveworm"
	actors.hero.data["hit_points"] = 7
	actors.hero.data.abilities["Agility"] = {"modifier": 0}
	actors.enemy.data["definition_id"] = "seth-goblin"
	actors.enemy.data["attacks"] = [{"id": "knife", "name": "Knife", "dice": "d4", "range_feet": 5, "defence_dr": 14}]
	access_entries = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}]

func as_player() -> void:
	participant = "player"
	session = "player-session"
	game_master = false

func SystemIntentReadActor(token: String, id: String) -> Dictionary:
	var result := super.SystemIntentReadActor(token, id)
	if result.ok:
		result.value.access_level = "Owner" if game_master or id == "hero" else "None"
	return result

func SystemIntentActorAccess(_token: String, id: String) -> Dictionary:
	return {"ok": true, "value": access_entries if id == "hero" else []}

func SystemIntentParticipantSessions(_token: String) -> Dictionary:
	return {"ok": active, "value": sessions.duplicate(true)}
