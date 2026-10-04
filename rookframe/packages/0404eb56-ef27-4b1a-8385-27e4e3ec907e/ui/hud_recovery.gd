extends RefCounted

## Recovery is a fixed list, independent of Actor Favorites and targeting.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const RULES = preload(ROOT + "logic/recovery_rules.gd")
const SURFACE: SDK.ExtensionSurface = preload(ROOT + "ui/hud_recovery_surface.tres")
const ICON = preload("res://rookframe/ui/icons/character/heart.svg")
var _sdk: SDK

func bind(facade: SDK) -> void:
	_sdk = facade

func entries(actor: SDK.Actor) -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	var omen_faces := RULES.new().omen_faces(actor.data) if actor != null else 0
	for option in [["breath", "Catch breath", "d4 HP"], ["sleep", "Full night’s sleep", "d6 HP"], ["omens", "Regain Omens", ""]]:
		var entry := ENTRY.new()
		entry.id = str(option[0])
		entry.title = _sdk.translations.text(str(option[1])) if _sdk != null else str(option[1])
		entry.value = ("d%d" % omen_faces if omen_faces in [2, 4] else "") if entry.id == "omens" else str(option[2])
		if _sdk != null:
			entry.value = _sdk.translations.text(entry.value)
		entry.icon = ICON
		entry.available = RULES.new().available(actor, _sdk, entry.id)
		result.append(entry)
	return result

func launch(actor: SDK.ActorId, key: String) -> void:
	if _sdk == null or actor == null:
		return
	var current := _sdk.actors.read(actor)
	if not current.ok:
		return
	for entry in entries(current.actor):
		if entry.id == key and entry.available:
			var result := _sdk.windows.open_actor_task(SURFACE, actor, {"recovery": key})
			if not result.ok:
				var message := SDK.FeedbackMessage.new()
				message.title = _sdk.translations.text("Recovery")
				message.message = _sdk.translations.text(result.message)
				_sdk.feedback.error(message)
			return
