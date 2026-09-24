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

func test_owned_creature_requests_the_other_characters_defence() -> void:
	var host := _host()
	host.actors.hero.data = load(ROOT + "content/nodh-zombie.tres").create_data({})
	host.actors.enemy.data = {"schema": "mork-borg-character/v1", "name": "Mira", "hit_points": 8, "abilities": {"Agility": {"modifier": 1}}, "inventory": []}
	host.sessions.append({"participant_id": "defender", "session_id": "defender-session", "is_gm": false})
	host.access_by_actor = {
		"hero": [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "player-session"}],
		"enemy": [{"participant_id": "defender", "display_name": "Mira", "access_level": "Owner", "is_connected": true, "session_id": "defender-session"}]}
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
