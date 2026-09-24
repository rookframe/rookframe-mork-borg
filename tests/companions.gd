extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host(power: String = "tongue-of-eris") -> BOUNDARY:
	var host := BOUNDARY.new()
	var system := SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	host.actors.hero.data["hit_points"] = 7
	host.actors.hero.data["maximum_hit_points"] = 9
	host.actors.enemy.data["maximum_hit_points"] = 6
	host.actors.hero.data["power_uses"] = 3
	host.actors.hero.data.abilities["Presence"] = {"modifier": 1}
	for family in SCROLLS.TABLES:
		for entry in SCROLLS.TABLES[family]:
			if entry.source_item_id == power:
				var scroll: Dictionary = entry.duplicate(true)
				scroll["inventory_id"] = "scroll"
				scroll["quantity"] = 1
				host.actors.hero.data.inventory.append(scroll)
	return host

func _cast_input(id: String = "cast") -> Dictionary:
	return {"id": id, "source": "hero", "rook": "hero-rook", "item": "scroll", "eligible": true, "modifier": 0}


func test_psychopomp_creates_individual_source_profiles_once(kind: int, profile: String, armor: String, _test_parameters := [[1, "belze-skeleton", ""], [3, "belze-skeleton", ""], [4, "nodh-zombie", "d2"], [6, "nodh-zombie", "d2"]]) -> void:
	var host := _host("foul-psychompomp")
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_array(host.requests[host.last_request].terms).is_equal([
		{"name": "Creature type", "faces": 6, "count": 1},
		{"name": "Creatures", "faces": 4, "count": 1}])
	host.roll(host.last_request, [kind, 2])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.size()).is_equal(4)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	var creatures: Array = []
	for raw in host.actors.values():
		var actor: Dictionary = raw
		if str(actor.data.get("summoner_actor", "")) == "hero":
			creatures.append(actor)
	assert_int(creatures.size()).is_equal(2)
	if creatures.size() != 2:
		return
	for creature in creatures:
		assert_str(creature.data.definition_id).is_equal(profile)
		assert_int(creature.data.hit_points).is_equal(7)
		assert_int(creature.data.maximum_hit_points).is_equal(7)
		assert_str(creature.data.armor.reduction).is_equal(armor)
		assert_str(creature.access_level).is_equal("Owner")
		assert_bool(creature.data.has("duration")).is_false()
		assert_bool(creature.data.has("allegiance")).is_false()
	creatures[0].data.hit_points = 3
	assert_int(creatures[1].data.hit_points).is_equal(7)
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	await sdk.system_actions.submit("power.start", _cast_input())
	assert_int(host.actors.size()).is_equal(4)
	assert_int(host.reports.size()).is_equal(2)
	assert_str(str(host.reports[-1])).contains("2").contains("Raw Rolls").not_contains("duration")

func test_summon_termination_preserves_casting_use_and_rejects_late_materialization(reason: String, _test_parameters := [["cancel"], ["tray"], ["disconnect"], ["access"], ["save"], ["restart"]]) -> void:
	var host := _host("foul-psychompomp")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	var quantity_request := host.last_request
	match reason:
		"cancel": await sdk.system_actions.submit("power.cancel", {"id": "cast"})
		"tray":
			host.SystemIntentCancelThrow("", quantity_request)
			await sdk.system_actions.submit("power.advance", {"id": "cast"})
		"disconnect": host.sessions = []
		"access": host.actors.hero.access_level = "Viewer"
		"save": host.fail_commit = true
		"restart":
			var system := SYSTEM.new()
			add_child(auto_free(system))
			host.handler = system
	host.roll(quantity_request, [6, 4])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.size()).is_equal(2)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	host.fail_commit = false
	await sdk.system_actions.submit("power.start", _cast_input())
	assert_int(host.actors.size()).is_equal(2)

func test_gm_cast_for_player_grants_the_casters_normal_access() -> void:
	var host := _host("foul-psychompomp")
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.access_entries = [{"participant_id": "player", "display_name": "Mira", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}]
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	assert_str(host.requests.cast.participant).is_equal("player")
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [4, 1])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.size()).is_equal(3)
	assert_str(host.created_for).is_equal("player")

func _combat_host() -> BOUNDARY:
	var host := _host()
	host.actors.hero.data = load(ROOT + "content/nodh-zombie.tres").create_data({})
	host.actors.enemy.data = {"schema": "mork-borg-character/v1", "name": "Mira", "hit_points": 8, "abilities": {"Agility": {"modifier": 1}}, "inventory": []}
	host.sessions.append({"participant_id": "defender", "session_id": "defender-session", "is_gm": false})
	host.access_by_actor = {
		"hero": [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}],
		"enemy": [{"participant_id": "defender", "display_name": "Mira", "access_level": "Owner", "is_connected": true, "session_id": "defender-session"}]}
	return host

func test_owned_creature_requests_the_other_characters_defence() -> void:
	var host := _combat_host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("defence.start", {"id": "bite", "source": "hero", "rook": "hero-rook", "attack": "bite"})
	assert_str(result.value.state).is_equal("ready")
	if result.value.state != "ready":
		return
	assert_bool(host.requests.is_empty()).is_true()
	host.participant = "defender"
	host.session = "defender-session"
	await sdk.system_actions.submit("defence.roll", {"id": "bite"})
	assert_str(host.requests.bite.participant).is_equal("defender")
	host.roll("bite", [2])
	await sdk.system_actions.submit("defence.advance", {"id": "bite"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Damage", "faces": 4, "count": 1}])
	host.roll(host.last_request, [4])
	result = await sdk.system_actions.submit("defence.advance", {"id": "bite"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

func test_creature_attack_uses_its_own_rook_and_equipped_action() -> void:
	var host := _host()
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	host.rooks["owner-rook"] = "owner"
	host.distances = {"hero-rook->enemy-rook": 8.0, "owner-rook->enemy-rook": 1.0}
	var sdk := SDK.new(host)
	var input := {"source": "hero", "rook": "owner-rook", "attack": "knife"}
	var result := await sdk.system_actions.submit("attack.validate", input)
	assert_str(result.value.message).contains("this Creature’s source Rook")
	input.rook = "hero-rook"
	result = await sdk.system_actions.submit("attack.validate", input)
	assert_str(result.value.message).is_equal("target Hooded stranger not in range")
	input.attack = "shortbow"
	result = await sdk.system_actions.submit("attack.validate", input)
	assert_str(result.value.state).is_equal("ready")
	host.actors.hero.data.attacks[1]["equipped"] = false
	result = await sdk.system_actions.submit("attack.validate", input)
	assert_str(result.value.state).is_equal("error")
	assert_str(result.value.message).contains("equipped")
	assert_bool(host.requests.is_empty()).is_true()

func test_companion_rows_keep_owner_actions_at_touch_size(access: String, _test_parameters := [["Owner"], ["Viewer"]]) -> void:
	var view = load(ROOT + "ui/character_companions.tscn").instantiate()
	add_child(auto_free(view))
	view.size = Vector2(343, 270)
	var actors: Array[SDK.Actor] = [SDK.Actor.new({"id": "hound", "access_level": access, "data": {"name": "Ancient gore-hound", "hit_points": 4, "maximum_hit_points": 10}})]
	view.configure(actors)
	await get_tree().process_frame
	await get_tree().process_frame
	var row: Control = view.get_node("Items").get_child(0)
	assert_str(row.get_node("Details").text).contains("4 / 10 HP")
	var open: Button = row.get_node("Actions/Open")
	var place: Button = row.get_node("Actions/Place")
	assert_bool(place.disabled).is_equal(access != "Owner")
	assert_bool(open.disabled).is_false()
	assert_float(open.size.y).is_greater_equal(44.0)
	assert_float(place.size.y).is_greater_equal(44.0)
	assert_float(row.size.x).is_less_equal(343.0)

func test_creature_inventory_edits_preserve_profiles_and_individual_state() -> void:
	var host := _host()
	host.actors.hero.data = load(ROOT + "content/belze-skeleton.tres").create_data({})
	var actions = load(ROOT + "logic/creature_actions.gd").new(SDK.new(host), SDK.ActorId.new("hero"))
	var result: SDK.ActorResult = await actions.add_equipment("sword")
	assert_bool(result.ok).is_true()
	if not result.ok:
		return
	assert_int(result.actor.data.inventory.size()).is_equal(4)
	var sword: Dictionary = result.actor.data.inventory[-1]
	assert_str(sword.damage).is_equal("d6")
	await actions.change_item(str(sword.inventory_id), "equipped", "true")
	result = await actions.change_item(str(sword.inventory_id), "quantity", "2")
	assert_int(result.actor.data.inventory[-1].quantity).is_equal(2)
	var creatures = load(ROOT + "logic/creature_definition.gd").new()
	var attacks: Array = creatures.attack_options(result.actor.data)
	assert_int(attacks.size()).is_equal(4)
	assert_str(attacks[-1].dice).is_equal("d6")
	assert_bool(attacks[-1].equipped).is_true()
	await actions.remove_item("creature:shortsword")
	result = await actions.add_equipment("torch")
	attacks = creatures.attack_options(result.actor.data)
	assert_int(attacks.size()).is_equal(3)
	assert_bool(attacks.any(func(attack): return attack.id == "shortsword")).is_false()
	await actions.change_item("creature:knife", "equipped", "false")
	var sdk := SDK.new(host)
	var prepared := await sdk.system_actions.submit("attack.validate", {"source": "hero", "rook": "hero-rook", "attack": "knife"})
	assert_str(prepared.value.message).contains("equipped")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	host.actors.hero.access_level = "Viewer"
	result = await actions.remove_item(str(sword.inventory_id))
	assert_bool(result.ok).is_false()

func test_companion_ranged_resource_is_spent_once_after_defence_roll() -> void:
	var host := _combat_host()
	var sdk := SDK.new(host)
	var actions = load(ROOT + "logic/creature_actions.gd").new(sdk, SDK.ActorId.new("hero"))
	var added: SDK.ActorResult = await actions.add_equipment("shortbow")
	var bow: Dictionary = added.actor.data.inventory[-1]
	await actions.change_item(str(bow.inventory_id), "equipped", "true")
	var input := {"id": "ranged", "source": "hero", "rook": "hero-rook", "attack": str(bow.inventory_id)}
	var result := await sdk.system_actions.submit("defence.start", input)
	assert_str(result.value.state).is_equal("error")
	added = await actions.add_equipment("arrow")
	var arrow: Dictionary = added.actor.data.inventory[-1]
	await actions.change_item(str(arrow.inventory_id), "quantity", "2")
	result = await sdk.system_actions.submit("defence.start", input)
	assert_str(result.value.state).is_equal("ready")
	host.participant = "defender"
	host.session = "defender-session"
	await sdk.system_actions.submit("defence.roll", {"id": "ranged"})
	host.roll("ranged", [2])
	await sdk.system_actions.submit("defence.advance", {"id": "ranged"})
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(1)
	var damage_request := host.last_request
	await sdk.system_actions.submit("defence.cancel", {"id": "ranged"})
	host.roll(damage_request, [4])
	await sdk.system_actions.submit("defence.advance", {"id": "ranged"})
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(1)
	assert_int(host.actors.enemy.data.hit_points).is_equal(8)

func test_critical_armor_damage_survives_unrelated_creature_inventory_edit() -> void:
	var host := _host()
	host.actors.enemy.data = load(ROOT + "content/nodh-zombie.tres").create_data({})
	host.actors.enemy.access_level = "Owner"
	var sdk := SDK.new(host)
	var actions = load(ROOT + "logic/creature_actions.gd").new(sdk, SDK.ActorId.new("enemy"))
	await actions.add_equipment("torch")
	await sdk.system_actions.submit("melee.start", {"id": "critical", "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"})
	host.roll("critical", [20])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	host.roll(host.last_request, [1, 4])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	assert_str(host.actors.enemy.data.armor.reduction).is_empty()
	await actions.add_equipment("torch")
	assert_str(host.actors.enemy.data.armor.reduction).is_empty()
	assert_int(host.actors.enemy.data.hit_points).is_equal(7)

func test_equipped_creature_shield_reduces_melee_and_power_damage(operation: String, _test_parameters := [["melee"], ["power"]]) -> void:
	var host := _host("palms-open-the-southern-gate")
	host.actors.enemy.data = load(ROOT + "content/nodh-zombie.tres").create_data({})
	host.actors.enemy.access_level = "Owner"
	var sdk := SDK.new(host)
	var actions = load(ROOT + "logic/creature_actions.gd").new(sdk, SDK.ActorId.new("enemy"))
	var added: SDK.ActorResult = await actions.add_equipment("shield")
	await actions.change_item(str(added.actor.data.inventory[-1].inventory_id), "equipped", "true")
	if operation == "melee":
		await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"})
		host.roll("attack", [17])
		await sdk.system_actions.submit("melee.advance", {"id": "attack"})
		host.roll(host.last_request, [5, 4])
		await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	else:
		await sdk.system_actions.submit("power.start", _cast_input())
		host.roll("cast", [11])
		await sdk.system_actions.submit("power.advance", {"id": "cast"})
		host.roll(host.last_request, [1])
		await sdk.system_actions.submit("power.advance", {"id": "cast"})
		await sdk.system_actions.submit("power.targets", {"id": "cast", "self": false})
		host.roll(host.last_request, [5, 4])
		await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.enemy.data.hit_points).is_equal(5)
