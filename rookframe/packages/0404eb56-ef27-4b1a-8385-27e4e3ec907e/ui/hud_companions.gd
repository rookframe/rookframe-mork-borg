extends Node
## Character favorites refer to actual Creature Actors and exact owned attacks.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const SURFACE: SDK.ExtensionSurface = preload(ROOT + "ui/tabletop_attack_surface.tres")
const MODEL = preload(ROOT + "logic/actor_favorites.gd")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const ICON = preload("res://rookframe/ui/icons/character/psychopomp.svg")
var _sdk: SDK

func bind(facade: SDK) -> void:
	_sdk = facade

func entries(character: SDK.Actor) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	if _sdk == null or character == null or character.access_level != "Owner":
		return result
	var listed := _sdk.actors.list()
	var companions: Array[SDK.Actor] = listed.items if listed.ok else []
	for favorite in MODEL.new().entries(character.data, character.id.value, companions):
		if str(favorite.get("category", "")) != "Companions":
			continue
		var row := ENTRY.new()
		row.id = str(favorite.key)
		row.title = str(favorite.get("name", "Companion"))
		row.detail = str(favorite.get("detail", ""))
		row.value = str(favorite.get("damage", ""))
		row.icon = ICON
		row.favorite = favorite.get("starred", false)
		row.available = available(character, favorite)
		result.append(row)
	return result

func available(character: SDK.Actor, entry: Dictionary) -> bool:
	if _sdk == null or character == null or character.access_level != "Owner" or not entry.get("present", false) or not entry.get("available", false):
		return false
	var source := _sdk.actors.read(SDK.ActorId.new(str(entry.get("actor", ""))))
	return source.ok and source.actor.access_level == "Owner" and MODEL.new().is_companion(character.data, character.id.value, source.actor.data) and RESPONSIBILITY.new().resolve(_sdk, source.actor.id).get("ok", false)

func launch(character_id: SDK.ActorId, key: String) -> void:
	if _sdk == null or character_id == null:
		return
	var character := _sdk.actors.read(character_id)
	var listed := _sdk.actors.list()
	if not character.ok or not listed.ok:
		return
	var exact := MODEL.new().find(character.actor.data, character_id.value, listed.items, key)
	if not available(character.actor, exact) or str(exact.get("category", "")) != "Companions":
		return
	var source := SDK.ActorId.new(str(exact.actor))
	var task := {"item": str(exact.item), "mode": "attack", "companion": true, "character": character_id.value}
	var opened := _sdk.windows.open_actor_task(SURFACE, source, task)
	if not opened.ok:
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = _sdk.translations.text("Companion attack")
		feedback.message = _sdk.translations.text(opened.message)
		_sdk.feedback.error(feedback)
