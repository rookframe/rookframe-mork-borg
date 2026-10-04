extends RefCounted

## Bare Bones pp.31,37 and printed class Omen dice. Rest never refills resources.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const CLASSES = preload(ROOT + "logic/creation_classes.gd")
const CONDITION = preload(ROOT + "logic/broken_incident.gd")

func can_rest(data: Dictionary) -> bool:
	return str(data.get("schema", "")) == "mork-borg-character/v1" and typeof(data.get("hit_points")) == TYPE_INT and typeof(data.get("maximum_hit_points")) == TYPE_INT and int(data.maximum_hit_points) > 0 and not CONDITION.new().is_dead(data)

func omen_faces(data: Dictionary) -> int:
	var profile := CLASSES.new().profile(str(data.get("class_id", "classless")))
	return int(profile.get("omen_faces", 0))

func can_regain_omens(data: Dictionary) -> bool:
	return can_rest(data) and typeof(data.get("omens")) == TYPE_INT and int(data.omens) == 0 and omen_faces(data) in [2, 4]

func available(actor: SDK.Actor, facade: SDK, key: String) -> bool:
	if facade == null or actor == null or actor.access_level != "Owner" or not RESPONSIBILITY.new().resolve(facade, actor.id).get("ok", false):
		return false
	return can_regain_omens(actor.data) if key == "omens" else can_rest(actor.data) if key in ["breath", "sleep"] else false
