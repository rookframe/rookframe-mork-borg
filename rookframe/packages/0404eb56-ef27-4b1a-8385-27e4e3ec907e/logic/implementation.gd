extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_authority.gd"

const DEFENCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_authority.gd")
var _defence := DEFENCE.new()
const POWERS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/power_authority.gd")
var _powers := POWERS.new()

func handle_system_intent(context: SDK.SystemActionContext, name: String, payload: Variant) -> Variant:
	if name.begins_with("power."):
		return _powers.handle(context, name, payload)
	if name.begins_with("defence."):
		return _defence.handle(context, name, payload)
	return super.handle_system_intent(context, name, payload)
