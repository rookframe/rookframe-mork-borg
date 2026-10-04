extends RefCounted

## Items and initiating class Features share exact owned Favorite identities.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const FAVORITES = preload(ROOT + "logic/actor_favorites.gd")
const RULES = preload(ROOT + "logic/special_rules.gd")
const SOURCE_ROOKS = preload(ROOT + "logic/source_rooks.gd")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const SURFACE: SDK.ExtensionSurface = preload(ROOT + "ui/hud_special_surface.tres")
const ITEM_ICON = preload("res://rookframe/ui/icons/character/bag.svg")
const FEATURE_ICON = preload("res://rookframe/ui/icons/character/presence.svg")
const FOOD_ICON = preload("res://rookframe/ui/icons/character/food.svg")
const HEALING_ICON = preload("res://rookframe/ui/icons/character/heart.svg")
const ELIXIR_ICON = preload("res://rookframe/ui/icons/character/elixir.svg")
const TORCH_ICON = preload("res://rookframe/ui/icons/character/palms.svg")
const LAB_ICON = preload("res://rookframe/ui/icons/character/herbs.svg")
const VALUES := {"wizard-teeth": "4d6", "abominable-gob-lobber": "PRE · DR8", "book-of-boiling-blood": "1 / day", "speaker-of-truths": "2 / day", "initiate-of-the-invisible-college": "1 / day", "harp": "+d4 reaction", "blasphemous-nechrubel-bible": "1 / day", "wrong-jesus-crucifix": "2d6 ± PRE", "portable-laboratory": "2d8 + d4"}
const DETAILS := {"filthy-fingersmith": "Pockets and locks", "master-of-fate": "Know the right way", "wizard-teeth": "Before battle · four teeth", "harp": "Perform music · reaction bonus", "stolen-mitre": "Stealth · worn outside battle", "list-of-sins": "Reveal evil creatures", "stones-taken-from-thel-emas-lost-temple": "Read adjacent-room danger", "wrong-jesus-crucifix": "Eligible creature · Morale", "portable-laboratory": "Prepare two recipes · shared doses"}
var _sdk: SDK

func bind(facade: SDK) -> void:
	_sdk = facade

func entries(actor: SDK.Actor, category: String = "Items") -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	if actor == null or not category in ["Items", "Features"]:
		return result
	var responsible: bool = actor.access_level == "Owner" and RESPONSIBILITY.new().resolve(_sdk, actor.id).get("ok", false)
	for source in FAVORITES.new().entries(actor.data, actor.id.value):
		if str(source.get("category", "")) != category:
			continue
		var entry := ENTRY.new()
		entry.id = str(source.key)
		entry.title = str(source.name) if FAVORITES.new().uses_literal_name(source) else _sdk.translations.text(str(source.get("name", "Item" if category == "Items" else "Feature")))
		var presentation := _presentation(actor, source)
		entry.detail = presentation.detail
		entry.value = presentation.value
		entry.icon = presentation.icon
		entry.favorite = source.get("starred", false)
		entry.available = responsible and source.get("available", false)
		result.append(entry)
	return result

func launch(actor: SDK.ActorId, key: String) -> void:
	var current := _sdk.actors.read(actor)
	if not current.ok or current.actor.access_level != "Owner" or not RESPONSIBILITY.new().resolve(_sdk, actor).get("ok", false):
		return
	var source := FAVORITES.new().find(current.actor.data, actor.value, [], key)
	if source.is_empty() or not str(source.category) in ["Items", "Features"] or not source.available:
		return
	var item := "owned-feature:" + str(source.entry) if source.category == "Features" else str(source.item)
	var task := {"key": key, "item": item, "source": str(source.source), "rook": _source_rook(actor)}
	var result := _sdk.windows.open_actor_task(SURFACE, actor, task)
	if not result.ok:
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = _sdk.translations.text(str(source.category))
		feedback.message = _sdk.translations.text(result.message)
		_sdk.feedback.error(feedback)

func _source_rook(actor: SDK.ActorId) -> String:
	var context := _sdk.character_hud.context()
	var preferred := context.rook.value if context.ok and context.actor != null and context.actor.value == actor.value and context.rook != null else ""
	var resolver := SOURCE_ROOKS.new()
	var rook := resolver.resolve(resolver.candidates(_sdk, actor), preferred)
	return rook.value if rook != null else ""

func _presentation(actor: SDK.Actor, source: Dictionary) -> Dictionary:
	var data: Dictionary = actor.data
	var kind := str(source.get("source", ""))
	var id := "owned-feature:" + str(source.get("entry", "")) if str(source.category) == "Features" else str(source.get("item", ""))
	var item := RULES.new().owned(data, id)
	var rule := RULES.new().definition(kind)
	var value := str(VALUES.get(kind, "Use"))
	var detail := _sdk.translations.text(str(DETAILS.get(kind, "Class action" if str(source.category) == "Features" else "Equipment")))
	var icon: Texture2D = FEATURE_ICON if str(source.category) == "Features" else ITEM_ICON
	if rule.has("ability"):
		var ability := str(rule.ability)
		var short := str({"Agility": "AGI", "Presence": "PRE", "Strength": "STR", "Toughness": "TOU"}.get(ability, ""))
		value = "%s · DR%d" % [short, int(rule.dr)] if not short.is_empty() else "DR%d" % int(rule.dr)
	elif rule.get("healing", false):
		value = "d6 healing"
	elif rule.get("poison", false):
		value = _sdk.translations.text("TOU DR%d · d%d HP") % [int(rule.dr), int(rule.die)]
	elif rule.get("damage", false):
		value = _sdk.translations.text("d%d damage") % int(rule.die)
	if not item.is_empty():
		if item.has("dose_pool"):
			var inventory: Array = data.get("inventory", [])
			for raw in inventory:
				var pool: Dictionary = raw
				if str(pool.get("source_item_id", "")) == str(item.dose_pool) and int(pool.get("quantity", 0)) > 0 and not pool.get("broken", false):
					detail = _sdk.translations.text("%d shared doses · current batch") % int(pool.get("uses", 0))
					break
		elif kind == "abominable-gob-lobber":
			detail = _sdk.translations.text("%d spits · new fight in workflow") % int(item.get("uses", 0))
		elif rule.has("uses") and kind != "stones-taken-from-thel-emas-lost-temple":
			detail = _sdk.translations.text("%d remaining · daily") % int(item.get("uses", int(rule.uses)))
		elif item.has("uses") and not DETAILS.has(kind):
			detail = _sdk.translations.text("Uses: %d") % int(item.uses)
		elif not DETAILS.has(kind):
			detail = _sdk.translations.text("Quantity: %d") % int(item.get("quantity", 0))
	if kind == "medicine-box":
		icon = HEALING_ICON
	elif kind in ["dried-food", "lard"]:
		icon = FOOD_ICON
	elif kind == "torch":
		icon = TORCH_ICON
	elif kind == "portable-laboratory":
		icon = LAB_ICON
	elif kind in ["lantern-oil", "waterskin", "life-elixir", "poison-red", "poison-black"]:
		icon = ELIXIR_ICON
	return {"detail": detail, "value": _sdk.translations.text(value), "icon": icon}
