extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func test_special_weapon_reach_difficulty_and_damage(key: String, damage: Array, expected_hp: int, _test_parameters := [["blade-of-your-ancestors", [3], 2], ["snake-skin-gift", [1], 0], ["old-sigurds-sling", [2, 3], 1]]) -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.abilities = {"Strength": {"modifier": 0}, "Presence": {"modifier": 0}}
	host.actors.hero.data.inventory = [{"inventory_id": "special", "source_item_id": key, "quantity": 1, "equipped": true}]
	host.actors.enemy.data.armor.reduction = ""
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "special"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("attack", [10 if key == "blade-of-your-ancestors" else 12])
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll(host.last_request, damage)
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(expected_hp)
	assert_str(str(host.reports)).not_contains("Seth")

func test_weapon_secondary_rolls_preserve_immediate_and_delayed_boundaries(key: String, damage: Array, expected_hp: int, text: String, _test_parameters := [["brown-scimitar-of-galgenbeck", [3, 1], 3, "10 minutes"], ["shoe-of-deaths-horse", [2, 1], 0, "instantly"], ["sacred-shepherds-crook", [3], 3, "faithless"]]) -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.abilities = {"Strength": {"modifier": 0}, "Presence": {"modifier": 0}}
	host.actors.hero.data.inventory = [{"inventory_id": "special", "source_item_id": key, "quantity": 1, "equipped": true}]
	host.actors.enemy.data.armor.reduction = ""
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "special", "small_medium": true, "faithless_human": true, "eligible": true})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("attack", [12])
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	var count := 0
	for term in host.requests[host.last_request].terms:
		count += int(term.count)
	assert_int(count).is_equal(damage.size())
	if count != damage.size():
		return
	host.roll(host.last_request, damage)
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.enemy.data.hit_points).is_equal(expected_hp)
	assert_str(result.value.message).contains(text)

func test_bite_and_cowards_jab_use_their_printed_tests(mode: String, _test_parameters := [["bite"], ["jab"]]) -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.abilities = {"Strength": {"modifier": 0}, "Agility": {"modifier": 0}}
	host.actors.hero.data.class_id = "fanged-deserter" if mode == "bite" else "gutterborn-scum"
	host.actors.hero.data.traits = [{"id": "cowards-jab"}]
	host.actors.enemy.data.armor.reduction = ""
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "class:bite" if mode == "bite" else "1", "mode": mode, "eligible": true})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll("attack", [10, 2] if mode == "bite" else [10])
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	host.roll(host.last_request, [2])
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_int(host.actors.enemy.data.hit_points).is_equal(4 if mode == "bite" else 1)
	if mode == "bite":
		assert_str(result.value.message).contains("free attack")

func test_eurekia_destroys_sword_and_records_hamfund_death_on_one_even_on_miss() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.inventory = [{"inventory_id": "sword", "source_item_id": "eurekia", "quantity": 1, "uses": 1, "equipped": true}]
	host.actors.hero.data["companion_sheets"] = [{"id": "hamfund-the-squire", "name": "Hamfund"}]
	var sdk := SDK.new(host)
	var result := await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "sword", "eligible": true})
	assert_str(result.value.state).is_equal("pending")
	if result.value.state != "pending":
		return
	assert_int(host.requests.attack.terms.size()).is_equal(2)
	if host.requests.attack.terms.size() != 2:
		return
	host.roll("attack", [2, 1])
	result = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(host.actors.hero.data.inventory[0].quantity).is_equal(0)
	assert_bool(host.actors.hero.data.companion_sheets[0].slain).is_true()
	assert_str(str(host.reports)).contains("Hamfund").contains("vanishes")

func test_eurekia_vanish_on_fumble_does_not_restore_sword_from_stale_snapshot() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.inventory = [{"inventory_id": "sword", "source_item_id": "eurekia", "quantity": 1, "uses": 1, "equipped": true}]
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "sword", "eligible": true})
	host.roll("attack", [1, 1])
	await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_int(host.actors.hero.data.inventory[0].quantity).is_equal(0)

func test_eurekia_remaining_draw_correction_starts_a_fresh_combat() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.inventory = [{"inventory_id": "sword", "source_item_id": "eurekia", "quantity": 1, "uses": 0, "drawn": true, "equipped": true}]
	var sdk := SDK.new(host)
	var actions = load(ROOT + "logic/character_actions.gd").new(sdk, SDK.ActorId.new("hero"))
	var correction: SDK.ActorResult = await actions.change_item("sword", "uses", "1")
	assert_bool(correction.ok).is_true()
	assert_bool(host.actors.hero.data.inventory[0].drawn).is_false()
	await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "sword", "eligible": true})
	host.roll("attack", [2, 3])
	await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_int(host.actors.hero.data.inventory[0].uses).is_equal(0)
	assert_bool(host.actors.hero.data.inventory[0].drawn).is_true()
