extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const STRIP = preload(ROOT + "ui/encounter_strip_base.gd")
const RULES = preload(ROOT + "logic/encounter_authority.gd")

func snapshot(sdk: SDK) -> Dictionary:
	var result := sdk.world_data.read()
	if not result.ok:
		return {"error": result.message}
	var world: Dictionary = {} if result.value == null else result.value
	var state: Dictionary = world.get("encounter", RULES.new().empty()).duplicate(true)
	var actors := sdk.actors.list()
	var rooks := sdk.rooks.list()
	if not actors.ok or not rooks.ok:
		return {"error": actors.message if not actors.ok else rooks.message}
	var context := sdk.context()
	var rows: Array = []
	var entries: Array = state.entries
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var row := {"actor": str(entry.actor), "rook": str(entry.rook), "label": "Unavailable Rook", "kind": "", "miniature": "", "side": str(entry.side), "active": bool(state.active) and (state.current == "first" if bool(entry.always_first) else state.current == entry.side), "available": false}
		var exists := false
		for rook in rooks.items:
			if rook.id.value == str(entry.rook):
				exists = true
			if rook.id.value != str(entry.rook) or rook.actor == null or rook.actor.value != str(entry.actor):
				continue
			row.miniature = rook.miniature.package_id + ":" + rook.miniature.local_id
			for actor in actors.items:
				if actor.id.value != str(entry.actor):
					continue
				var data: Dictionary = actor.data
				var readable := context.is_gm or actor.access_level in ["Viewer", "Owner"]
				row.label = str(data.get("name", "Actor")) if readable else (actor.public_label if not actor.public_label.is_empty() else "Creature")
				row.kind = str(data.get("kind", data.get("type", ""))) if readable else ""
				row.available = true
		if exists:
			rows.append(row)
	state["rows"] = rows
	state["is_gm"] = context.is_gm
	return state

func show_preview(sdk: SDK, target: Control, row: Dictionary) -> void:
	var shown := sdk.rooks.preview(SDK.RookId.new(str(row.rook)), target).ok
	var fallback := target.get_node("Fallback") as TextureRect
	fallback.visible = not shown

func surface(sdk: SDK) -> SDK.ExtensionSurface:
	var result := SDK.ExtensionSurface.new()
	result.scene = load(ROOT + "ui/encounter_window.tscn")
	var experience := sdk.presentation_experience()
	result.initial_dock_width = 375 if experience.is_phone else 412
	if experience.is_desktop:
		result.initial_placement = "floating"
		result.initial_floating_rect = Rect2(1456, 220, 400, 292)
	return result

func local_state(owner: Node):
	var strip = owner.get_tree().get_first_node_in_group("mork-borg-0404eb56-encounter-view") as STRIP
	return strip.encounter_view_state()
