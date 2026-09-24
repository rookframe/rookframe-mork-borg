extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/melee_authority.gd")
const EQUIPMENT = preload(ROOT + "logic/equipment.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func test_bow_uses_presence_and_one_arrow_for_a_miss() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	var bow: Dictionary = EQUIPMENT.new().item("bow")
	bow.merge({"inventory_id": "1", "equipped": true}, true)
	host.actors.hero.data.inventory = [bow, {"inventory_id": "2", "source_item_id": "arrow", "quantity": 2}]
	host.actors.hero.data.abilities["Presence"] = {"modifier": 2}
	host.distance = 9.144
	var started: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": "shot", "source": "hero", "rook": "hero-rook", "item": "1", "ammunition": "2"})
	assert_str(started.value.state).is_equal("pending")
	if started.value.state != "pending":
		return
	host.roll("shot", [9])
	var finished: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "shot"})
	assert_str(finished.value.state).is_equal("resolved")
	assert_str(host.reports[-1].result).is_equal("Miss")
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)
	assert_int(host.actors.hero.data.inventory[0].quantity).is_equal(1)
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	await sdk.system_actions.submit("melee.advance", {"id": "shot"})
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)

func test_presence_hit_spends_ammunition_before_damage_and_preserves_it_on_cancel() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	var bow: Dictionary = EQUIPMENT.new().item("bow")
	bow.merge({"inventory_id": "1", "equipped": true}, true)
	# An unrelated editable use counter must not replace a single arrow's quantity.
	host.actors.hero.data.inventory = [bow, {"inventory_id": "2", "source_item_id": "arrow", "quantity": 2, "uses": 0}]
	host.actors.hero.data.abilities["Presence"] = {"modifier": 2}
	var started: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": "shot", "source": "hero", "rook": "hero-rook", "item": "1", "ammunition": "2"})
	assert_str(started.value.state).is_equal("pending")
	if started.value.state != "pending":
		return
	host.roll("shot", [10])
	var hit: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "shot"})
	assert_str(hit.value.state).is_equal("pending")
	assert_int(host.requests[host.last_request].terms[0].faces).is_equal(6)
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)
	await sdk.system_actions.submit("melee.cancel", {"id": "shot"})
	host.roll(host.last_request, [6, 1])
	await sdk.system_actions.submit("melee.advance", {"id": "shot"})
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)
	assert_int(host.actors.hero.data.inventory[1].quantity).is_equal(1)

func test_selected_creature_alternative_owns_its_range() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	var definition = load(ROOT + "content/seth-goblin.tres")
	host.actors.hero.data = definition.create_data({})
	host.distance = 9.144
	var input := {"source": "hero", "rook": "hero-rook", "attack": "knife"}
	var knife: SDK.DataResult = await sdk.system_actions.submit("attack.validate", input)
	assert_str(knife.value.message).is_equal("target Hooded stranger not in range")
	assert_bool(host.requests.is_empty()).is_true()
	input.attack = "shortbow"
	var bow: SDK.DataResult = await sdk.system_actions.submit("attack.validate", input)
	assert_str(bow.value.state).is_equal("ready")
	if bow.value.state != "ready":
		return
	assert_int(bow.value.attack.range_feet).is_equal(30)
	assert_str(bow.value.attack.name).is_equal("Shortbow")
	assert_bool(host.requests.is_empty()).is_true()
	host.distance = 9.14401
	var outside: SDK.DataResult = await sdk.system_actions.submit("attack.validate", input)
	assert_str(outside.value.message).is_equal("target Hooded stranger not in range")

func test_gutterborn_presence_exception_keeps_source_difficulty() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	var sling: Dictionary = EQUIPMENT.new().item("sling")
	sling.merge({"inventory_id": "1", "equipped": true, "uses": 3}, true)
	host.actors.hero.data.inventory = [sling]
	host.actors.hero.data.class_id = "gutterborn-scum"
	host.actors.hero.data.abilities["Presence"] = {"modifier": 0}
	host.actors.enemy.data.definition_id = "seth-goblin"
	await sdk.system_actions.submit("melee.start", {"id": "shot", "source": "hero", "rook": "hero-rook", "item": "1"})
	host.roll("shot", [12])
	var hit: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "shot"})
	assert_str(hit.value.state).is_equal("pending")
	assert_int(host.actors.hero.data.inventory[0].uses).is_equal(3)
	assert_int(host.actors.hero.data.inventory[0].quantity).is_equal(1)

func test_equipped_bow_view_selects_only_matching_ammunition() -> void:
	var view = auto_free(load(ROOT + "ui/melee_attack.tscn").instantiate())
	add_child(view)
	var bow: Dictionary = EQUIPMENT.new().item("bow")
	var arrows: Dictionary = EQUIPMENT.new().item("twenty-arrows")
	arrows.inventory_id = "arrows"
	var bolts: Dictionary = EQUIPMENT.new().item("bolt")
	bolts.inventory_id = "bolts"
	view.configure({"name": "Graveworm", "abilities": {"Presence": {"modifier": 2}}, "inventory": [arrows, bolts]}, bow, {"difficulty": 0, "modifier": 0, "fumble": "break"}, "ready", "")
	assert_str(view.options().ammunition).is_equal("arrows")
	assert_str(view.get_node("Metrics/Strength/Content/Label").text).is_equal("PRESENCE")
	assert_str(view.get_node("Ammunition/Resource").text).contains("20 left")
	view.configure({"inventory": [arrows]}, bow, {"difficulty": 0, "modifier": 0, "fumble": "break", "ammunition": "arrows"}, "pending", "Waiting for the attack Throw")
	assert_str(view.options().ammunition).is_equal("arrows")

func after_test() -> void:
	await get_tree().process_frame

func test_creature_source_ranges_and_exceptions_survive_selection() -> void:
	var cases := [
		["zukuma-berserker", "long-flail", 3.048, 10],
		["zukuma-berserker", "chained-sword", 3.048, 10],
		["zukuma-berserker", "heavy-mace", 1.524, 5],
		["thinx-grotesque", "eye-beam", 9.144, 30],
		["thinx-grotesque", "claws", 1.524, 5],
		["belze-skeleton", "bony-knuckles", 1.524, 5],
		["eulotha-wyvern", "sting", 1.524, 5],
		["nodh-zombie", "bite", 1.524, 5]
	]
	for row in cases:
		var host = BOUNDARY.new()
		var system = auto_free(SYSTEM.new())
		add_child(system)
		host.handler = system
		var sdk := SDK.new(host)
		host.actors.hero.data = load(ROOT + "content/" + row[0] + ".tres").create_data({})
		host.distance = row[2]
		var input := {"source": "hero", "rook": "hero-rook", "attack": row[1]}
		var selected: SDK.DataResult = await sdk.system_actions.submit("attack.validate", input)
		assert_str(selected.value.state).is_equal("ready")
		if selected.value.state != "ready":
			continue
		assert_int(selected.value.attack.range_feet).is_equal(row[3])
		if row[1] == "eye-beam":
			assert_bool(selected.value.attack.always_hits).is_true()
			assert_str(selected.value.attack.rules).contains("1–2 on a d6")
		host.distance += 0.00001
		var outside: SDK.DataResult = await sdk.system_actions.submit("attack.validate", input)
		assert_str(outside.value.message).is_equal("target Hooded stranger not in range")
		assert_bool(host.requests.is_empty()).is_true()

func test_saved_creature_combined_attack_keeps_live_values_and_gains_source_choices() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	host.actors.hero.data = {"schema": "mork-borg-adversary/v1", "definition_id": "seth-goblin", "name": "Live goblin", "hit_points": 2, "attacks": [{"name": "Knife / shortbow", "dice": "d6"}]}
	host.distance = 9.144
	var selected: SDK.DataResult = await sdk.system_actions.submit("attack.validate", {"source": "hero", "rook": "hero-rook", "attack": "shortbow"})
	assert_str(selected.value.state).is_equal("ready")
	if selected.value.state != "ready":
		return
	assert_str(selected.value.attack.dice).is_equal("d6")
	assert_int(selected.value.attack.range_feet).is_equal(30)
	assert_int(host.actors.hero.data.hit_points).is_equal(2)
	var contact: SDK.DataResult = await sdk.system_actions.submit("attack.validate", {"source": "hero", "rook": "hero-rook", "attack": "knife"})
	assert_str(contact.value.message).is_equal("target Hooded stranger not in range")

func test_unspecified_custom_projectile_is_rejected_before_any_roll() -> void:
	var host = BOUNDARY.new()
	var system = auto_free(SYSTEM.new())
	add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	host.actors.hero.data.inventory = [{"custom": true, "inventory_id": "1", "name": "Custom bow", "kind": "Weapon", "damage": "d6", "range_feet": 30, "equipped": true, "quantity": 1}]
	var result: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": "shot", "source": "hero", "rook": "hero-rook", "item": "1"})
	assert_str(result.value.state).is_equal("error")
	assert_str(result.value.message).contains("explicit attack rules")
	assert_bool(host.requests.is_empty()).is_true()
