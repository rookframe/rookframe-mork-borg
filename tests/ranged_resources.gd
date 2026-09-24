extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/melee_authority.gd")
const EQUIPMENT = preload(ROOT + "logic/equipment.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func test_crossbow_critical_and_fumble_spend_bolts_once() -> void:
	for face in [20, 1]:
		var host = BOUNDARY.new()
		var system = auto_free(SYSTEM.new())
		add_child(system)
		host.handler = system
		var sdk := SDK.new(host)
		var weapon: Dictionary = EQUIPMENT.new().item("crossbow")
		weapon.merge({"inventory_id": "1", "equipped": true}, true)
		var bolts: Dictionary = EQUIPMENT.new().item("ten-bolts")
		bolts.inventory_id = "2"
		host.actors.hero.data.inventory = [weapon, bolts]
		host.actors.hero.data.abilities["Presence"] = {"modifier": -3}
		host.actors.enemy.data.hit_points = 20
		await sdk.system_actions.submit("melee.start", _attack_input())
		host.roll("shot", [face])
		await sdk.system_actions.submit("melee.advance", {"id": "shot"})
		if face == 20:
			assert_int(host.requests[host.last_request].terms[0].faces).is_equal(8)
			host.roll(host.last_request, [8, 4])
			await sdk.system_actions.submit("melee.advance", {"id": "shot"})
			assert_int(host.actors.enemy.data.hit_points).is_equal(6)
			assert_str(host.actors.enemy.data.armor.reduction).is_equal("")
		else:
			assert_bool(host.actors.hero.data.inventory[0].broken).is_true()
			assert_bool(host.actors.hero.data.inventory[0].equipped).is_false()
			assert_int(host.actors.enemy.data.hit_points).is_equal(20)
		await sdk.system_actions.submit("melee.advance", {"id": "shot"})
		assert_int(host.actors.hero.data.inventory[1].uses).is_equal(9)
		assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)
		assert_bool(str(host.reports).contains("Seth")).is_false()

func test_rejected_targets_and_cancelled_throws_preserve_resources() -> void:
	for scenario in ["range", "mixed-targets", "all-outside", "cancel", "missing", "wrong-kind", "save-failure", "already-spent"]:
		var host = BOUNDARY.new()
		var system = auto_free(SYSTEM.new())
		add_child(system)
		host.handler = system
		var sdk := SDK.new(host)
		var weapon: Dictionary = EQUIPMENT.new().item("shortbow")
		weapon.merge({"inventory_id": "1", "equipped": true}, true)
		var arrows: Dictionary = EQUIPMENT.new().item("arrow")
		arrows.merge({"inventory_id": "2", "quantity": 1}, true)
		host.actors.hero.data.inventory = [weapon, arrows]
		if scenario in ["range", "mixed-targets", "all-outside"]:
			host.distance = 9.14401
			if scenario != "range":
				host.actors["second"] = host.actors.enemy.duplicate(true)
				host.actors.second.id = "second"
				host.actors.second.public_label = "Distant stranger"
				host.rooks["second-rook"] = "second"
				host.targets.append("second-rook")
				host.distances["second-rook"] = 1.0 if scenario == "mixed-targets" else 10.0
		if scenario == "missing":
			host.actors.hero.data.inventory[1].quantity = 0
		if scenario == "wrong-kind":
			host.actors.hero.data.inventory[1] = EQUIPMENT.new().item("bolt")
			host.actors.hero.data.inventory[1].inventory_id = "2"
		var result: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input())
		if scenario in ["cancel", "save-failure", "already-spent"]:
			assert_str(result.value.state).is_equal("pending")
			if scenario == "cancel":
				await sdk.system_actions.submit("melee.cancel", {"id": "shot"})
			elif scenario == "save-failure":
				host.fail_commit = true
			else:
				host.actors.hero.data.inventory[1].quantity = 0
			host.roll("shot", [20])
			result = await sdk.system_actions.submit("melee.advance", {"id": "shot"})
			assert_str(result.value.state).is_equal("ended")
			assert_int(host.requests.size()).is_equal(1)
		else:
			assert_str(result.value.state).is_equal("error")
			assert_bool(host.requests.is_empty()).is_true()
		if scenario in ["range", "mixed-targets"]:
			assert_str(result.value.message).is_equal("target Hooded stranger not in range")
		if scenario == "all-outside":
			assert_str(result.value.message).is_equal("target Hooded stranger not in range\ntarget Distant stranger not in range")
		assert_int(host.actors.enemy.data.hit_points).is_equal(6)
		assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(0 if scenario in ["missing", "already-spent"] else 1)

func _attack_input() -> Dictionary:
	return {"id": "shot", "source": "hero", "rook": "hero-rook", "item": "1", "ammunition": "2"}
