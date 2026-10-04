extends RefCounted

## Powers share the sheet's Actor Favorite records and authority workflow.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const FAVORITES = preload(ROOT + "logic/actor_favorites.gd")
const POWERS = preload(ROOT + "logic/powers.gd")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const SURFACE: SDK.ExtensionSurface = preload(ROOT + "ui/hud_power_surface.tres")
const ICON = preload("res://rookframe/ui/icons/character/book.svg")
var _sdk: SDK

func bind(facade: SDK) -> void:
	_sdk = facade

func entries(actor: SDK.Actor) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	if actor == null:
		return result
	var responsible := can_morning(actor)
	for source in FAVORITES.new().entries(actor.data, actor.id.value):
		if str(source.get("category", "")) != "Powers":
			continue
		var power := POWERS.new().definition(str(source.get("source", "")))
		var entry := ENTRY.new()
		entry.id = str(source.key)
		entry.title = _sdk.translations.text(str(source.get("name", "Power")))
		entry.detail = _sdk.translations.text("Sacred scroll" if str(power.get("family", "")) == "sacred" else "Unclean scroll")
		entry.value = _sdk.translations.text("Cast")
		entry.icon = ICON
		entry.favorite = source.get("starred", false)
		entry.available = responsible and source.get("available", false) and power.get("playable", false)
		result.append(entry)
	return result

func can_morning(actor: SDK.Actor) -> bool:
	# Morning is independent of daily uses, equipment and casting restrictions.
	return _sdk != null and actor != null and actor.access_level == "Owner" and RESPONSIBILITY.new().resolve(_sdk, actor.id).get("ok", false)

func launch(actor: SDK.ActorId, key: String) -> void:
	var current := _sdk.actors.read(actor)
	if not current.ok or not can_morning(current.actor):
		return
	var source := FAVORITES.new().find(current.actor.data, actor.value, [], key)
	if source.is_empty() or source.category != "Powers" or not source.available:
		return
	var task := {"key": key, "item": str(source.item), "source": str(source.source), "rook": _source_rook(actor), "daily": false}
	_report(_sdk.windows.open_actor_task(SURFACE, actor, task))

func morning(actor: SDK.ActorId) -> void:
	var current := _sdk.actors.read(actor)
	if current.ok and can_morning(current.actor):
		_report(_sdk.windows.open_actor_task(SURFACE, actor, {"daily": true, "rook": ""}))

func _source_rook(actor: SDK.ActorId) -> String:
	var context := _sdk.character_hud.context()
	if context.ok and context.actor != null and context.actor.value == actor.value and context.rook != null:
		return context.rook.value
	return ""

func _report(result: SDK.OperationResult) -> void:
	if result.ok:
		return
	var message := SDK.FeedbackMessage.new()
	message.title = _sdk.translations.text("Powers")
	message.message = _sdk.translations.text(result.message)
	_sdk.feedback.error(message)
