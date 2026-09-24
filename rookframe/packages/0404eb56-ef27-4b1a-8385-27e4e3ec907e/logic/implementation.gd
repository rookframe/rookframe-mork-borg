extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_authority.gd"

const DEFENCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_authority.gd")
var _defence := DEFENCE.new()
const POWERS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/power_authority.gd")
var _powers := POWERS.new()

const SPECIAL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_authority.gd")
var _special := SPECIAL.new()

const HEALTH = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/health_authority.gd")
var _health := HEALTH.new()

func handle_system_intent(context: SDK.SystemActionContext, name: String, payload: Variant) -> Variant:
	if name.begins_with("health."):
		return _health.handle(context, name, payload)
	if name.begins_with("special."):
		return _special.handle(context, name, payload)
	if name.begins_with("power."):
		return _powers.handle(context, name, payload)
	if name == "defence.inbox":
		var inbox: Array = _defence.handle(context, name, payload)
		for action in _special.shield_inbox(context):
			inbox.append(action)
		return inbox
	if name.begins_with("defence."):
		return _defence.handle(context, name, payload)
	return super.handle_system_intent(context, name, payload)
