extends RefCounted
## Resolve the rolling side once on Authority, retaining the existing action.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const MELEE = preload(ROOT + "logic/melee_authority.gd")
const DEFENCE = preload(ROOT + "logic/defence_authority.gd")
const MODEL = preload(ROOT + "logic/actor_favorites.gd")
const TARGETING = preload(ROOT + "logic/attack_targeting.gd")
const BROKEN = preload(ROOT + "logic/broken_incident.gd")
var _melee: MELEE
var _defence: DEFENCE
var _routes: Dictionary = {}

func _init(melee: MELEE, defence: DEFENCE) -> void:
	_melee = melee
	_defence = defence

func handle(context: SDK.SystemActionContext, name: String, payload: Variant) -> Dictionary:
	if not name in ["companion.start", "companion.cancel"] or typeof(payload) != TYPE_DICTIONARY:
		return _error("The companion action is malformed.")
	var input: Dictionary = payload
	if name == "companion.cancel":
		if typeof(input.get("id", "")) != TYPE_STRING or not _routes.has(str(input.get("id", ""))):
			return _error("The companion action is unavailable.")
		var route := str(_routes.get(str(input.id)))
		# Existing authorities retain the initiating Participant/session checks.
		return _defence.handle(context, "defence.cancel", input) if route == "defence" else _melee.handle_system_intent(context, "melee.cancel", input)
	for key in ["id", "source", "character", "item"]:
		if typeof(input.get(str(key), "")) != TYPE_STRING or str(input.get(str(key), "")).is_empty():
			return _error("Choose the exact companion and owned attack.")
	var id := str(input.id)
	if _routes.has(id):
		return _start(context, str(_routes.get(id)), input)
	var character := context.read_actor(SDK.ActorId.new(str(input.character)))
	var source := context.read_actor(SDK.ActorId.new(str(input.source)))
	if not character.ok or character.actor.access_level != "Owner" or typeof(character.actor.data) != TYPE_DICTIONARY:
		return _error("Owner access to the initiating Character is required.")
	var character_data: Dictionary = character.actor.data
	if str(character_data.get("schema", "")) != "mork-borg-character/v1":
		return _error("Choose a Character.")
	if not source.ok or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		return _error("Choose this Character's authorized companion.")
	var source_data: Dictionary = source.actor.data
	if str(source_data.get("schema", "")) != "mork-borg-adversary/v1" or not MODEL.new().is_companion(character_data, character.actor.id.value, source_data):
		return _error("Choose this Character's authorized companion.")
	if not BROKEN.new().can_act(source.actor.data):
		return _error("This companion cannot act.")
	var caller := context.caller()
	if not caller.ok:
		return _error(caller.message)
	var values: Dictionary = caller.value
	var route := "melee"
	if not values.targets.is_empty():
		var preparation := TARGETING.new().validate_creature(context, input)
		if str(preparation.state) != "ready":
			return preparation
		route = "defence" if str(preparation.resolution) == "defence" else "melee"
	var result := _start(context, route, input)
	if str(result.get("state", "")) != "error":
		_routes[id] = route
	return result

func _start(context: SDK.SystemActionContext, route: String, input: Dictionary) -> Dictionary:
	var result: Dictionary = _defence.handle(context, "defence.start", input) if route == "defence" else _melee.handle_system_intent(context, "melee.start", input)
	result["operation"] = route
	return result

func _error(message: String) -> Dictionary:
	return {"state": "error", "message": message}
