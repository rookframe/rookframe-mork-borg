extends "res://tests/encounter_sdk_boundary.gd"
var language := "en"
var missing := false
var placed: Dictionary = {}
var previews_requested: Array = []

func ReadContent(package: String, id: String) -> Dictionary:
	if package != "external-miniatures" or id not in ["goblin", "warden"]:
		return {"ok": false, "message": "Unavailable"}
	return {"ok": true, "value": {"packageId": package, "localId": id, "displayName": "Goblin" if id == "goblin" else "Amber Warden", "localizedDisplayName": ("Чужой гоблин" if id == "goblin" else "Янтарный страж") if language == "ru" else ("Goblin" if id == "goblin" else "Amber Warden"), "packageName": "Tabletop Pieces", "type": "miniature", "available": not missing}}

func ListContent(_kind: int) -> Dictionary:
	return {"ok": true, "value": [ReadContent("external-miniatures", "goblin").value, ReadContent("external-miniatures", "warden").value]}

func Translate(message: String, _domain: String) -> String:
	var translations: Translation = load(ROOT + "i18n/" + language + ".tres")
	var text := str(translations.get_message(message))
	return text if not text.is_empty() else message

func PreviewMiniature(package: String, id: String, _target: Control) -> Dictionary:
	previews_requested.append(package + "/" + id)
	return {"ok": not missing}

func CurrentScene() -> Dictionary:
	return {"ok": true, "value": {"id": "chosen-scene", "name": "Tabletop"}}

func CreateRook(package: String, id: String, scene: String, position: Vector2, yaw: float) -> Dictionary:
	var identity := "placed-%d" % placed.size()
	placed[identity] = {"id": identity, "actor": "", "scene": scene, "position": position, "yaw": yaw, "hidden": false, "miniature": {"packageId": package, "localId": id}}
	return ReadRook(identity)

func ReadRook(id: String) -> Dictionary:
	if placed.has(id):
		return {"ok": true, "value": placed[id].duplicate(true)}
	return super.ReadRook(id)

func LinkRook(id: String, actor: String) -> Dictionary:
	placed[id].actor = actor
	return {"ok": true}

func DeleteRook(id: String) -> Dictionary:
	placed.erase(id)
	return {"ok": true}

func SetRookMiniature(id: String, package: String, local_id: String) -> Dictionary:
	placed[id].miniature = {"packageId": package, "localId": local_id}
	return ReadRook(id)
