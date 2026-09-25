extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/encounter_sdk_boundary.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.abilities.Agility = {"modifier": 2}
	host.actors.enemy.data.morale = {"kind": "fixed", "value": 7}
	return host

func test_gm_roster_round_and_current_turn_are_saved_without_actor_changes() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	assert_str(result.value.state).is_equal("resolved")
	if result.value.state != "resolved":
		return
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "add", "actor": "enemy", "side": "enemy"})
	var actors := host.actors.duplicate(true)
	await sdk.system_actions.submit("encounter.edit", {"revision": 2, "kind": "begin"})
	assert_int(host.world_data.encounter.round).is_equal(1)
	assert_str(host.world_data.encounter.current).is_equal("hero")
	await sdk.system_actions.submit("encounter.edit", {"revision": 3, "kind": "next"})
	assert_str(host.world_data.encounter.current).is_equal("enemy")
	await sdk.system_actions.submit("encounter.edit", {"revision": 4, "kind": "next"})
	assert_int(host.world_data.encounter.round).is_equal(2)
	assert_dict(host.actors).is_equal(actors)
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	result = await sdk.system_actions.submit("encounter.edit", {"revision": 5, "kind": "correct", "round": 7, "current": "enemy"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.world_data.encounter.round).is_equal(7)
	assert_str(host.world_data.encounter.current).is_equal("enemy")
	assert_str(host.world_data.unrelated).is_equal("retained")

func test_group_initiative_requests_gm_d6_and_sorts_sides() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "add", "actor": "enemy", "side": "enemy"})
	var result := await sdk.system_actions.submit("encounter.roll", {"revision": 2, "id": "initiative", "kind": "group"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.initiative.terms).is_equal([{"name": "Initiative", "faces": 6, "count": 1}])
	assert_str(host.requests.initiative.participant).is_equal("gm")
	host.roll("initiative", [3])
	result = await sdk.system_actions.submit("encounter.advance", {"id": "initiative"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(host.world_data.encounter.entries[0].actor).is_equal("enemy")
	assert_str(str(host.reports)).contains("Enemies go first").contains("Raw Roll #1")
	await sdk.system_actions.submit("encounter.advance", {"id": "initiative"})
	assert_int(host.world_data.encounter.revision).is_equal(3)

func test_reaction_table_uses_two_d6(a: int, b: int, expected: String, _test_parameters := [[1, 1, "Kill!"], [1, 3, "Angered"], [3, 4, "Indifferent"], [4, 5, "Almost friendly"], [5, 6, "Helpful"]]) -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("encounter.roll", {"revision": 0, "id": "reaction", "kind": "reaction", "actor": "enemy"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.reaction.terms).is_equal([{"name": "Reaction", "faces": 6, "count": 2}])
	host.roll("reaction", [a, b])
	result = await sdk.system_actions.submit("encounter.advance", {"id": "reaction"})
	assert_str(result.value.message).contains(expected).contains("Hooded stranger")
	assert_str(str(host.reports)).not_contains("Seth").not_contains("armor")

func test_morale_equality_holds_and_failure_requests_flee_or_surrender(total: int, face: int, expected: String, _test_parameters := [[7, 0, "Holds"], [8, 3, "Flees"], [12, 4, "Surrenders"]]) -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("encounter.roll", {"revision": 0, "id": "morale", "kind": "morale", "actor": "enemy"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_array(host.requests.morale.terms).is_equal([{"name": "Morale", "faces": 6, "count": 2}])
	host.roll("morale", [6, total - 6])
	result = await sdk.system_actions.submit("encounter.advance", {"id": "morale"})
	if face > 0:
		assert_str(result.value.state).is_equal("pending")
		assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Flee or surrender", "faces": 6, "count": 1}])
		host.roll(host.last_request, [face])
		result = await sdk.system_actions.submit("encounter.advance", {"id": "morale"})
	assert_str(result.value.message).contains(expected).contains("Hooded stranger")
	assert_str(str(host.reports)).not_contains("Seth").not_contains("7")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_individual_initiative_uses_agility_and_wraith_always_wins() -> void:
	var host := _host()
	host.actors.enemy.data.definition_id = "wrat-wraith"
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "add", "actor": "enemy", "side": "enemy"})
	await sdk.system_actions.submit("encounter.edit", {"revision": 2, "kind": "mode", "mode": "individual"})
	var result := await sdk.system_actions.submit("encounter.roll", {"revision": 3, "id": "individual", "kind": "individual", "actor": "hero"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("individual", [6])
	await sdk.system_actions.submit("encounter.advance", {"id": "individual"})
	assert_str(host.world_data.encounter.entries[0].actor).is_equal("enemy")
	assert_int(host.world_data.encounter.entries[1].initiative).is_equal(8)

func test_unauthorized_stale_failed_and_interrupted_changes_leave_guidance_intact() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	host.game_master = false
	var result := await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	assert_str(result.value.state).is_equal("error")
	assert_bool(host.world_data.has("encounter")).is_false()
	host.game_master = true
	await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	result = await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "begin"})
	assert_str(result.value.state).is_equal("error")
	host.fail_commit = true
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "begin"})
	assert_bool(host.world_data.encounter.active).is_false()
	host.fail_commit = false
	await sdk.system_actions.submit("encounter.roll", {"revision": 1, "id": "late", "kind": "group"})
	host.roll("late", [2])
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "begin"})
	result = await sdk.system_actions.submit("encounter.advance", {"id": "late"})
	assert_str(result.value.state).is_equal("ended")
	assert_str(host.world_data.encounter.first_side).is_equal("pc")
	await sdk.system_actions.submit("encounter.roll", {"revision": 2, "id": "cancel", "kind": "group"})
	await sdk.system_actions.submit("encounter.cancel", {"id": "cancel"})
	host.roll("cancel", [1])
	result = await sdk.system_actions.submit("encounter.advance", {"id": "cancel"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.world_data.encounter.revision).is_equal(2)

func test_new_session_and_restarted_system_do_not_resume_pending_rolls() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("encounter.roll", {"revision": 0, "id": "old", "kind": "morale", "actor": "enemy"})
	host.roll("old", [6, 6])
	host.session = "reconnected"
	var result := await sdk.system_actions.submit("encounter.advance", {"id": "old"})
	assert_str(result.value.state).is_equal("error")
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	result = await sdk.system_actions.submit("encounter.roll", {"revision": 0, "id": "old", "kind": "morale", "actor": "enemy"})
	assert_str(result.value.state).is_equal("ended")
	assert_bool(host.world_data.has("encounter")).is_false()

func test_special_morale_does_not_invent_a_numeric_roll() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	host.actors.enemy.data.morale = {"kind": "special", "text": "Retreats when badly wounded"}
	var result := await sdk.system_actions.submit("encounter.roll", {"revision": 0, "id": "special", "kind": "morale", "actor": "enemy"})
	assert_str(result.value.state).is_equal("error")
	assert_dict(host.requests).is_empty()
	assert_bool(host.world_data.has("encounter")).is_false()
