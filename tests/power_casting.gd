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

func test_palms_applies_independent_damage_after_armor_and_shield_once() -> void:
	var host := _host("palms-open-the-southern-gate")
	host.actors.hero.data.inventory.append({"inventory_id": "armor", "kind": "Armor", "reduction": "d6", "armor_tier": 1, "quantity": 1, "equipped": true})
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "kind": "Shield", "quantity": 1, "equipped": true})
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Creatures (d2)", "faces": 4, "count": 1}])
	host.roll(host.last_request, [4])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.message).contains("exactly 2")
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	result = await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(result.value.state).is_equal("pending")
	assert_array(host.requests[host.last_request].terms).is_equal([
		{"name": "1. Hooded stranger · damage", "faces": 8, "count": 1},
		{"name": "1. Hooded stranger · armor", "faces": 4, "count": 1},
		{"name": "2. Creature · damage", "faces": 8, "count": 1},
		{"name": "2. Creature · armor", "faces": 6, "count": 1}])
	host.roll(host.last_request, [6, 3, 3, 6])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.outcome).is_equal("Damage applied")
	assert_int(host.actors.enemy.data.hit_points).is_equal(2)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(1)
	assert_str(str(host.reports[-1])).contains("Hooded stranger: lost 4 HP").contains("Creature: lost 0 HP").contains("armor 2").contains("shield 1").contains("halved").not_contains("Seth")
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.enemy.data.hit_points).is_equal(2)
	assert_int(host.reports.size()).is_equal(2)

func test_grace_heals_each_chosen_actor_once_after_rolled_target_count() -> void:
	var host := _host("grace-of-a-dead-saint")
	host.actors.hero.data["maximum_hit_points"] = 9
	host.actors.enemy.data["maximum_hit_points"] = 12
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Creatures (d2)", "faces": 4, "count": 1}])
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	host.roll(host.last_request, [3])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("targets")
	assert_str(result.value.message).contains("exactly 2")
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	result = await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(result.value.state).is_equal("pending")
	assert_array(host.requests[host.last_request].terms).is_equal([
		{"name": "1. Hooded stranger · healing", "faces": 10, "count": 1},
		{"name": "2. Creature · healing", "faces": 10, "count": 1}])
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	host.roll(host.last_request, [4, 8])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(10)
	assert_int(host.actors.hero.data.hit_points).is_equal(9)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_str(str(host.reports[-1])).contains("Hooded stranger: regained 4 HP").contains("regained 2 HP").not_contains("Seth")
	assert_str(str(result.value)).not_contains("maximum_hit_points").not_contains("Seth")
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_int(host.reports.size()).is_equal(2)
	assert_int(host.actors.enemy.data.hit_points).is_equal(10)

func test_palms_uses_only_equipped_intact_protection_and_preserves_zero_hp_boundary(condition: String, _test_parameters := [["shield"], ["broken"], ["unequipped"], ["empty"]]) -> void:
	var host := _host("palms-open-the-southern-gate")
	host.targets = PackedStringArray(["hero-rook"])
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "kind": "Shield", "quantity": 0 if condition == "empty" else 1, "equipped": condition != "unequipped", "broken": condition == "broken"})
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [1])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "1. Creature · damage", "faces": 8, "count": 1}])
	host.roll(host.last_request, [8])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).override_failure_message(condition).is_equal(0 if condition == "shield" else -1)

func test_palms_changed_armor_discards_the_whole_set_without_reapplying_late_rolls() -> void:
	var host := _host("palms-open-the-southern-gate")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [3])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.targets = PackedStringArray(["hero-rook", "enemy-rook"])
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	host.actors.enemy.data.armor.reduction = "d6"
	host.roll(host.last_request, [8, 7, 1])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	host.actors.enemy.data.armor.reduction = "d2"
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

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

func test_roskoe_rolls_independent_hp_loss_for_four_targets_without_armor() -> void:
	var host := _host("roskoes-consuming-glare")
	for index in 3:
		var id := "extra-%d" % index
		host.actors[id] = host.actors.enemy.duplicate(true)
		host.actors[id].id = id
		host.actors[id].public_label = "Stranger %d" % index
		host.rooks[id] = id
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [4])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.message).contains("exactly 4")
	host.targets = PackedStringArray(["enemy-rook", "extra-0", "extra-1", "extra-2"])
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_int(host.requests[host.last_request].terms.size()).is_equal(4)
	for term in host.requests[host.last_request].terms:
		assert_int(term.faces).is_equal(8)
		assert_int(term.count).is_equal(1)
	host.roll(host.last_request, [1, 3, 6, 8])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(5)
	assert_int(host.actors["extra-0"].data.hit_points).is_equal(3)
	assert_int(host.actors["extra-1"].data.hit_points).is_equal(0)
	assert_int(host.actors["extra-2"].data.hit_points).is_equal(-2)
	assert_str(str(host.reports[-1])).contains("Stranger 2: lost 8 HP").not_contains("Seth")
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.reports.size()).is_equal(2)

func test_hp_targets_revalidate_the_entire_confirmed_set_before_commit() -> void:
	var host := _host("roskoes-consuming-glare")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [2])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	# Changing shared targeting cannot redirect dice already assigned to Actors.
	host.targets = PackedStringArray(["hero-rook"])
	host.distances = {"enemy-rook": 10.0, "hero-rook": 0.0}
	host.roll(host.last_request, [4, 5])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("ended")
	assert_str(str(host.reports)).contains("target Hooded stranger not in range")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	host.distances.clear()
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

func test_immediate_target_count_and_hp_data_are_validated_before_requesting_dice(invalid: String, _test_parameters := [["too-many"], ["hp"], ["maximum"], ["dead"], ["no-maximum"]]) -> void:
	var host := _host("grace-of-a-dead-saint")
	host.actors.enemy.data["maximum_hit_points"] = 12
	if invalid == "too-many":
		for index in 3:
			var id := "extra-%d" % index
			host.actors[id] = host.actors.enemy.duplicate(true)
			host.actors[id].id = id
			host.rooks[id] = id
		host.targets = PackedStringArray(["extra-0", "extra-1", "extra-2"])
	elif invalid == "hp":
		host.actors.enemy.data.hit_points = "bad"
	elif invalid == "dead":
		host.actors.enemy.data.hit_points = -1
	elif invalid == "no-maximum":
		host.actors.enemy.data.maximum_hit_points = 0
	else:
		host.actors.enemy.data.maximum_hit_points = "bad"
	var result := await SDK.new(host).system_actions.submit("power.start", _cast_input())
	assert_str(result.value.state).override_failure_message(invalid).is_equal("error")
	assert_bool(host.requests.is_empty()).is_true()
	assert_int(host.actors.hero.data.power_uses).is_equal(3)

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

func test_immediate_corrections_interruption_and_atomic_refusal(failure: String, _test_parameters := [["count"], ["duplicate"], ["range"], ["cancel"], ["disconnect"], ["owner"], ["relink"], ["malformed"], ["save"]]) -> void:
	var host := _host("roskoes-consuming-glare")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [2])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	if failure in ["count", "duplicate", "range"]:
		if failure == "count":
			host.targets = PackedStringArray(["enemy-rook"])
		elif failure == "duplicate":
			host.rooks["other-rook"] = "enemy"
			host.targets = PackedStringArray(["enemy-rook", "other-rook"])
		else:
			host.distances = {"enemy-rook": 12.0, "hero-rook": 14.0}
		var invalid := await sdk.system_actions.submit("power.targets", {"id": "cast"})
		assert_str(invalid.value.state).is_equal("targets")
		if failure == "range":
			assert_str(invalid.value.message).is_equal("target Hooded stranger not in range\ntarget Creature not in range")
		assert_int(host.requests.size()).is_equal(2)
		assert_int(host.actors.hero.data.power_uses).is_equal(2)
		host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
		host.distances.clear()
	var selected := await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(selected.value.state).is_equal("pending")
	var request: String = host.last_request
	await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_int(host.requests.size()).is_equal(3)
	match failure:
		"cancel": await sdk.system_actions.submit("power.cancel", {"id": "cast"})
		"disconnect": host.sessions = []
		"owner": host.actors.hero.access_level = "Viewer"
		"relink": host.rooks["enemy-rook"] = "hero"
		"malformed": host.actors.hero.data.hit_points = "bad"
		"save": host.fail_commit = true
	host.roll(request, [3, 4])
	var result := await sdk.system_actions.submit("power.advance", {"id": "cast"})
	if failure in ["count", "duplicate", "range"]:
		assert_str(result.value.state).is_equal("resolved")
		assert_int(host.actors.enemy.data.hit_points).is_equal(3)
		assert_int(host.actors.hero.data.hit_points).is_equal(3)
	else:
		assert_str(result.value.state).override_failure_message(failure).is_equal("ended")
		assert_int(host.actors.enemy.data.hit_points).is_equal(6)
		if failure != "malformed":
			assert_int(host.actors.hero.data.hit_points).is_equal(7)
		assert_str(str(host.reports)).not_contains("HP loss applied")
		var retry := await sdk.system_actions.submit("power.advance", {"id": "cast"})
		assert_str(retry.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.power_uses).is_equal(2)
	assert_str(str(host.reports)).not_contains("Seth")

func test_shared_and_long_public_labels_keep_per_target_dice_distinct(long_name: bool, _test_parameters := [[false], [true]]) -> void:
	var label := "𐀀".repeat(80) if long_name else "Hooded stranger"
	var host := _host("roskoes-consuming-glare")
	host.actors.hero.public_label = label
	host.actors.enemy.public_label = label
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [2])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.targets = PackedStringArray(["enemy-rook", "hero-rook"])
	var result := await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll(host.last_request, [3, 5])
	result = await sdk.system_actions.submit("power.advance", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(3)
	assert_int(host.actors.hero.data.hit_points).is_equal(2)

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
	for restriction in ["uses", "viewer", "illiterate", "armor", "zweihand", "dizzy", "unowned", "foul-psychompomp"]:
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

func test_eyelid_pc_only_outcome_reports_manual_test_and_one_hour() -> void:
	var host := _host("eyelid-blinds-the-mind")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("power.start", _cast_input())
	host.roll("cast", [11])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.roll(host.last_request, [1])
	await sdk.system_actions.submit("power.advance", {"id": "cast"})
	host.targets = PackedStringArray(["hero-rook"])
	var result := await sdk.system_actions.submit("power.targets", {"id": "cast"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(str(host.reports[-1])).contains("one hour").contains("PC ability").contains("DR14")

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
		if id in ["foul-psychompomp"]:
			assert_str(result.value.state).is_equal("error")
			assert_str(result.value.message).contains("not playable yet")
		else:
			assert_str(result.value.state).override_failure_message(id).is_equal("pending")
	var commands := _host("enochian-syntax")
	await SDK.new(commands).system_actions.submit("power.start", _cast_input())
	commands.roll("cast", [11])
	await SDK.new(commands).system_actions.submit("power.advance", {"id": "cast"})
	assert_str(str(commands.reports[-1])).contains("single command")
