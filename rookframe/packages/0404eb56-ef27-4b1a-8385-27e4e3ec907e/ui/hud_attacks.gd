extends Node
## HUD handoff only. The managed tabletop action owns the captured Actor/source.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SURFACE: SDK.ExtensionSurface = preload(ROOT + "ui/tabletop_attack_surface.tres")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const MODEL = preload(ROOT + "logic/actor_favorites.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ICON = preload("res://rookframe/ui/icons/character/sword.svg")
var _sdk: SDK

func bind(facade: SDK) -> void:
	_sdk = facade

func entries(actor: SDK.Actor) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	if actor == null:
		return result
	for source in MODEL.new().entries(actor.data, actor.id.value):
		if str(source.get("category", "")) != "Attacks":
			continue
		var entry := ENTRY.new()
		entry.id = str(source.key)
		entry.title = _sdk.translations.text(str(source.get("name", "Attack")))
		entry.detail = _sdk.translations.text(str(source.get("detail", "")))
		entry.value = str(source.get("damage", ""))
		entry.icon = ICON
		entry.available = available(actor, source)
		entry.favorite = source.get("starred", false)
		result.append(entry)
	return result

func available(actor: SDK.Actor, entry: Dictionary) -> bool:
	return _sdk != null and actor != null and actor.access_level == "Owner" and entry.get("present", false) and entry.get("available", false) and RESPONSIBILITY.new().resolve(_sdk, actor.id).get("ok", false)

func launch(actor: SDK.ActorId, entry: Dictionary) -> void:
	if _sdk == null or actor == null:
		return
	var current := _sdk.actors.read(actor)
	if not current.ok:
		return
	var exact := MODEL.new().find(current.actor.data, actor.value, [], str(entry.get("key", "")))
	if not available(current.actor, exact) or str(exact.get("category", "")) != "Attacks":
		return
	var task := {"item": str(exact.get("item", "")), "mode": "jab" if str(exact.get("source", "")) == "cowards-jab" else "attack", "entry": str(exact.get("entry", ""))}
	var result: SDK.OperationResult = _sdk.windows.open_actor_task(SURFACE, actor, task)
	if not result.ok:
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = _sdk.translations.text("Attack")
		feedback.message = _sdk.translations.text(result.message)
		_sdk.feedback.error(feedback)
