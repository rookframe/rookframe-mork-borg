extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/implementation.gd"

const SHEET = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/sheet_authority.gd")
var _sheet := SHEET.new()
const CREATURE_CORRECTIONS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_authority.gd")
var _creature_corrections := CREATURE_CORRECTIONS.new()
const CREATURE_HEALTH = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_health_authority.gd")
var _creature_health := CREATURE_HEALTH.new()
const CREATURE_HUD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_hud_authority.gd")
var _creature_hud := CREATURE_HUD.new()
const CREATURE_ROLL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_roll_authority.gd")
var _creature_roll := CREATURE_ROLL.new()

const MELEE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_authority.gd")
var _melee := MELEE.new()

const DEFENCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_authority.gd")
var _defence := DEFENCE.new()
const COMPANIONS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/companion_authority.gd")
var _companions := COMPANIONS.new(_melee, _defence)
const POWERS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/power_authority.gd")
var _powers := POWERS.new()

const SPECIAL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_authority.gd")
var _special := SPECIAL.new()

const HEALTH = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/health_authority.gd")
var _health := HEALTH.new()

const ENCOUNTER = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/encounter_authority.gd")
var _encounter := ENCOUNTER.new()

const MINIATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/miniature_authority.gd")
var _miniatures := MINIATURES.new()
const CREATURE_APPEARANCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_appearance_authority.gd")
var _creature_appearance := CREATURE_APPEARANCE.new()
const SHEET_COMBAT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/sheet_combat.gd")
var _sheet_combat := SHEET_COMBAT.new()
const PORTRAIT_CONVERSION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/portrait_conversion.gd")

func migrate_actor_data(data: Variant) -> Variant:
	return PORTRAIT_CONVERSION.new().actor_data(sdk, data)

func migrate_world_data(data: Variant) -> Variant:
	return PORTRAIT_CONVERSION.new().world_data(sdk, data)

func handle_system_intent(context: SDK.SystemActionContext, name: String, payload: Variant) -> Variant:
	if name == "creature-hud.special":
		return _creature_hud.handle(context, payload)
	if name.begins_with("creature-roll."):
		return _creature_roll.handle(context, name, payload)
	if name.begins_with("creature-health."):
		return _creature_health.handle(context, name, payload)
	if name.begins_with("creature-appearance."):
		return _creature_appearance.handle(context, sdk, name, payload)
	if name.begins_with("companion."):
		return _companions.handle(context, name, payload)
	if name.begins_with("creature."):
		return await _creature_corrections.handle(context, name, payload)
	if name.begins_with("sheet."):
		return await _sheet.handle(context, sdk, name, payload)
	if name.begins_with("sheet-combat."):
		return _sheet_combat.handle_system_intent(context, name.replace("sheet-combat.", "melee."), payload)
	if name.begins_with("miniature."):
		return _miniatures.handle(context, sdk, name, payload)
	if name.begins_with("encounter."):
		return _encounter.handle(context, name, payload)
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
	return _melee.handle_system_intent(context, name, payload)
