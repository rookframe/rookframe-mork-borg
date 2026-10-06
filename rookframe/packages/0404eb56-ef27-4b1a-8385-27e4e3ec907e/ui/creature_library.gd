extends RefCounted
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const MINIATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/miniature_actions.gd")
var sdk: SDK

func _init(facade: SDK) -> void:
	sdk = facade

func create(definition: SDK.ContentReference, scene: SDK.SceneId = null, position: Vector2 = Vector2(0, 0), open_view: bool = true) -> SDK.ActorResult:
	if definition.package_id != sdk.package_id() or not CREATURES.CORE_DEFINITIONS.has(definition.local_id):
		return _failure("Choose a Creature definition.")
	var result := await sdk.system_actions.submit("miniature.create", {"definition": definition.local_id})
	if not result.ok:
		return _failure(result.message)
	var outcome: Dictionary = result.value
	if str(outcome.get("state", "error")) != "resolved":
		return _failure(str(outcome.get("message", "Could not create Actor.")))
	var actor := SDK.ActorId.new(str(outcome.actor))
	if scene != null:
		var placed := await MINIATURES.new(sdk).place_at(actor, scene, position)
		if not placed.ok:
			var removed := await sdk.actors.delete(actor)
			return _failure(placed.message + (" " + removed.message if not removed.ok else ""))
	elif open_view:
		sdk.windows.open_actor(preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_surface.tres"), actor)
	return sdk.actors.read(actor)

func _failure(message: String) -> SDK.ActorResult:
	var feedback := SDK.FeedbackMessage.new()
	feedback.title = sdk.translations.text("Could not create Actor")
	feedback.message = sdk.translations.text(message)
	sdk.feedback.error(feedback)
	return SDK.ActorResult.new({"ok": false, "message": message})
