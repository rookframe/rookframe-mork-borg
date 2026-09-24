extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host(item_id: String = "medicine-box") -> BOUNDARY:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.merge({"hit_points": 7, "maximum_hit_points": 9, "class_id": "classless", "traits": []}, true)
	host.actors.hero.data.abilities.merge({"Agility": {"modifier": 1}, "Presence": {"modifier": 1}, "Toughness": {"modifier": 1}})
	host.actors.hero.data.inventory.append({"source_item_id": item_id, "inventory_id": "special", "quantity": 1, "uses": 2})
	return host

func _use_input(id: String = "use") -> Dictionary:
	return {"id": id, "source": "hero", "rook": "hero-rook", "item": "special", "self": true, "eligible": true}

func test_medicine_heals_and_consumes_one_use_atomically() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", _use_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.use.terms).is_equal([{"name": "Healing", "faces": 6, "count": 1}])
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)

	host.roll("use", [5])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(9)
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	assert_str(str(host.reports)).contains("regained 2 HP").contains("infection").contains("bleeding")
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	assert_int(host.reports.size()).is_equal(1)

func test_poison_routes_resistance_and_applies_hp_loss(key: String, self_use: bool, face: int, loss: int, _test_parameters := [["poison-red", true, 10, 7], ["poison-black", false, 12, 4], ["red-poison-decoction", false, 12, 0]]) -> void:
	var host := _host(key)
	var input := _use_input()
	input.self = self_use
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_str(host.requests.use.participant).is_equal("player" if self_use else "gm")
	assert_int(host.requests.use.terms[0].faces).is_equal(20)
	host.roll("use", [face])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	if loss > 0:
		assert_str(result.value.state).is_equal("pending")
		if result.value.state != "pending":
			return
		host.roll(host.last_request, [loss])
		result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(7 - loss if self_use else 7)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6 if self_use else 6 - loss)
	if key == "poison-black":
		assert_str(result.value.message).contains("one hour").not_contains("Seth")
func test_elixir_uses_shared_doses_and_heals_private_target_at_contact() -> void:
	var host := _host("elixir-vitalis")
	host.actors.hero.data.inventory[-1].erase("uses")
	host.actors.hero.data.inventory[-1]["dose_pool"] = "portable-laboratory"
	host.actors.hero.data.inventory.append({"inventory_id": "lab", "source_item_id": "portable-laboratory", "quantity": 1, "uses": 3})
	host.actors.enemy.data["maximum_hit_points"] = 12
	var input := _use_input()
	input.self = false
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("use", [4])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(10)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)
	assert_str(str(host.reports)).contains("Hooded stranger").not_contains("Seth")

func test_wizard_teeth_request_four_dice_and_report_manual_maximum_damage() -> void:
	var host := _host("wizard-teeth")
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", _use_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.use.terms).is_equal([{"name": "Wizard teeth", "faces": 6, "count": 4}])
	host.roll("use", [6, 2, 6, 1])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(str(host.reports)).contains("2 attacks").contains("maximum damage").contains("manually")
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_printed_class_tests_resolve_without_automating_later_benefits(key: String, feature: bool, face: int, expected: String, _test_parameters := [["master-of-fate", true, 7, "right way"], ["filthy-fingersmith", true, 7, "pockets and locks"], ["list-of-sins", false, 9, "discovered"], ["horn-of-the-schleswig-lords", false, 11, "automatic success"], ["stones-taken-from-thel-emas-lost-temple", false, 8, "sunset"]]) -> void:
	var host := _host(key)
	var input := _use_input()
	if feature:
		host.actors.hero.data.traits = [{"id": key, "name": key}]
		input.item = "feature:" + key
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.use.terms[0].faces).is_equal(20)
	host.roll("use", [face])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains(expected)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	if key == "horn-of-the-schleswig-lords" or key == "stones-taken-from-thel-emas-lost-temple":
		assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)

func test_decoctions_consume_shared_pool_and_report_durations(key: String, values: Array, expected: String, _test_parameters := [["fernors-philtre", [4], "4 hours"], ["spider-owl-soup", [], "30 minutes"], ["hyphos-enervating-snuff", [], "DR14"]]) -> void:
	var host := _host(key)
	host.actors.hero.data.inventory[-1].erase("uses")
	host.actors.hero.data.inventory[-1]["dose_pool"] = "portable-laboratory"
	host.actors.hero.data.inventory.append({"inventory_id": "lab", "source_item_id": "portable-laboratory", "quantity": 1, "uses": 3})
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", _use_input())
	if not values.is_empty():
		assert_str(result.value.state).is_equal("pending")
		if result.value.state != "pending":
			return
		host.roll("use", values)
		result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains(expected).contains("manually")
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)

func test_class_parameters_and_manual_benefits(key: String, feature: bool, values: Array, expected: String, _test_parameters := [["speaker-of-truths", true, [], "lowered by 4"], ["harp", false, [3], "+3"], ["blasphemous-nechrubel-bible", false, [4], "five minutes"], ["dodging-death", true, [1, 3], "10 rounds"], ["excretal-stealth", true, [], "DR16"], ["escaping-fate", true, [], "Omen"], ["crumpled-monster-mask", false, [], "every round"]]) -> void:
	var host := _host(key)
	var input := _use_input()
	if feature:
		host.actors.hero.data.traits = [{"id": key, "uses": 2}]
		input.item = "feature:" + key
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", input)
	if not values.is_empty():
		assert_str(result.value.state).is_equal("pending")
		if result.value.state != "pending":
			return
		host.roll("use", values)
		result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains(expected)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	if key == "speaker-of-truths":
		assert_int(host.actors.hero.data.traits[0].uses).is_equal(1)
	if key == "blasphemous-nechrubel-bible":
		assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)

func test_book_creature_resistance_summons_printed_berserkers_and_spends_daily_use() -> void:
	var host := _host("book-of-boiling-blood")
	var sdk := SDK.new(host)
	var input := _use_input()
	input.self = false
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_str(host.requests.use.participant).is_equal("gm")
	host.roll("use", [11])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	host.roll(host.last_request, [4, 5])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.size()).is_equal(4)
	assert_int(host.actors['created-2'].data.hit_points).is_equal(13)
	assert_str(host.created_for).is_equal("player")
	assert_str(result.value.message).contains("turn on you").contains("after battle")
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.size()).is_equal(4)

func test_brewing_replaces_two_recipes_and_one_shared_dose_pool() -> void:
	var host := _host("portable-laboratory")
	host.actors.hero.data.class_id = "occult-herbmaster"
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", _use_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.use.terms).is_equal([{"name": "Decoctions", "faces": 8, "count": 2}, {"name": "Shared doses", "faces": 4, "count": 1}])
	host.roll("use", [4, 8, 3])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	var inventory: Array = host.actors.hero.data.inventory
	assert_int(inventory[1].uses).is_equal(3)
	assert_str(inventory[-2].source_item_id).is_equal("elixir-vitalis")
	assert_str(inventory[-1].source_item_id).is_equal("black-poison-decoction")
	assert_str(inventory[-1].dose_pool).is_equal("portable-laboratory")
	assert_bool(inventory[-1].has("uses")).is_false()
	assert_str(result.value.message).contains("24 hours").contains("manually")

func test_invisible_college_rolls_count_and_family_then_keeps_table_selected_scrolls() -> void:
	var host := _host()
	host.actors.hero.data.traits = [{"id": "initiate-of-the-invisible-college", "uses": 1}]
	var input := _use_input()
	input.item = "feature:initiate-of-the-invisible-college"
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("use", [4, 1])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("scrolls")
	assert_int(host.actors.hero.data.traits[0].uses).is_equal(0)
	result = await sdk.system_actions.submit("special.scrolls", {"id": "use", "scrolls": ["enochian-syntax", "aegis-of-sorrow"]})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(host.actors.hero.data.inventory[-2].source_item_id).is_equal("enochian-syntax")
	assert_bool(host.actors.hero.data.inventory[-2].single_use).is_true()
	assert_str(result.value.message).contains("sunrise").contains("manually")

func test_mitre_requires_wearing_and_table_selected_stealth_ability() -> void:
	var host := _host("stolen-mitre")
	var sdk := SDK.new(host)
	var input := _use_input()
	input["ability"] = "Agility"
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("error")
	host.actors.hero.data.inventory[-1]["equipped"] = true
	input.id = "wearing"
	result = await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("wearing", [7])
	result = await sdk.system_actions.submit("special.advance", {"id": "wearing"})
	assert_str(result.value.message).contains("DR8").contains("Success")

func test_crucifix_rolls_morale_with_explicit_presence_sign_and_private_label() -> void:
	var host := _host("wrong-jesus-crucifix")
	host.actors.enemy.data["morale"] = 7
	var sdk := SDK.new(host)
	var input := _use_input()
	input.self = false
	input["presence_sign"] = 1
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.use.terms[0].count).is_equal(2)
	host.roll("use", [3, 4])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains("Hooded stranger").contains("remove").not_contains("Seth")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_vapor_resistance_is_requested_with_table_chosen_ability() -> void:
	var host := _host("ezumiels-vapor")
	var sdk := SDK.new(host)
	var input := _use_input()
	input["ability"] = "Presence"
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.use.terms[0].faces).is_equal(20)
	if host.requests.use.terms[0].faces != 20:
		return
	host.roll("use", [12])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [3])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.message).contains("3 hours")
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)

func test_gob_lobber_rolls_fight_uses_spends_spit_then_routes_witness_tests() -> void:
	var host := _host()
	host.actors.hero.data.traits = [{"id": "abominable-gob-lobber"}]
	var sdk := SDK.new(host)
	var input := _use_input()
	input.item = "feature:abominable-gob-lobber"
	input.self = false
	input["new_fight"] = true
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.use.terms[0].faces).is_equal(4)
	host.roll("use", [3])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.traits[0].uses).is_equal(2)
	host.roll(host.last_request, [7])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.traits[0].uses).is_equal(1)
	host.roll(host.last_request, [4])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("witnesses")
	assert_str(result.value.message).contains("4 rounds")
	host.targets = PackedStringArray(["hero-rook", "enemy-rook"])
	result = await sdk.system_actions.submit("special.witnesses", {"id": "use", "confirmed": true})
	assert_str(host.requests[host.last_request].participant).is_equal("player")
	host.roll(host.last_request, [9])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(host.requests[host.last_request].participant).is_equal("gm")
	host.roll(host.last_request, [11])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(str(host.reports)).contains("DR10").contains("DR12").contains("vomits").not_contains("Seth")
	assert_int(host.actors.hero.data.traits[0].uses).is_equal(1)

func test_cancel_after_bible_parity_preserves_spent_use_and_logs_once() -> void:
	var host := _host("blasphemous-nechrubel-bible")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	host.roll("use", [3])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	var result := await sdk.system_actions.submit("special.cancel", {"id": "use"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(1)
	assert_str(str(host.reports)).contains("Action ended")
	var count := host.reports.size()
	await sdk.system_actions.submit("special.cancel", {"id": "use"})
	assert_int(host.reports.size()).is_equal(count)

func test_pending_action_stops_after_item_removal_and_on_source_access_loss(change: String, _test_parameters := [["item"], ["access"], ["session"]]) -> void:
	var host := _host("wizard-teeth")
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	if change == "item":
		host.actors.hero.data.inventory.pop_back()
	elif change == "access":
		host.actors.hero.access_level = "Observer"
	else:
		host.sessions[0].session_id = "replacement"
	host.roll("use", [6, 6, 6, 6])
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("ended")
	assert_str(str(host.reports)).not_contains("maximum damage").contains("Action ended")

func test_all_invalid_ranges_report_public_labels_and_roll_nothing() -> void:
	var host := _host()
	host.rooks["far-rook"] = "enemy"
	host.targets = PackedStringArray(["enemy-rook", "far-rook"])
	host.distance = 10.0
	var input := _use_input()
	input.self = false
	var result := await SDK.new(host).system_actions.submit("special.start", input)
	assert_str(result.value.message).is_equal("target Hooded stranger not in range\ntarget Hooded stranger not in range")
	assert_int(host.requests.size()).is_equal(0)
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)

func test_concurrent_actions_from_same_character_are_refused() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	var result := await sdk.system_actions.submit("special.start", _use_input("duplicate"))
	assert_str(result.value.state).is_equal("error")
	assert_int(host.requests.size()).is_equal(1)

func test_ancestors_blade_checks_treachery_then_resolves_attack_against_self() -> void:
	var host := _host("blade-of-your-ancestors")
	host.actors.hero.data.inventory[-1]["equipped"] = true
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("special.start", _use_input())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.use.terms[0].faces).is_equal(6)
	host.roll("use", [1])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [11])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [3])
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(3)
	assert_str(str(host.reports)).contains("treachery").contains("4 damage")

func test_triggered_equipment_rolls_damage_and_consumes_only_expendable_bomb(key: String, values: Array, expected: int, _test_parameters := [["bomb", [5, 2], 2], ["bear-trap", [4, 2], 3], ["caltrops", [3, 2, 1], 4]]) -> void:
	var host := _host(key)
	var sdk := SDK.new(host)
	var input := _use_input()
	input.self = false
	var result := await sdk.system_actions.submit("special.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("use", values)
	result = await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(expected)
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(0 if key == "bomb" else 1)
	if key == "caltrops":
		assert_str(result.value.message).contains("Infection")

func test_food_water_and_oil_use_prescribed_resources_without_timers(key: String, quantity: int, uses: int, text: String, _test_parameters := [["dried-food", 0, 2, "one day"], ["waterskin", 1, 1, "water"], ["lard", 1, 1, "meal"], ["lantern-oil", 0, 2, "7 hours"], ["torch", 0, 2, "Burns"]]) -> void:
	var host := _host(key)
	var result := await SDK.new(host).system_actions.submit("special.start", _use_input())
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(quantity)
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(uses)
	assert_str(result.value.message).contains(text)
	assert_int(host.requests.size()).is_equal(0)

func test_treacherous_blade_offers_existing_shield_choice_before_hp_change() -> void:
	var host := _host("blade-of-your-ancestors")
	host.actors.hero.data.inventory[-1]["equipped"] = true
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "quantity": 1, "equipped": true})
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	host.roll("use", [1])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [11])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [3])
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("shield")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	if result.value.state != "shield":
		return
	assert_int(result.value.loss).is_equal(3)
	result = await sdk.system_actions.submit("special.choose", {"id": "use", "choice": "break"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_bool(host.actors.hero.data.inventory[-1].broken).is_true()
	assert_str(str(host.reports)).contains("Shield")

func test_removed_college_ends_before_chosen_scrolls_are_created() -> void:
	var host := _host()
	host.actors.hero.data.traits = [{"id": "initiate-of-the-invisible-college", "uses": 1}]
	var input := _use_input()
	input.item = "feature:initiate-of-the-invisible-college"
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", input)
	host.roll("use", [1, 1])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.actors.hero.data.traits = []
	var result := await sdk.system_actions.submit("special.scrolls", {"id": "use", "scrolls": ["enochian-syntax"]})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.inventory.size()).is_equal(2)

func test_class_agility_tests_include_worn_armor(key: String, tier: int, expected_dr: int, _test_parameters := [["filthy-fingersmith", 2, 10], ["stolen-mitre", 3, 12]]) -> void:
	var host := _host(key)
	host.actors.hero.data.inventory[-1]["equipped"] = true
	host.actors.hero.data.inventory.append({"inventory_id": "armor", "kind": "Armor", "quantity": 1, "equipped": true, "armor_tier": tier})
	var input := _use_input()
	input["ability"] = "Agility"
	if key == "filthy-fingersmith":
		host.actors.hero.data.traits = [{"id": key}]
		input.item = "feature:" + key
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", input)
	host.roll("use", [7])
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains("DR%d" % expected_dr)

func test_special_damage_rejects_changed_protection() -> void:
	var host := _host("bomb")
	var input := _use_input()
	input.self = false
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", input)
	host.roll("use", [6, 2])
	host.actors.enemy.data.armor.reduction = "d4"
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_shield_continuation_requires_source_item_and_range(change: String, _test_parameters := [["item"], ["range"]]) -> void:
	var host := _host("blade-of-your-ancestors")
	host.actors.hero.data.inventory[-1]["equipped"] = true
	host.actors.enemy.data["creature_inventory"] = true
	host.actors.enemy.data["inventory"] = [{"inventory_id": "shield", "source_item_id": "shield", "quantity": 1, "equipped": true}]
	var input := _use_input()
	input.self = false
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", input)
	host.roll("use", [1])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [11])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	host.roll(host.last_request, [3])
	await sdk.system_actions.submit("special.advance", {"id": "use"})
	if change == "item":
		host.actors.hero.data.inventory = []
	else:
		host.distance = 8.0
	host.participant = "gm"
	host.session = "gm-session"
	host.game_master = true
	host.access_by_actor.hero = [{"participant_id": "player", "session_id": "player-session", "display_name": "Player", "is_connected": true, "access_level": "Owner"}]
	var result := await sdk.system_actions.submit("special.choose", {"id": "use", "choice": "take"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_bomb_spends_once_before_shield_and_never_refunds_on_cancel(choice: String, _test_parameters := [["break"], ["cancel"]]) -> void:
	var host := _host("bomb")
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "quantity": 1, "equipped": true})
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	host.roll("use", [5])
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("shield")
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(0)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	if result.value.state != "shield":
		return
	result = await sdk.system_actions.submit("special.cancel" if choice == "cancel" else "special.choose", {"id": "use", "choice": choice})
	assert_str(result.value.state).is_equal("ended" if choice == "cancel" else "resolved")
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(0)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

func test_taking_caltrops_damage_preserves_rolled_infection_report() -> void:
	var host := _host("caltrops")
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "quantity": 1, "equipped": true})
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("special.start", _use_input())
	host.roll("use", [4, 1])
	var result := await sdk.system_actions.submit("special.advance", {"id": "use"})
	assert_str(result.value.state).is_equal("shield")
	result = await sdk.system_actions.submit("special.choose", {"id": "use", "choice": "take"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains("Infection")
	assert_int(host.actors.hero.data.hit_points).is_equal(4)
