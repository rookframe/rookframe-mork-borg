extends RefCounted
## Accepted Creature data projected into short, actionable HUD collections.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const ROLLS = preload(ROOT + "logic/creature_rolls.gd")
const ACTIONS = preload(ROOT + "logic/creature_hud_actions.gd")
const ART = preload(ROOT + "ui/creature_sheet_art.gd")
const PORTRAIT = preload(ROOT + "ui/creature_portrait_cache.gd")
const ICONS := {"Attacks": preload(ROOT + "ui/hud_art/attacks.svg"), "Special": preload(ROOT + "ui/hud_art/features.svg"), "Checks": preload(ROOT + "ui/hud_art/dice.svg"), "Scene": preload(ROOT + "ui/hud_art/people.svg")}
var sdk: SDK
var _favorites: Dictionary = {}
var _portraits: Dictionary = {}

## One escaped stable key per line, local to this Participant's Package files.
func load_preferences() -> void:
	var saved := sdk.files.user.file("creature-hud-favorites.txt").read_text()
	if saved.ok:
		for key in saved.text.split("\n"):
			if not str(key).is_empty():
				_favorites[str(key)] = false

func _favorite_key(data: Dictionary, entry: String) -> String:
	return (str(data.get("definition_id", "")) + ":" + entry).replace("%", "%25").replace("\n", "%0A").replace("\r", "%0D")

func favorite(data: Dictionary, entry: String, enabled: bool) -> SDK.IntegrationResult:
	var key := _favorite_key(data, entry)
	var next := _favorites.duplicate(true)
	if enabled:
		next.erase(key)
	else:
		next[key] = false
	var text := ""
	for name in next.keys():
		text += str(name) + "\n"
	var result := sdk.files.user.file("creature-hud-favorites.txt").write_text(text)
	if result.ok:
		_favorites = next
	return result

func portrait(data: Dictionary) -> Texture2D:
	var reference := str(data.get("portrait", ""))
	if not _portraits.has(reference):
		_portraits[reference] = PORTRAIT.new()
	var cached: PORTRAIT = _portraits.get(reference)
	var texture: Texture2D = cached.resolve(reference, sdk.portraits)
	if texture != null:
		return texture
	var definition := str(data.get("definition_id", ""))
	return ART.new().portrait("lich" if definition == "lich-necromancer" else definition)

func hp(data: Dictionary) -> String:
	return "%s / %s %s" % [str(data.get("hit_points", "—")), str(data.get("maximum_hit_points", "—")), sdk.translations.text("HP")]

func entries(data: Dictionary, category: String, rolling: bool) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	var alive := HEALTH.new().can_roll(data)
	if category == "Attacks":
		for raw in CREATURES.new().attack_options(data):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = raw
			var entry := _entry(str(source.get("id", "")), str(source.get("name", "Attack")), category)
			entry.value = str(source.get("dice", ""))
			entry.available = alive and not ROLLS.new().choice(data, "damage", entry.id).is_empty()
			entry.favorite = _favorites.get(_favorite_key(data, entry.id), true) == true
			if not entry.available:
				entry.detail = sdk.translations.text("Dead" if not alive else "Damage unavailable")
			result.append(entry)
	elif category == "Special":
		for source in ACTIONS.new().specials(data):
			var entry := _entry(str(source.id), str(source.get("name", "Special")), category)
			entry.available = alive
			entry.detail = sdk.translations.text("Resolve at the table" if alive else "Dead")
			result.append(entry)
	elif category == "Checks":
		for part in ["test", "morale", "reaction", "initiative"]:
			var choice := ROLLS.new().choice(data, part, "")
			var label: String = {"test": "Creature test", "morale": "Morale", "reaction": "Reaction", "initiative": "Side initiative"}.get(part)
			var entry := _entry(part, sdk.translations.text(label), category)
			entry.value = str(choice.get("formula", "—"))
			entry.available = alive and not rolling and not choice.is_empty()
			var detail := "Unmodified · choose DR at the table" if part == "test" else "Resolve at the table"
			if part == "morale":
				detail = "No morale test" if choice.is_empty() else sdk.translations.text("Morale %d") % int(choice.morale)
			entry.detail = sdk.translations.text("Dead" if not alive else "Roll in progress" if rolling else detail)
			result.append(entry)
	return result

func roster(selected: SDK.RookId, query: String) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	var scene := sdk.scenes.current()
	var rooks := sdk.rooks.list()
	if not scene.ok or not rooks.ok:
		return result
	for rook in rooks.items:
		if rook.scene.value != scene.scene.id.value or rook.actor == null or (rook.hidden and not sdk.context().is_gm):
			continue
		var actor := sdk.actors.read(rook.actor)
		if not actor.ok or actor.actor.access_level != "Owner" or typeof(actor.actor.data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = actor.actor.data
		if str(data.get("schema", "")) != "mork-borg-adversary/v1":
			continue
		var name := str(data.get("name", "Creature"))
		if not query.strip_edges().is_empty() and not name.to_lower().contains(query.strip_edges().to_lower()):
			continue
		var entry := _entry(rook.id.value, name, "Scene")
		if selected != null and rook.id.value == selected.value:
			entry.detail = sdk.translations.text("Selected")
		entry.value = hp(data)
		entry.icon = portrait(data)
		result.append(entry)
	return result

func _entry(id: String, title: String, category: String) -> ENTRY:
	var entry := ENTRY.new()
	entry.id = id
	entry.title = title
	entry.icon = ICONS.get(category)
	return entry
