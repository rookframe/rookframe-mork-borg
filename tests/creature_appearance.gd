extends GdUnitTestSuite
## Severe first-write capability loss and stale appearance overwrite coverage.
## Public SDK boundary only; not application persistence, replication or picker QA.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
const CHARACTERS = preload(ROOT + "logic/character_actions.gd")
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
	var portrait: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
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
			result = await ACTIONS.new(sdk, id).set_portrait(portrait, "", 0)
			expected["portrait"] = portrait
			expected["portrait_revision"] = 1
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
		result = await ACTIONS.new(sdk, id).set_portrait("", str(expected.get("portrait", "")), int(expected.get("portrait_revision", 0)))
		assert_bool(result.ok).is_false()
		assert_dict(host.actors.enemy.data).is_equal(expected)
		host.fail_commit = false
		host.actors.enemy.access_level = "Viewer"
		result = await ACTIONS.new(sdk, id).set_miniature({})
		assert_bool(result.ok).is_false()
		assert_dict(host.actors.enemy.data).is_equal(expected)
		host.actors.enemy.access_level = "Owner"

func test_library_filepath_defaults_snapshot_only_future_actors_and_failed_changes_leave_defaults_intact() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var sdk := SDK.new(host)
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_RED)
	var first_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
	image.fill(Color.DARK_BLUE)
	var second_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
	var rooks := host.rooks.duplicate(true)
	var saved := await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": first_path, "expected": "", "expected_revision": 0})
	assert_bool(saved.value.ok).is_true()
	var created := await sdk.system_actions.submit("miniature.create", {"definition": "seth-goblin"})
	assert_str(created.value.state).is_equal("resolved")
	var first_id := SDK.ActorId.new(str(created.value.actor))
	assert_str(sdk.actors.read(first_id).actor.data.portrait).is_equal(first_path)
	host.fail_commit = true
	saved = await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": second_path, "expected": first_path, "expected_revision": 1})
	assert_bool(saved.value.ok).is_false()
	assert_str(host.world_data.creature_portraits["seth-goblin"]).is_equal(first_path)
	host.fail_commit = false
	saved = await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": second_path, "expected": first_path, "expected_revision": 1})
	assert_bool(saved.value.ok).is_true()
	created = await sdk.system_actions.submit("miniature.create", {"definition": "seth-goblin"})
	var second_id := SDK.ActorId.new(str(created.value.actor))
	assert_str(sdk.actors.read(second_id).actor.data.portrait).is_equal(second_path)
	assert_str(sdk.actors.read(first_id).actor.data.portrait).is_equal(first_path)
	assert_dict(host.rooks).is_equal(rooks)
	assert_str(host.world_data.unrelated).is_equal("retained")

func test_late_actor_upload_after_new_choice_and_reset_is_rejected_without_blocking_hp_changes() -> void:
	for actor_id in ["hero", "enemy"]:
		var host := BOUNDARY.new()
		host.handler = auto_free(SYSTEM.new())
		host.handler.sdk = SDK.new(host)
		add_child(host.handler)
		host.actors[actor_id].access_level = "Owner"
		var sdk := SDK.new(host)
		var id := SDK.ActorId.new(actor_id)
		var actions = CHARACTERS.new(sdk, id) if actor_id == "hero" else ACTIONS.new(sdk, id)
		var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
		image.fill(Color.DARK_RED)
		var late_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
		image.fill(Color.DARK_BLUE)
		var newer_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
		# Upload A captured empty/0 before B accepted a choice and then reset it.
		assert_bool((await actions.set_portrait(newer_path, "", 0)).ok).is_true()
		assert_bool((await actions.set_portrait("", newer_path, 1)).ok).is_true()
		# Ordinary HP and loot writes must retain the portrait generation.
		assert_bool((await actions.correct_many({"hit_points": "-4"})).ok).is_true()
		assert_bool((await actions.add_custom({"name": "Accepted loot", "quantity": "2"})).ok).is_true()
		assert_int(host.actors[actor_id].data.portrait_revision).is_equal(2)
		var accepted: Dictionary = host.actors[actor_id].data.duplicate(true)
		var late: SDK.ActorResult = await actions.set_portrait(late_path, "", 0)
		assert_bool(late.ok).is_false()
		assert_str(late.message).is_equal("Portrait changed. Choose it again.")
		assert_dict(host.actors[actor_id].data).is_equal(accepted)
		# A fresh choice captures empty/2; an intervening HP edit must survive.
		assert_bool((await actions.correct_many({"hit_points": "5"})).ok).is_true()
		var saved: SDK.ActorResult = await actions.set_portrait(late_path, "", 2)
		assert_bool(saved.ok).is_true()
		assert_int(saved.actor.data.hit_points).is_equal(5)
		assert_int(saved.actor.data.portrait_revision).is_equal(3)
		assert_str(saved.actor.data.portrait).is_equal(late_path)
		assert_array(saved.actor.data.inventory).is_equal(accepted.inventory)

func test_late_library_upload_after_reset_is_rejected_and_unrelated_world_changes_survive() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var sdk := SDK.new(host)
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_RED)
	var late_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
	image.fill(Color.DARK_BLUE)
	var newer_path: String = host.RetainActorPortrait(image.save_png_to_buffer()).path
	var saved := await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": newer_path, "expected": "", "expected_revision": 0})
	assert_bool(saved.value.ok).is_true()
	saved = await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": "", "expected": newer_path, "expected_revision": 1})
	assert_bool(saved.value.ok).is_true()
	host.world_data.unrelated = "accepted later"
	var accepted: Dictionary = host.world_data.duplicate(true)
	saved = await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": late_path, "expected": "", "expected_revision": 0})
	assert_bool(saved.value.ok).is_false()
	assert_dict(host.world_data).is_equal(accepted)
	saved = await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": "seth-goblin", "path": late_path, "expected": "", "expected_revision": 2})
	assert_bool(saved.value.ok).is_true()
	assert_str(host.world_data.unrelated).is_equal("accepted later")
	assert_int(host.world_data.creature_portrait_revisions["seth-goblin"]).is_equal(3)
