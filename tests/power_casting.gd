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

func test_cast_from_owned_scroll_spends_only_success_and_reports_manual_outcome() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var started := await sdk.system_actions.submit("power.start", _cast_input())
	assert_bool(started.ok).is_true()
	assert_str(started.value.state).is_equal("pending")
	if started.value.state != "pending":
		return
	assert_array(host.requests.cast.terms).is_equal([{"name": "Casting", "faces": 20, "count": 1}])
	host.roll("cast", [11])
	var finished := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(finished.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_str(str(host.reports[-1])).contains("10 minutes").contains("Hooded stranger").not_contains("Seth")
	assert_int(host.reports.size()).is_equal(1)
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_int(host.reports.size()).is_equal(1)

func after_test() -> void:
	await get_tree().process_frame

func test_failure_and_natural_faces_preserve_their_distinct_resource_rules() -> void:
	for face in [2, 1, 20]:
		var host := _host()
		var sdk := SDK.new(host)
		await sdk.system_actions.submit("power.start", _cast_input())
		host.roll("cast", [face])
		var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
		if face == 2:
			assert_str(result.value.state).is_equal("pending")
			if result.value.state != "pending":
				continue
			assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Failure HP loss (d2)", "faces": 4, "count": 1}])
			host.roll(host.last_request, [3])
			result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
			assert_int(host.actors.hero.data.hit_points).is_equal(5)
			assert_str(str(host.reports[-1])).contains("dizzy for one hour").contains("worst possible way")
		else:
			assert_int(host.requests.size()).is_equal(1)
			assert_int(host.actors.hero.data.hit_points).is_equal(7)
			assert_str(str(host.reports[-1])).contains("Power %s: GM determines the outcome" % ("critical" if face == 20 else "fumble"))
		assert_str(result.value.state).is_equal("resolved")
		assert_int(host.actors.hero.data.power_uses).is_equal(3)
		await sdk.system_actions.submit("power.advance", {"id": "cast"})
		assert_int(host.reports.size()).is_equal(1)

func test_narrative_parameters_and_manual_hp_boundaries() -> void:
	var examples := [
		["te-le-kin-esis", [7, 4], "70 feet", "4 minutes"],
		["lucy-fires-levitation", [7], "8 rounds", "Hover"],
		["daemon-of-capillaries", [4], "4 rounds", "d4 HP per round"],
		["metzhuotl-blind-your-eye", [4], "4 rounds", "DR6"],
		["aegis-of-sorrow", [3, 5], "8 extra HP", "10 rounds"],
		["grace-for-a-sinner", [5], "+5", "one roll"],
		["bestial-speech", [17], "17 minutes", "animals"],
		["false-dawn-nights-chariot", [3, 6, 8], "17 minutes", "pitch black"],
		["hermetic-step", [3, 8], "11 minutes", "traps"],
		["death", [2, 4, 6, 8], "20 HP", "allocation"],
		["unmet-fate", [], "restored HP", "week"],
		["whispers-pass-the-gate", [], "three questions", "deceased"]]
	for example in examples:
		var host := _host(example[0])
		var sdk := SDK.new(host)
		var start := await sdk.system_actions.submit("power.start", _cast_input())
		assert_str(start.value.state).override_failure_message(str(example[0])).is_equal("pending")
		if start.value.state != "pending":
			continue
		host.roll("cast", [11])
		var outcome := await sdk.system_actions.submit("power.advance", {"id": "cast"})
		if not example[1].is_empty():
			assert_str(outcome.value.state).override_failure_message(str(example[0])).is_equal("pending")
			if outcome.value.state != "pending":
				continue
			host.roll(host.last_request, example[1])
			outcome = await sdk.system_actions.submit("power.advance", {"id": "cast"})
		assert_str(outcome.value.state).is_equal("resolved")
		assert_str(str(host.reports[-1])).contains(example[2]).contains(example[3])
		assert_int(host.actors.hero.data.power_uses).is_equal(2)
		assert_int(host.actors.hero.data.hit_points).is_equal(7)
		assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_lightning_reports_each_bolt_without_assigning_damage() -> void:
	var host := _host("nine-violet-signs-unknot-the-storm")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Bolts (d2)", "faces": 4, "count": 1}])
	host.roll(host.last_request, [4])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Bolt damage", "faces": 6, "count": 2}])
	host.roll(host.last_request, [2, 5])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(str(host.reports[-1])).contains("2 bolts").contains("2, 5").contains("allocation")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_restrictions_and_unfinished_powers_refuse_before_any_throw() -> void:
	for restriction in ["uses", "viewer", "illiterate", "armor", "zweihand", "dizzy", "unowned", "palms-open-the-southern-gate", "grace-of-a-dead-saint", "roskoes-consuming-glare", "foul-psychompomp"]:
		var host := _host(restriction if restriction.contains("-") else "tongue-of-eris")
		var input := _cast_input()
		match restriction:
			"uses": host.actors.hero.data.power_uses = 0
			"viewer": host.actors.hero.access_level = "Viewer"
			"illiterate": host.actors.hero.data["class_id"] = "fanged-deserter"
			"armor": host.actors.hero.data.inventory.append({"kind": "Armor", "armor_tier": 2, "equipped": true})
			"zweihand": host.actors.hero.data.inventory[0].source_item_id = "zweihander"
			"dizzy": input.eligible = false
			"unowned": host.actors.hero.data.inventory[-1].quantity = 0
		var outcome := await SDK.new(host).system_actions.submit("power.start", input)
		assert_str(outcome.value.state).override_failure_message(restriction).is_equal("error")
		assert_bool(host.requests.is_empty()).override_failure_message(restriction).is_true()
	var priest := _host()
	priest.actors.hero.data["class_id"] = "heretical-priest"
	priest.actors.hero.data.inventory.append({"kind": "Armor", "armor_tier": 2, "equipped": true})
	var allowed := await SDK.new(priest).system_actions.submit("power.start", _cast_input())
	assert_str(allowed.value.state).is_equal("pending")

func test_every_target_is_validated_at_authored_range_without_private_data() -> void:
	var host := _host()
	host.rooks["farther"] = "enemy"
	host.targets = PackedStringArray(["enemy-rook", "farther"])
	host.distances = {"enemy-rook": 9.1440011, "farther": 12.0}
	var result := await SDK.new(host).system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).is_equal("error")
	assert_str(result.value.message).is_equal("target Hooded stranger not in range\ntarget Hooded stranger not in range")
	assert_bool(host.requests.is_empty()).is_true()
	assert_int(host.reports.size()).is_equal(1)
	assert_str(str(host.reports)).not_contains("Seth")
	await SDK.new(host).system_actions.submit("power.start", _cast_input())
	assert_int(host.reports.size()).is_equal(1)
	host.targets = PackedStringArray(["enemy-rook"])
	host.distances = {"enemy-rook": 9.144}
	result = await SDK.new(host).system_actions.submit("power.start", _cast_input("edge"))
	assert_str(result.value.state).is_equal("pending")
	var self_cast := _host("lucy-fires-levitation")
	self_cast.targets = PackedStringArray()
	var input := _cast_input()
	input.rook = ""
	result = await SDK.new(self_cast).system_actions.submit("power.start", input)
	assert_str(result.value.state).is_equal("pending")

func test_daily_allowance_is_an_explicit_human_throw_and_never_a_timer() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var input := _cast_input("morning")
	input["morning_confirmed"] = true
	var result := await sdk.system_actions.submit("power.daily", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.morning.terms).is_equal([{"name": "Daily uses + Presence", "faces": 4, "count": 1}])
	host.roll("morning", [3])
	result = await sdk.system_actions.submit("power.advance", {"id": "morning"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.power_uses).is_equal(4)
	await sdk.system_actions.submit("power.advance", {"id": "morning"})
	assert_int(host.reports.size()).is_equal(1)

func test_interruption_preserves_accepted_use_and_refuses_late_parameters() -> void:
	var host := _host("aegis-of-sorrow")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	var request: String = host.last_request
	await sdk.system_actions.submit("power.cancel", {"id": "cast"})
	host.roll(request, [6, 6])
	var ended := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(ended.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_int(host.reports.size()).is_equal(2)
	var disconnected := _host()
	await SDK.new(disconnected).system_actions.submit("power.start", _cast_input())
	disconnected.sessions = []
	disconnected.roll("cast", [20])
	ended = await SDK.new(disconnected).system_actions.submit("power.advance", {"id": "cast"})
	assert_str(ended.value.state).is_equal("ended")
	assert_int(disconnected.actors.hero.data.power_uses).is_equal(3)

func test_eyelid_selects_the_rolled_count_and_uses_gm_creature_resistance() -> void:
	var host := _host("eyelid-blinds-the-mind")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [2])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("targets")
	if result.value.state != "targets":
		return
	assert_str(result.value.message).contains("2")
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	result = await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(result.value.state).is_equal("pending")
	assert_str(host.requests[host.last_request].participant).is_equal("gm")
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Creature resistance DR14", "faces": 20, "count": 1}])
	host.roll(host.last_request, [13])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(str(host.reports[-1])).contains("Hooded stranger").contains("13").contains("asleep for one hour").contains("PC ability").contains("DR14").not_contains("Seth")
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_owner_routing_malformed_inputs_and_failed_commits() -> void:
	for field in ["source", "rook", "item", "eligible", "modifier"]:
		var host := _host()
		var input := _cast_input()
		input[field] = []
		var refused := await SDK.new(host).system_actions.submit("power.start", input)
		assert_str(refused.value.state).is_equal("error")
		assert_bool(host.requests.is_empty()).is_true()
	var gm := _host()
	gm.participant = "gm"
	gm.session = "gm-session"
	gm.game_master = true
	gm.access_entries = [{"participant_id": "player", "session_id": "player-session", "access_level": "Owner", "is_connected": true, "display_name": "Player"}]
	await SDK.new(gm).system_actions.submit("power.start", _cast_input())
	assert_str(gm.requests.cast.participant).is_equal("player")
	gm.access_entries[0].access_level = "Viewer"
	gm.roll("cast", [11])
	var ended := await SDK.new(gm).system_actions.submit("power.advance", {"id": "cast"})
	assert_str(ended.value.state).is_equal("ended")
	assert_int(gm.actors.hero.data.power_uses).is_equal(3)
	var failure := _host()
	await SDK.new(failure).system_actions.submit("power.start", _cast_input())
	failure.roll("cast", [11])
	failure.fail_commit = true
	ended = await SDK.new(failure).system_actions.submit("power.advance", {"id": "cast"})
	assert_str(ended.value.state).is_equal("ended")
	assert_int(failure.actors.hero.data.power_uses).is_equal(3)
	assert_bool(failure.reports.is_empty()).is_true()

func test_all_twenty_core_scrolls_have_an_explicit_playable_boundary() -> void:
	var expected := ["palms-open-the-southern-gate", "tongue-of-eris", "te-le-kin-esis", "lucy-fires-levitation", "daemon-of-capillaries", "nine-violet-signs-unknot-the-storm", "metzhuotl-blind-your-eye", "foul-psychompomp", "eyelid-blinds-the-mind", "death", "grace-of-a-dead-saint", "grace-for-a-sinner", "whispers-pass-the-gate", "aegis-of-sorrow", "unmet-fate", "bestial-speech", "false-dawn-nights-chariot", "hermetic-step", "roskoes-consuming-glare", "enochian-syntax"]
	for id in expected:
		var host := _host(id)
		var result := await SDK.new(host).system_actions.submit("power.start", _cast_input())
		if id in ["palms-open-the-southern-gate", "grace-of-a-dead-saint", "roskoes-consuming-glare", "foul-psychompomp"]:
			assert_str(result.value.state).is_equal("error")
			assert_str(result.value.message).contains("not playable yet")
		else:
			assert_str(result.value.state).override_failure_message(id).is_equal("pending")
	var commands := _host("enochian-syntax")
	await SDK.new(commands).system_actions.submit("power.start", _cast_input())
	commands.roll("cast", [11])
	await SDK.new(commands).system_actions.submit("power.advance", {"id": "cast"})
	assert_str(str(commands.reports[-1])).contains("single command")
