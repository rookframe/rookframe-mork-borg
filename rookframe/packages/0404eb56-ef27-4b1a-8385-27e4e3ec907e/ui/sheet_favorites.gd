extends RefCounted
## Sheet composition for the same Actor Favorite model consumed by the HUD.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const MODEL = preload(ROOT + "logic/actor_favorites.gd")
const STAR_SCRIPT = preload(ROOT + "ui/sheet_favorite.gd")
const COMPANION = preload(ROOT + "ui/sheet_companion_favorite.tscn")
const PROJECTION = preload(ROOT + "ui/sheet_projection.gd")
signal favorite_changed(key: String, starred: bool)
var sdk: SDK
var _model := MODEL.new()

func needs_identity(data: Dictionary) -> bool:
	return _model.needs_identity(data)

func entries(actor: SDK.Actor) -> Array[Dictionary]:
	var actors := sdk.actors.list()
	var companions: Array[SDK.Actor] = actors.items if actors.ok else []
	return _model.entries(actor.data, actor.id.value, companions)

func find(actor: SDK.Actor, key: String) -> Dictionary:
	for entry in entries(actor):
		if str(entry.key) == key:
			return entry
	return {}

func configure(star: STAR_SCRIPT, actor: SDK.Actor, detail: String, busy: bool) -> void:
	var entry: Dictionary = {}
	var data: Dictionary = actor.data
	if detail.begins_with("favorite:"):
		entry = find(actor, detail.trim_prefix("favorite:"))
	elif detail.begins_with("item:"):
		var items: Array = data.get("inventory", [])
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("inventory_id", "")) == detail.trim_prefix("item:"):
				var source := _model.item_entry(item)
				if not source.is_empty():
					entry = find(actor, str(source.key))
	elif detail.begins_with("trait:"):
		var traits: Array = data.get("traits", [])
		var index := int(detail.trim_prefix("trait:"))
		if index >= 0 and index < traits.size():
			var feature: Dictionary = traits[index]
			entry = find(actor, "feature:" + str(feature.get("favorite_entry_id", "")) + ":use")
	star.configure(entry, actor.access_level == "Owner", busy)

func append_missing(rows: Dictionary, actor: SDK.Actor, chapter: int) -> void:
	var companions: Array = rows.companions
	var primary: Array = rows.primary
	for entry in entries(actor):
		if entry.present:
			continue
		var row := PROJECTION.new().row("favorite:" + str(entry.key), str(entry.get("name", "Favorite")), "Unavailable")
		if chapter == 0 and entry.category == "Companions":
			companions.append(row)
		elif chapter == 0 and entry.category == "Features" or chapter == 1 and entry.category == "Powers" or chapter == 2 and entry.category in ["Items", "Attacks"]:
			primary.append(row)

func append_companions(content: Control, actor: SDK.Actor, companion: String, busy: bool) -> void:
	for entry in entries(actor):
		if str(entry.get("actor", "")) != companion:
			continue
		var row = COMPANION.instantiate()
		content.add_child(row)
		row.configure(entry, actor.access_level == "Owner", busy)
		row.favorite_changed.connect(_changed)

func prepare(id: SDK.ActorId) -> SDK.ActorResult:
	var current := sdk.actors.read(id)
	if not current.ok or current.actor.access_level != "Owner":
		return current
	var companions: Array[String] = []
	var listed := sdk.actors.list()
	if listed.ok:
		for actor in listed.items:
			var data: Dictionary = actor.data
			if actor.access_level == "Owner" and str(data.get("schema", "")) == "mork-borg-adversary/v1" and _model.is_companion(current.actor.data, id.value, data) and _model.needs_companion_identity(data):
				companions.append(actor.id.value)
	if needs_identity(current.actor.data) or not companions.is_empty():
		var result := await preload(ROOT + "logic/character_actions.gd").new(sdk, id).prepare_favorites(companions)
		return _latest(id, result)
	return current

func item(actor: SDK.Actor, id: String) -> Dictionary:
	var inventory: Array = MODEL.ITEMS.new(sdk, actor.id).inventory(actor.data)
	for raw in inventory:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == id:
			return item
	return {}

func change(actor: SDK.Actor, key: String, starred: bool) -> SDK.ActorResult:
	var result := await preload(ROOT + "logic/character_actions.gd").new(sdk, actor.id).set_favorite(key, starred)
	return _latest(actor.id, result)

func _latest(id: SDK.ActorId, result: SDK.ActorResult) -> SDK.ActorResult:
	return sdk.actors.read(id) if result.ok else result

func _changed(key: String, starred: bool) -> void:
	favorite_changed.emit(key, starred)
