extends RefCounted
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
var sdk: SDK
func _init(facade: SDK) -> void:
	sdk = facade

func available(reference: Dictionary) -> bool:
	if reference.is_empty():
		return false
	var found := sdk.content.read(_reference(reference))
	return found.ok and found.content_entry.available and found.content_entry.kind == SDK.ContentKind.Value.MINIATURE

func set_actor(actor: SDK.ActorId, reference: Dictionary) -> SDK.ActorResult:
	var current := sdk.actors.read(actor)
	if not current.ok or current.actor.access_level != "Owner":
		return SDK.ActorResult.new({"ok": false, "message": "Owner access is required to change this Creature’s Miniature."})
	if not available(reference):
		return SDK.ActorResult.new({"ok": false, "message": "This Miniature is unavailable. Choose another."})
	var data: Dictionary = current.actor.data.duplicate(true)
	data["preferred_miniature"] = reference.duplicate(true)
	return await sdk.actors.update(actor, data)

func place(actor: SDK.ActorId) -> SDK.RookResult:
	var current := sdk.actors.read(actor)
	if not current.ok:
		return SDK.RookResult.new({"ok": false, "message": current.message})
	var data: Dictionary = current.actor.data
	var reference: Dictionary = data.get("preferred_miniature", {})
	if not available(reference):
		return SDK.RookResult.new({"ok": false, "message": "Choose an available Miniature before placing this Creature."})
	var scene := sdk.scenes.current()
	if not scene.ok:
		return SDK.RookResult.new({"ok": false, "message": scene.message})
	var created := await sdk.rooks.create(_reference(reference), scene.scene.id, Vector2(0, 0))
	if not created.ok:
		return created
	var linked := await sdk.rooks.link(created.rook.id, actor)
	if not linked.ok:
		var removed := await sdk.rooks.delete(created.rook.id)
		return SDK.RookResult.new({"ok": false, "message": linked.message + (" " + removed.message if not removed.ok else "")})
	return created

func apply_selected(actor: SDK.ActorId) -> SDK.RookResult:
	var current := sdk.actors.read(actor)
	var id := sdk.rooks.selected()
	if id == null:
		return SDK.RookResult.new({"ok": false, "message": "Select a Rook linked to this Creature."})
	var selected := sdk.rooks.read(id)
	if not current.ok or not selected.ok or selected.rook.actor == null or selected.rook.actor.value != actor.value:
		return SDK.RookResult.new({"ok": false, "message": "Select a Rook linked to this Creature."})
	var data: Dictionary = current.actor.data
	var reference: Dictionary = data.get("preferred_miniature", {})
	if not available(reference):
		return SDK.RookResult.new({"ok": false, "message": "This Miniature is unavailable. Choose another."})
	return await sdk.rooks.set_miniature(selected.rook.id, _reference(reference))

func _reference(value: Dictionary) -> SDK.ContentReference:
	return SDK.ContentReference.new(str(value.get("package_id", "")), str(value.get("local_id", "")))
