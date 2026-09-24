extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.merge({"hit_points": 4, "maximum_hit_points": 9, "omens": 0, "silver": 10, "class_id": "classless", "traits": []}, true)
	host.actors.hero.data.abilities = {"Agility": {"modifier": -3}, "Presence": {"modifier": 1}, "Strength": {"modifier": 3}, "Toughness": {"modifier": 6}}
	return host

func _options(kind: String = "rest") -> Dictionary:
	return {"id": "health", "source": "hero", "kind": kind, "eligible": true, "rest": "breath", "food_and_drink": true, "infected": false}

func test_recovery_uses_human_throw_caps_hp_and_keeps_omens() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("health.start", _options())
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.health.terms).is_equal([{"name": "Recovery", "faces": 4, "count": 1}])
	assert_str(host.requests.health.participant).is_equal("player")
	host.roll("health", [4])
	result = await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(8)
	assert_int(host.actors.hero.data.omens).is_equal(0)
	assert_str(str(host.reports)).contains("regained 4 HP").contains("Raw Roll #1")
	await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_int(host.reports.size()).is_equal(1)

func _gm(host: BOUNDARY, enabled: bool) -> void:
	host.game_master = enabled
	host.participant = "gm" if enabled else "player"
	host.session = "gm-session" if enabled else "player-session"

func test_improvement_requires_gm_grant_and_applies_ordered_steps() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var input := _options("improve")
	var result := await sdk.system_actions.submit("health.start", input)
	assert_str(result.value.state).is_equal("error")
	assert_int(host.requests.size()).is_equal(0)
	_gm(host, true)
	result = await sdk.system_actions.submit("health.start", {"id": "grant", "source": "hero", "kind": "authorize", "eligible": true})
	assert_str(result.value.state).is_equal("resolved")
	_gm(host, false)
	input.id = "improvement"
	result = await sdk.system_actions.submit("health.start", input)
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.improvement.terms).is_equal([{"name": "More HP", "faces": 10, "count": 6}])
	host.roll("improvement", [1, 1, 1, 2, 2, 2])
	await sdk.system_actions.submit("health.advance", {"id": "improvement"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Maximum HP increase", "faces": 6, "count": 1}])
	host.roll(host.last_request, [4])
	await sdk.system_actions.submit("health.advance", {"id": "improvement"})
	assert_int(host.actors.hero.data.maximum_hit_points).is_equal(13)
	assert_int(host.actors.hero.data.hit_points).is_equal(4)
	host.roll(host.last_request, [4])
	await sdk.system_actions.submit("health.advance", {"id": "improvement"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Silver", "faces": 10, "count": 3}])
	host.roll(host.last_request, [2, 3, 4])
	await sdk.system_actions.submit("health.advance", {"id": "improvement"})
	assert_int(host.actors.hero.data.silver).is_equal(19)
	host.roll(host.last_request, [1, 2, 2, 6])
	result = await sdk.system_actions.submit("health.advance", {"id": "improvement"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.abilities.Agility.modifier).is_equal(-3)
	assert_int(host.actors.hero.data.abilities.Presence.modifier).is_equal(2)
	assert_int(host.actors.hero.data.abilities.Strength.modifier).is_equal(2)
	assert_int(host.actors.hero.data.abilities.Toughness.modifier).is_equal(6)
	assert_int(host.actors.hero.data.omens).is_equal(0)
	assert_str(str(host.reports)).contains("Maximum HP").contains("Silver").contains("Agility")

func test_broken_reports_delayed_recovery_without_healing(branch: int, values: Array, copy: String, _test_parameters := [[1, [3, 4], "awaken with 4 HP after 3 rounds"], [2, [6, 2, 3], "Lost eye"], [3, [3], "death in 2 hours"], [4, [], "Dead"]]) -> void:
	var host := _host()
	host.actors.hero.data.hit_points = 0
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("health.start", _options("broken"))
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.health.terms).is_equal([{"name": "Broken", "faces": 4, "count": 1}])
	host.roll("health", [branch])
	result = await sdk.system_actions.submit("health.advance", {"id": "health"})
	if not values.is_empty():
		assert_str(result.value.state).is_equal("pending")
		host.roll(host.last_request, values)
		result = await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(result.value.message).contains(copy)
	assert_int(host.actors.hero.data.hit_points).is_equal(0)
	assert_bool(host.actors.hero.data.has("conditions")).is_false()

func _begin_improvement(host: BOUNDARY, id: String = "health") -> SDK.DataResult:
	var sdk := SDK.new(host)
	_gm(host, true)
	await sdk.system_actions.submit("health.start", {"id": id + "-grant", "source": "hero", "kind": "authorize", "eligible": true})
	_gm(host, false)
	var input := _options("improve")
	input.id = id
	return await sdk.system_actions.submit("health.start", input)

func _through_debris(host: BOUNDARY, value: int) -> SDK.DataResult:
	var sdk := SDK.new(host)
	host.actors.hero.data.maximum_hit_points = 70
	await _begin_improvement(host)
	host.roll("health", [10, 10, 10, 10, 10, 10])
	await sdk.system_actions.submit("health.advance", {"id": "health"})
	host.roll(host.last_request, [value])
	return await sdk.system_actions.submit("health.advance", {"id": "health"})

func test_found_scroll_is_chosen_in_rolled_family_and_added_before_abilities() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await _through_debris(host, 5)
	assert_str(result.value.state).is_equal("scroll")
	assert_str(result.value.get("family", "")).is_equal("unclean")
	result = await sdk.system_actions.submit("health.choose", {"id": "health", "scroll": "palms-open-the-southern-gate"})
	assert_str(result.value.state).is_equal("pending")
	assert_str(str(host.actors.hero.data.inventory)).contains("palms-open-the-southern-gate")
	assert_int(host.actors.hero.data.inventory[-1].quantity).is_equal(1)
	assert_bool(host.actors.hero.data.inventory[-1].get("single_use", false)).is_false()

func test_scum_first_improvement_adds_specialty_then_later_allows_optional_reroll() -> void:
	var host := _host()
	host.actors.hero.data.class_id = "gutterborn-scum"
	host.actors.hero.data.traits = [{"id": "cowards-jab", "name": "Coward's jab"}]
	var sdk := SDK.new(host)
	await _through_debris(host, 1)
	host.roll(host.last_request, [2, 2, 3, 6])
	var result := await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "New specialty", "faces": 6, "count": 1}])
	host.roll(host.last_request, [6])
	result = await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(host.actors.hero.data.traits[1].id).is_equal("dodging-death")
	await _begin_improvement(host, "second")
	host.roll("second", [1, 1, 1, 1, 1, 1])
	await sdk.system_actions.submit("health.advance", {"id": "second"})
	host.roll(host.last_request, [1])
	await sdk.system_actions.submit("health.advance", {"id": "second"})
	host.roll(host.last_request, [2, 2, 2, 2])
	result = await sdk.system_actions.submit("health.advance", {"id": "second"})
	assert_str(result.value.state).is_equal("specialties")
	result = await sdk.system_actions.submit("health.choose", {"id": "second", "reroll": [0]})
	assert_str(result.value.state).is_equal("pending")
	host.roll(host.last_request, [2])
	result = await sdk.system_actions.submit("health.advance", {"id": "second"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(host.actors.hero.data.traits[0].id).is_equal("filthy-fingersmith")
	assert_str(host.actors.hero.data.traits[1].id).is_equal("dodging-death")
	assert_int(host.actors.hero.data.inventory.size()).is_equal(1)

func test_rest_restrictions_and_sleep(food: bool, infected: bool, hp: int, expected: String, _test_parameters := [[false, false, 4, "resolved"], [true, true, 4, "resolved"], [true, false, -1, "error"], [true, false, 7, "pending"]]) -> void:
	var host := _host()
	host.actors.hero.data.hit_points = hp
	var sdk := SDK.new(host)
	var input := _options()
	input.rest = "sleep"
	input.food_and_drink = food
	input.infected = infected
	var result := await sdk.system_actions.submit("health.start", input)
	assert_str(result.value.state).is_equal(expected)
	if expected == "pending":
		assert_int(host.requests.health.terms[0].faces).is_equal(6)
		host.roll("health", [6])
		await sdk.system_actions.submit("health.advance", {"id": "health"})
		assert_int(host.actors.hero.data.hit_points).is_equal(9)
	else:
		assert_int(host.requests.size()).is_equal(0)
		assert_int(host.actors.hero.data.hit_points).is_equal(hp)
		if expected == "resolved":
			assert_str(str(host.reports)).contains("No HP restored").contains("daily")

func test_owner_eligibility_and_real_gm_identity_are_required(case: String, _test_parameters := [["viewer"], ["eligibility"], ["forged_grant"], ["malformed"]]) -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var input := _options()
	if case == "viewer":
		host.actors.hero.access_level = "Viewer"
	elif case == "eligibility":
		input.eligible = false
	elif case == "forged_grant":
		input.kind = "authorize"
		input["is_gm"] = true
	else:
		input.food_and_drink = "true"
	var result := await sdk.system_actions.submit("health.start", input)
	assert_str(result.value.state).is_equal("error")
	assert_int(host.requests.size()).is_equal(0)
	assert_int(host.reports.size()).is_equal(0)
	assert_bool(host.actors.hero.data.has("improvement_grant")).is_false()

func test_interruption_rejects_late_changes_and_preserves_accepted_improvement(cause: String, _test_parameters := [["cancel"], ["disconnect"], ["access"], ["restart"], ["save"]]) -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await _begin_improvement(host)
	host.roll("health", [3, 3, 3, 3, 3, 3])
	await sdk.system_actions.submit("health.advance", {"id": "health"})
	host.roll(host.last_request, [5])
	await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_int(host.actors.hero.data.maximum_hit_points).is_equal(14)
	var unfinished := host.last_request
	if cause == "cancel":
		await sdk.system_actions.submit("health.cancel", {"id": "health"})
	elif cause == "disconnect":
		host.sessions[0].session_id = "new-player-session"
	elif cause == "access":
		host.actors.hero.access_level = "Viewer"
	elif cause == "save":
		host.fail_commit = true
	else:
		host.handler = auto_free(SYSTEM.new())
		add_child(host.handler)
	host.roll(unfinished, [4])
	var count: int = host.requests.size()
	var result := await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.requests.size()).is_equal(count)
	assert_int(host.actors.hero.data.maximum_hit_points).is_equal(14)
	assert_int(host.actors.hero.data.silver).is_equal(10)
	assert_str(host.requests[unfinished].result.status).is_equal("rolled")
	assert_str(host.actors.hero.data.improvement_grant).is_empty()

func test_broken_requires_zero_and_negative_hp_reports_death(hp: int, expected: String, _test_parameters := [[5, "error"], [-2, "resolved"]]) -> void:
	var host := _host()
	host.actors.hero.data.hit_points = hp
	var result := await SDK.new(host).system_actions.submit("health.start", _options("broken"))
	assert_str(result.value.state).is_equal(expected)
	assert_int(host.requests.size()).is_equal(0)
	assert_int(host.actors.hero.data.hit_points).is_equal(hp)
	if hp < 0:
		assert_str(result.value.message).contains("Dead")

func test_ability_changes_apply_source_boundaries(before: int, die: int, expected: int, _test_parameters := [[-3, 1, -3], [-3, 2, -2], [-1, 1, -2], [0, 1, -1], [1, 1, 0], [1, 2, 2], [2, 1, 1], [2, 2, 3], [5, 4, 4], [6, 6, 6]]) -> void:
	var host := _host()
	host.actors.hero.data.abilities.Agility.modifier = before
	var sdk := SDK.new(host)
	await _through_debris(host, 3)
	host.roll(host.last_request, [die, 2, 3, 6])
	var result := await sdk.system_actions.submit("health.advance", {"id": "health"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.abilities.Agility.modifier).is_equal(expected)

func test_gm_routes_recovery_to_connected_player_and_cannot_replace_offline_owner() -> void:
	var host := _host()
	_gm(host, true)
	host.access_entries = [{"participant_id": "player", "session_id": "player-session", "display_name": "Player", "access_level": "Owner", "is_connected": true}]
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("health.start", _options())
	assert_str(result.value.state).is_equal("pending")
	assert_str(host.requests.health.participant).is_equal("player")
	await sdk.system_actions.submit("health.cancel", {"id": "health"})
	host.access_entries[0].is_connected = false
	var input := _options()
	input.id = "offline"
	result = await sdk.system_actions.submit("health.start", input)
	assert_str(result.value.state).is_equal("error")
	assert_int(host.requests.size()).is_equal(1)

func test_interrupted_scum_can_finish_with_ordinary_sheet_corrections() -> void:
	var host := _host()
	host.actors.hero.data.class_id = "gutterborn-scum"
	host.actors.hero.data.traits = [{"id": "cowards-jab", "name": "Coward's jab"}]
	var sdk := SDK.new(host)
	await _begin_improvement(host)
	await sdk.system_actions.submit("health.cancel", {"id": "health"})
	var edits = load(ROOT + "logic/character_actions.gd").new(sdk, SDK.ActorId.new("hero"))
	var result: SDK.ActorResult = await edits.correct("scum_specialty:1", "6")
	assert_bool(result.ok).is_true()
	if not result.ok:
		return
	assert_str(host.actors.hero.data.traits[1].id).is_equal("dodging-death")
	var next := await _begin_improvement(host, "next")
	assert_str(next.value.state).is_equal("pending")
