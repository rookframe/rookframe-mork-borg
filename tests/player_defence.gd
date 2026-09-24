extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/defence_sdk_boundary.gd")

func test_defender_receives_agility_throw_and_success_report() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	var started: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack("defence-1"))
	assert_str(started.value.state).is_equal("ready")
	if started.value.state != "ready":
		return
	assert_bool(host.requests.is_empty()).is_true()
	host.as_player()
	var inbox: SDK.DataResult = await sdk.system_actions.submit("defence.inbox", {})
	assert_int(inbox.value.size()).is_equal(1)
	if inbox.value.is_empty():
		return
	assert_str(inbox.value[0].attacker).is_equal("Hooded stranger")
	assert_bool(str(inbox.value).contains("Seth")).is_false()
	await sdk.system_actions.submit("defence.roll", {"id": "defence-1", "difficulty": 0, "modifier": 0})
	assert_str(host.requests["defence-1"].participant).is_equal("player")
	assert_array(host.requests["defence-1"].terms).is_equal([{"name": "Defence", "faces": 20, "count": 1}])
	host.roll("defence-1", [14])
	var result: SDK.DataResult = await sdk.system_actions.submit("defence.advance", {"id": "defence-1"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.requests.size()).is_equal(1)
	assert_str(host.reports[-1].result).is_equal("Defended")
	assert_bool(str(host.reports).contains("Seth")).is_false()
	await sdk.system_actions.submit("defence.advance", {"id": "defence-1"})
	assert_int(host.reports.size()).is_equal(1)

func _attack(id: String) -> Dictionary:
	return {"id": id, "source": "enemy", "rook": "enemy-rook", "attack": "knife"}

func test_failed_defence_offers_protected_damage_or_one_broken_shield() -> void:
	for choice in ["take", "break"]:
		var host := BOUNDARY.new()
		host.handler = auto_free(SYSTEM.new())
		add_child(host.handler)
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory.append({"inventory_id": "armor", "source_item_id": "light-armor", "equipped": true})
		host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true, "quantity": 1})
		await sdk.system_actions.submit("defence.start", _attack(choice))
		host.as_player()
		await sdk.system_actions.submit("defence.roll", {"id": choice, "difficulty": 0, "modifier": 0})
		host.roll(choice, [2])
		await sdk.system_actions.submit("defence.advance", {"id": choice})
		assert_int(host.requests.size()).is_equal(2)
		if host.requests.size() != 2:
			continue
		assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Damage", "faces": 4, "count": 1}, {"name": "Protection", "faces": 4, "count": 1}])
		host.roll(host.last_request, [4, 2])
		var offered: SDK.DataResult = await sdk.system_actions.submit("defence.advance", {"id": choice})
		assert_str(offered.value.state).is_equal("shield")
		assert_int(offered.value.loss).is_equal(2)
		assert_int(offered.value.hp).is_equal(7)
		assert_int(host.actors.hero.data.hit_points).is_equal(7)
		var resolved: SDK.DataResult = await sdk.system_actions.submit("defence.choose", {"id": choice, "choice": choice})
		assert_str(resolved.value.state).is_equal("resolved")
		assert_int(host.actors.hero.data.hit_points).is_equal(5 if choice == "take" else 7)
		assert_bool(host.actors.hero.data.inventory[2].get("broken", false)).is_equal(choice == "break")
		assert_bool(host.actors.hero.data.inventory[2].equipped).is_equal(choice == "take")
		var reports: int = host.reports.size()
		await sdk.system_actions.submit("defence.choose", {"id": choice, "choice": choice})
		assert_int(host.reports.size()).is_equal(reports)
		assert_bool(str(host.reports).contains("d4 halved, rounded up")).is_true()

func after_test() -> void:
	await get_tree().process_frame

func test_natural_faces_and_fumble_armor_survive_shield_cancellation() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("defence.start", _attack("critical"))
	host.as_player()
	await sdk.system_actions.submit("defence.roll", {"id": "critical", "difficulty": 30, "modifier": -20})
	host.roll("critical", [20])
	await sdk.system_actions.submit("defence.advance", {"id": "critical"})
	assert_str(host.reports[-1].result).is_equal("Free attack")
	assert_int(host.requests.size()).is_equal(1)
	host.participant = "gm"
	host.session = "gm-session"
	host.game_master = true
	host.actors.hero.data.inventory.append({"inventory_id": "armor", "source_item_id": "medium-armor", "equipped": true})
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true})
	await sdk.system_actions.submit("defence.start", _attack("fumble"))
	host.as_player()
	await sdk.system_actions.submit("defence.roll", {"id": "fumble", "difficulty": 1, "modifier": 20})
	host.roll("fumble", [1])
	await sdk.system_actions.submit("defence.advance", {"id": "fumble"})
	host.roll(host.last_request, [4, 3])
	var offered: SDK.DataResult = await sdk.system_actions.submit("defence.advance", {"id": "fumble"})
	assert_str(offered.value.state).is_equal("shield")
	assert_int(offered.value.loss).is_equal(4)
	assert_int(host.actors.hero.data.inventory[1].get("armor_tier", -1)).is_equal(1)
	assert_int(host.actors.hero.data.inventory[1].get("penalty_tier", -1)).is_equal(2)
	await sdk.system_actions.submit("defence.cancel", {"id": "fumble"})
	var ended: SDK.DataResult = await sdk.system_actions.submit("defence.choose", {"id": "fumble", "choice": "break"})
	assert_str(ended.value.state).is_equal("ended")
	assert_int(host.actors.hero.data.hit_points).is_equal(7)
	assert_int(host.actors.hero.data.inventory[1].get("armor_tier", -1)).is_equal(1)
	assert_bool(host.actors.hero.data.inventory[2].get("broken", false)).is_false()
	assert_str(host.requests[host.last_request].result.status).is_equal("rolled")

func test_disconnect_or_reconnect_after_damage_refuses_late_choice() -> void:
	for participant_id in ["gm", "player"]:
		for reconnect in [false, true]:
			var host := BOUNDARY.new()
			host.handler = auto_free(SYSTEM.new())
			add_child(host.handler)
			var sdk := SDK.new(host)
			host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true})
			await sdk.system_actions.submit("defence.start", _attack("session-ended"))
			host.as_player()
			await sdk.system_actions.submit("defence.roll", {"id": "session-ended"})
			host.roll("session-ended", [2])
			await sdk.system_actions.submit("defence.advance", {"id": "session-ended"})
			host.roll(host.last_request, [4])
			await sdk.system_actions.submit("defence.advance", {"id": "session-ended"})
			for current: Dictionary in host.sessions:
				if current.participant_id == participant_id:
					if reconnect:
						current.session_id = "replacement-session"
					else:
						host.sessions.erase(current)
					break
			var result: SDK.DataResult = await sdk.system_actions.submit("defence.choose", {"id": "session-ended", "choice": "take"})
			assert_str(result.value.state).is_equal("ended")
			assert_int(host.actors.hero.data.hit_points).is_equal(7)
			assert_str(host.requests[host.last_request].result.status).is_equal("rolled")

func test_armor_defence_penalty_and_source_automatic_hit() -> void:
	for armor in ["medium-armor", "heavy-armor"]:
		var host := BOUNDARY.new()
		host.handler = auto_free(SYSTEM.new())
		add_child(host.handler)
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory.append({"inventory_id": "armor", "source_item_id": armor, "equipped": true})
		var ready: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack(armor))
		assert_int(ready.value.difficulty).is_equal(16)
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	host.actors.enemy.data.attacks[0]["always_hits"] = true
	var ready: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack("automatic"))
	assert_bool(ready.value.get("automatic_hit", false)).is_true()
	host.as_player()
	await sdk.system_actions.submit("defence.roll", {"id": "automatic"})
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Damage", "faces": 4, "count": 1}])
	host.roll(host.last_request, [4])
	await sdk.system_actions.submit("defence.advance", {"id": "automatic"})
	assert_int(host.actors.hero.data.hit_points).is_equal(3)
	assert_int(host.requests.size()).is_equal(1)

func test_shield_choice_rejects_changed_equipment_or_failed_save_without_late_mutation() -> void:
	for refusal in ["removed", "save"]:
		var host := BOUNDARY.new()
		host.handler = auto_free(SYSTEM.new())
		add_child(host.handler)
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true})
		await sdk.system_actions.submit("defence.start", _attack(refusal))
		host.as_player()
		await sdk.system_actions.submit("defence.roll", {"id": refusal})
		host.roll(refusal, [2])
		await sdk.system_actions.submit("defence.advance", {"id": refusal})
		host.roll(host.last_request, [4])
		await sdk.system_actions.submit("defence.advance", {"id": refusal})
		if refusal == "removed":
			host.actors.hero.data.inventory.remove_at(1)
		else:
			host.fail_commit = true
		var result: SDK.DataResult = await sdk.system_actions.submit("defence.choose", {"id": refusal, "choice": "break"})
		assert_str(result.value.state).is_equal("ended")
		host.fail_commit = false
		await sdk.system_actions.submit("defence.choose", {"id": refusal, "choice": "take"})
		assert_int(host.actors.hero.data.hit_points).is_equal(7)
		assert_bool(str(host.reports).contains("Shield broken")).is_false()

func test_explicit_owner_selection_and_no_player_owner_fallback() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	host.access_entries.append({"participant_id": "second", "display_name": "Second", "access_level": "Owner", "is_connected": true, "session_id": "second-session"})
	host.sessions.append({"participant_id": "second", "session_id": "second-session", "is_gm": false})
	var offered: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack("owners"))
	assert_int(offered.value.get("owners", []).size()).is_equal(2)
	assert_bool(host.requests.is_empty()).is_true()
	var input := _attack("owners")
	input["owner"] = "second"
	var selected: SDK.DataResult = await sdk.system_actions.submit("defence.start", input)
	assert_str(selected.value.state).is_equal("ready")
	host.participant = "second"
	host.session = "second-session"
	host.game_master = false
	await sdk.system_actions.submit("defence.roll", {"id": "owners"})
	assert_str(host.requests.get("owners", {}).get("participant", "")).is_equal("second")
	await sdk.system_actions.submit("defence.cancel", {"id": "owners"})
	host.participant = "gm"
	host.session = "gm-session"
	host.game_master = true
	host.access_entries.clear()
	await sdk.system_actions.submit("defence.start", _attack("gm-owned"))
	await sdk.system_actions.submit("defence.roll", {"id": "gm-owned"})
	assert_str(host.requests["gm-owned"].participant).is_equal("gm")

func test_live_client_close_during_roll_reply_cancels_once_and_never_resumes() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	var started: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack("client-close"))
	host.as_player()
	var client = auto_free(load(ROOT + "logic/defence_action.gd").new(sdk))
	add_child(client)
	client.adopt(started.value)
	host.defer_reply = true
	client.roll({"difficulty": 0, "modifier": 0})
	await client.cancel()
	host.complete_reply()
	await get_tree().process_frame
	assert_str(client.state).is_equal("ended")
	assert_str(host.requests["client-close"].result.status).is_equal("cancelled")
	await client.refresh()
	assert_int(host.submissions.get("defence.advance", 0)).is_equal(0)
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

func test_breaking_one_shield_preserves_spares_and_refuses_overlapping_defence() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true, "quantity": 2})
	await sdk.system_actions.submit("defence.start", _attack("stack"))
	var competing: SDK.DataResult = await sdk.system_actions.submit("defence.start", _attack("competing"))
	assert_str(competing.value.state).is_equal("error")
	host.as_player()
	await sdk.system_actions.submit("defence.roll", {"id": "stack"})
	host.roll("stack", [2])
	await sdk.system_actions.submit("defence.advance", {"id": "stack"})
	host.roll(host.last_request, [4])
	await sdk.system_actions.submit("defence.advance", {"id": "stack"})
	await sdk.system_actions.submit("defence.choose", {"id": "stack", "choice": "break"})
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)
	assert_bool(host.actors.hero.data.inventory[1].get("broken", false)).is_false()
	assert_bool(host.actors.hero.data.inventory[1].equipped).is_false()
	assert_int(host.actors.hero.data.inventory[2].quantity).is_equal(1)
	assert_bool(host.actors.hero.data.inventory[2].broken).is_true()
	assert_int(host.actors.hero.data.hit_points).is_equal(7)

func test_invalid_options_can_be_corrected_or_cancelled_and_hp_preview_stays_current() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	host.actors.hero.data.inventory.append({"inventory_id": "shield", "source_item_id": "shield", "equipped": true})
	await sdk.system_actions.submit("defence.start", _attack("editable"))
	host.as_player()
	var invalid: SDK.DataResult = await sdk.system_actions.submit("defence.roll", {"id": "editable", "difficulty": 31})
	assert_str(invalid.value.state).is_equal("ready")
	assert_str(invalid.value.message).contains("1–30")
	assert_bool(host.requests.is_empty()).is_true()
	await sdk.system_actions.submit("defence.roll", {"id": "editable", "difficulty": 0})
	host.roll("editable", [2])
	await sdk.system_actions.submit("defence.advance", {"id": "editable"})
	host.actors.hero.data.hit_points = 9
	host.roll(host.last_request, [4])
	var choice: SDK.DataResult = await sdk.system_actions.submit("defence.advance", {"id": "editable"})
	assert_int(choice.value.hp).is_equal(9)
	host.actors.hero.data.hit_points = 8
	choice = await sdk.system_actions.submit("defence.advance", {"id": "editable"})
	assert_int(choice.value.hp).is_equal(8)
	await sdk.system_actions.submit("defence.choose", {"id": "editable", "choice": "take"})
	assert_int(host.actors.hero.data.hit_points).is_equal(5)

func test_equipped_class_defence_exception_and_scum_keep_armor_penalty(key: String, class_id: String, expected: int, _test_parameters := [["brown-scimitar-of-galgenbeck", "fanged-deserter", 10], ["blade-of-your-ancestors", "wretched-royalty", 10], ["stolen-mitre", "heretical-priest", 10], ["sword", "gutterborn-scum", 10]]) -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.enemy.data.attacks[0].defence_dr = 12
	host.actors.hero.data.class_id = class_id
	host.actors.hero.data.inventory = [{"inventory_id": "special", "source_item_id": key, "quantity": 1, "equipped": true}]
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("defence.start", _attack("plain"))
	assert_int(result.value.difficulty).is_equal(expected)
	host.as_player()
	await sdk.system_actions.submit("defence.cancel", {"id": "plain"})
	host.participant = "gm"
	host.session = "gm-session"
	host.game_master = true
	host.actors.hero.data.inventory.append({"inventory_id": "armor", "source_item_id": "medium-armor", "equipped": true, "quantity": 1})
	result = await sdk.system_actions.submit("defence.start", _attack("armor"))
	assert_int(result.value.difficulty).is_equal(expected + 2)
