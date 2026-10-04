extends GdUnitTestSuite

## Retained for severe saved-capability loss and stale-entry corruption risks.
## Uses the existing public SDK host boundary; does not exercise native saves.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	var system := SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	return host

func _saved_creature() -> Dictionary:
	var data: Dictionary = load(ROOT + "content/seth-goblin.tres").create_data({})
	data.erase("creature_stat_block")
	data["creature_inventory"] = true
	# Knife was removed; the remaining bow and armor were corrected in play.
	data["inventory_serial"] = 7
	data["inventory"] = [
		{"inventory_id": "5", "source_attack_id": "shortbow", "name": "Bent warbow", "kind": "Weapon", "damage": "d8", "range_feet": 40, "quantity": 2, "equipped": true, "ammunition": "arrow"},
		{"inventory_id": "6", "name": "Patched coat", "kind": "Armor", "reduction": "d4", "armor_tier": 2, "quantity": 1, "equipped": true},
		{"inventory_id": "7", "name": "Shield", "kind": "Shield", "quantity": 1, "equipped": true}]
	data["armor"] = {"name": "Patched coat", "reduction": "d4"}
	data.attacks[1]["rules"] = "Corrected attack rule."
	return data

func test_saved_capabilities_survive_conversion_and_stale_loot_edits() -> void:
	var host := _host()
	host.actors.hero.data = _saved_creature()
	var saved_items: Array = host.actors.hero.data.inventory.duplicate(true)
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var result := await actions.add_equipment("torch")
	assert_bool(result.ok).is_true()
	var data: Dictionary = sdk.actors.read(SDK.ActorId.new("hero")).actor.data
	var attacks: Array = data.attacks.duplicate(true)
	var armor: Dictionary = data.armor.duplicate(true)
	assert_int(attacks.size()).is_equal(1)
	assert_str(attacks[0].id).is_equal("shortbow")
	assert_str(attacks[0].name).is_equal("Bent warbow")
	assert_str(attacks[0].dice).is_equal("d8")
	assert_str(attacks[0].rules).is_equal("Corrected attack rule.")
	assert_int(attacks[0].range_feet).is_equal(40)
	assert_str(armor.reduction).is_equal("d4")
	assert_int(CREATURES.new().shield_reduction(data)).is_equal(1)
	for index in range(saved_items.size()):
		for key in saved_items[index]:
			assert_bool(data.inventory[index][key] == saved_items[index][key]).is_true()
	await actions.change_item("5", "quantity", "0")
	await actions.remove_item("5")
	await actions.remove_item("6")
	await actions.remove_item("7")
	result = await actions.add_custom({"name": "Stolen relic", "kind": "Weapon", "damage": "d4", "range_feet": 5})
	var new_id := str(result.actor.data.inventory[-1].inventory_id)
	assert_bool(new_id in ["5", "6", "7"]).is_false()
	result = await actions.change_item("5", "name", "Stale bow editor")
	assert_bool(result.ok).is_false()
	result = await actions.change_item(new_id, "damage", "d6")
	assert_bool(result.ok).is_true()
	result = await actions.change_item(new_id, "equipped", "true")
	assert_bool(result.ok).is_false()
	data = sdk.actors.read(SDK.ActorId.new("hero")).actor.data
	assert_array(data.attacks).is_equal(attacks)
	assert_dict(data.armor).is_equal(armor)
	assert_str(data.inventory[-1].name).is_equal("Stolen relic")
	assert_array(CREATURES.new().attack_options(data)).is_equal(attacks)
	var before := data.duplicate(true)
	host.actors.hero.access_level = "Viewer"
	result = await actions.remove_item(new_id)
	assert_bool(result.ok).is_false()
	assert_dict(sdk.actors.read(SDK.ActorId.new("hero")).actor.data).is_equal(before)

func test_accepted_creature_combat_keeps_loot_quantities_and_condition() -> void:
	var host := _host()
	host.actors.hero.data = _saved_creature()
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	await actions.add_equipment("arrow")
	var before: Array = host.actors.hero.data.inventory.duplicate(true)
	var result := await sdk.system_actions.submit("melee.start", {"id": "fumble", "source": "hero", "rook": "hero-rook", "item": "creature:shortbow"})
	assert_str(result.value.state).is_equal("pending")
	host.roll("fumble", [1])
	result = await sdk.system_actions.submit("melee.advance", {"id": "fumble"})
	assert_str(result.value.state).is_equal("resolved")
	await sdk.system_actions.submit("melee.advance", {"id": "fumble"})
	assert_array(host.actors.hero.data.inventory).is_equal(before)
	result = await sdk.system_actions.submit("attack.validate", {"source": "hero", "rook": "hero-rook", "attack": "shortbow"})
	assert_str(result.value.state).is_equal("ready")
	# Targeted defence retains the creature's independent protection procedure and never
	# presents a loot-shield break or spends the attacker's carried arrows.
	host.actors.enemy.data = load(ROOT + "content/nodh-zombie.tres").create_data({})
	host.actors.enemy.access_level = "Owner"
	host.access_by_actor.hero = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}]
	host.access_by_actor.enemy = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}]
	result = await sdk.system_actions.submit("defence.start", {"id": "defence", "source": "hero", "rook": "hero-rook", "attack": "shortbow"})
	assert_str(result.value.state).is_equal("ready")
	await sdk.system_actions.submit("defence.roll", {"id": "defence"})
	host.roll("defence", [1])
	await sdk.system_actions.submit("defence.advance", {"id": "defence"})
	host.roll(host.last_request, [2, 4])
	result = await sdk.system_actions.submit("defence.advance", {"id": "defence"})
	assert_str(result.value.state).is_equal("resolved")
	await sdk.system_actions.submit("defence.advance", {"id": "defence"})
	assert_array(host.actors.hero.data.inventory).is_equal(before)
	assert_str(host.actors.enemy.data.armor.reduction).is_empty()
	assert_bool(host.reports.is_empty()).is_false()
