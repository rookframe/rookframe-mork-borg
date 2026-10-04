extends RefCounted
## Resolve only this Actor's Rooks in the Participant's active Scene.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")

func candidates(facade: SDK, actor: SDK.ActorId) -> Array[SDK.RookId]:
	var result: Array[SDK.RookId] = []
	var scene := facade.scenes.current()
	var listed := facade.rooks.list()
	if not scene.ok or not listed.ok:
		return result
	for rook in listed.items:
		if rook.actor != null and rook.actor.value == actor.value and rook.scene.value == scene.scene.id.value:
			result.append(rook.id)
	return result

func resolve(rooks: Array[SDK.RookId], preferred: String) -> SDK.RookId:
	for rook in rooks:
		if rook.value == preferred:
			return rook
	return rooks[0] if rooks.size() == 1 else null
