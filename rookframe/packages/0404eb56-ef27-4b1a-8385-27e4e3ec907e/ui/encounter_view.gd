extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const RULES = preload(ROOT + "logic/encounter_authority.gd")
const PORTRAITS = preload(ROOT + "ui/encounter_portraits.gd")
const FALLBACK = preload("res://rookframe/ui/icons/person.svg")

func snapshot(sdk: SDK) -> Dictionary:
	var result := sdk.world_data.read()
	if not result.ok:
		return {"error": result.message}
	var world: Dictionary = {} if result.value == null else result.value
	var state: Dictionary = world.get("encounter", RULES.new().empty()).duplicate(true)
	var actors := sdk.actors.list()
	if not actors.ok:
		return {"error": actors.message}
	var context := sdk.context()
	var rows: Array = []
	var entries: Array = state.entries
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var label := "Unavailable Actor"
		var can_open := false
		var suggested: Texture2D
		var portrait: Texture2D = entry.get("portrait", FALLBACK)
		for actor in actors.items:
			if actor.id.value != str(entry.actor):
				continue
			var data: Dictionary = actor.data
			if context.is_gm:
				suggested = PORTRAITS.CREATURES.get(str(data.get("definition_id", "")))
			can_open = actor.access_level in ["Viewer", "Owner"]
			label = str(data.get("name", "Actor")) if context.is_gm or can_open else (actor.public_label if not actor.public_label.is_empty() else "Creature")
			if not entry.has("portrait") and can_open and data.get("portrait") is Texture2D:
				portrait = data.portrait
		rows.append({"actor": str(entry.actor), "label": label, "portrait": portrait, "suggested_portrait": suggested, "can_open": can_open, "initiative": entry.initiative, "side": str(entry.side), "active": bool(state.active) and state.current == entry.actor})
	state["rows"] = rows
	state["is_gm"] = context.is_gm
	return state
