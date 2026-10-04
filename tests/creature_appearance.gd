extends GdUnitTestSuite
## Severe first-write capability loss and stale appearance overwrite coverage.
## Public SDK boundary only; not application persistence, replication or picker QA.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
const BOUNDARY = preload("res://tests/creature_appearance_boundary.gd")
const REFERENCE := {"package_id": "external-miniatures", "local_id": "warden"}

func _legacy() -> Dictionary:
	var data: Dictionary = load(ROOT + "content/seth-goblin.tres").create_data({})
	data.erase("creature_stat_block")
	data["creature_inventory"] = true
	data["inventory"] = [
		{"inventory_id": "5", "source_attack_id": "shortbow", "name": "Corrected warbow", "kind": "Weapon", "damage": "d8", "range_feet": 40, "quantity": 2, "equipped": true},
		{"inventory_id": "6", "name": "Corrected coat", "kind": "Armor", "reduction": "d4", "armor_tier": 2, "quantity": 1, "equipped": true},
		{"inventory_id": "7", "name": "Shield", "kind": "Shield", "quantity": 1, "equipped": true}]
	data["armor"] = {"name": "Corrected coat", "reduction": "d4"}
	data.attacks[1]["rules"] = "Accepted attack rule."
	return data

func test_appearance_first_writes_preserve_latest_legacy_capabilities() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	host.actors.enemy.access_level = "Owner"
	var sdk := SDK.new(host)
	var id := SDK.ActorId.new("enemy")
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_RED)
	var portrait := image.save_png_to_buffer()
	var rooks := host.rooks.duplicate(true)
	for operation in ["portrait", "miniature"]:
		host.actors.enemy.data = _legacy()
		var latest := _legacy()
		latest.hit_points = -3
		latest.name = "Accepted correction"
		latest["rules"] = "Accepted free rule."
		latest.inventory.append({"inventory_id": "8", "name": "Accepted loot", "quantity": 3})
		host.before_appearance = latest
		var expected := CREATURES.new().stat_block(latest)
		var result: SDK.ActorResult
		if operation == "portrait":
			result = await ACTIONS.new(sdk, id).set_portrait(portrait)
			expected["portrait"] = portrait
		else:
			result = await MINIATURES.new(sdk).set_actor(id, REFERENCE)
			expected["preferred_miniature"] = REFERENCE
		assert_bool(result.ok).is_true()
		assert_dict(result.actor.data).is_equal(expected)
		assert_int(result.actor.data.attacks.size()).is_equal(1)
		assert_str(result.actor.data.attacks[0].id).is_equal("shortbow")
		assert_str(result.actor.data.attacks[0].dice).is_equal("d8")
		assert_str(result.actor.data.attacks[0].rules).is_equal("Accepted attack rule.")
		assert_int(result.actor.data.armor.shield_reduction).is_equal(1)
		assert_int(result.actor.data.armor.defence_penalty).is_equal(2)
		assert_dict(host.rooks).is_equal(rooks)
		host.fail_commit = true
		result = await ACTIONS.new(sdk, id).set_portrait(PackedByteArray())
		assert_bool(result.ok).is_false()
		assert_dict(host.actors.enemy.data).is_equal(expected)
		host.fail_commit = false
		host.actors.enemy.access_level = "Viewer"
		result = await ACTIONS.new(sdk, id).set_miniature({})
		assert_bool(result.ok).is_false()
		assert_dict(host.actors.enemy.data).is_equal(expected)
		host.actors.enemy.access_level = "Owner"
