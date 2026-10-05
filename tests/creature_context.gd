extends GdUnitTestSuite
## Severe transaction risk: critical context must follow identity and accepted commits.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const PROJECTION = preload(ROOT + "logic/creature_projection.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _start(sdk: SDK, id: String, part: String, entry: String) -> Dictionary:
	var result := await sdk.system_actions.submit("creature-roll.start", {"id": id, "source": "hero", "part": part, "entry": entry})
	assert_str(result.value.state).is_equal("pending")
	return result.value

func _finish(sdk: SDK, host: BOUNDARY, id: String, face: int) -> Dictionary:
	host.roll(id, [face])
	var result := await sdk.system_actions.submit("creature-roll.advance", {"id": id})
	return result.value

func test_context_is_immutable_identity_bound_and_consumed_only_by_matching_accepted_damage() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.targets = PackedStringArray()
	host.rooks.clear()
	host.actors.hero.data = load(ROOT + "content/hawk-as-weapon.tres").create_data({})
	var data: Dictionary = host.actors.hero.data
	data.attacks[0].dice = "d4+1"
	data.inventory = [{"inventory_id": "independent", "name": "Unspent loot", "quantity": 9}]
	data.portrait = PackedByteArray([1, 2, 3])
	var entry := str(data.attacks[0].id)
	var other := str(data.attacks[1].id)
	var sdk := SDK.new(host)
	await _start(sdk, "first-attack", "attack", entry)
	var result := await _finish(sdk, host, "first-attack", 20)
	assert_str(result.state).is_equal("resolved")
	assert_bool(result.critical).is_true()
	# First Edit prepares stable tags only; a subsequent accepted correction must
	# not reinterpret the formula captured by the preceding untagged Attack.
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var prepared := await actions.prepare_corrections()
	assert_bool(prepared.ok).is_true()
	assert_str(str(prepared.actor.data.attacks[0].correction_entry_id)).is_not_empty()
	var corrected := await actions.correct_many({"attack:0:dice": "d6+2", "rule:0:text": "Accepted custom own-test prose"}, PROJECTION.new().identities(prepared.actor.data))
	assert_bool(corrected.ok).is_true()
	var before: Dictionary = host.actors.duplicate(true)
	# A different named attack cannot spend the preceding context.
	await _start(sdk, "unmatched", "damage", other)
	result = await _finish(sdk, host, "unmatched", 1)
	assert_bool(result.critical).is_false()
	await _start(sdk, "failed-damage", "damage", entry)
	assert_int(host.requests["failed-damage"].terms[0].faces).is_equal(4)
	host.fail_commit = true
	result = await _finish(sdk, host, "failed-damage", 3)
	assert_str(result.state).is_equal("ended")
	host.fail_commit = false
	var count := host.reports.size()
	await sdk.system_actions.submit("creature-roll.advance", {"id": "failed-damage"})
	assert_int(host.reports.size()).is_equal(count)
	await _start(sdk, "accepted-damage", "damage", entry)
	result = await _finish(sdk, host, "accepted-damage", 3)
	assert_int(result.total).is_equal(8)
	assert_bool(result.critical).is_true()
	assert_str(result.choice.formula).is_equal("d4+1")
	assert_int(result.attack_sequence).is_equal(1)
	count = host.reports.size()
	for operation in ["advance", "start", "cancel", "advance"]:
		await sdk.system_actions.submit("creature-roll." + operation, {"id": "accepted-damage", "source": "hero", "part": "damage", "entry": entry})
	assert_int(host.reports.size()).is_equal(count)
	await _start(sdk, "ordinary-after-consumption", "damage", entry)
	result = await _finish(sdk, host, "ordinary-after-consumption", 3)
	assert_bool(result.critical).is_false()
	assert_int(result.total).is_equal(5)
	assert_str(result.choice.formula).is_equal("d6+2")
	assert_dict(host.actors).is_equal(before)
	# Known identity replacement invalidates the captured context even at same ID.
	await _start(sdk, "before-replacement", "attack", entry)
	await _finish(sdk, host, "before-replacement", 20)
	await _start(sdk, "pending-replaced", "damage", entry)
	host.actors.hero.data.attacks[0].correction_entry_id = "known-new-entry"
	result = await _finish(sdk, host, "pending-replaced", 3)
	assert_bool(result.critical).is_false()
	assert_int(result.total).is_equal(5)
	# An accepted new Attack replaces context; late old Damage cannot consume it.
	await _start(sdk, "preceding-old", "attack", entry)
	await _finish(sdk, host, "preceding-old", 20)
	await _start(sdk, "pending-old", "damage", entry)
	await _start(sdk, "preceding-new", "attack", entry)
	await _finish(sdk, host, "preceding-new", 20)
	result = await _finish(sdk, host, "pending-old", 2)
	assert_bool(result.critical).is_false()
	assert_int(result.total).is_equal(4)
	# Reordering changes no stable source identity or accepted choice.
	host.actors.hero.data.attacks.reverse()
	before = host.actors.duplicate(true)
	await _start(sdk, "matching-new", "damage", entry)
	result = await _finish(sdk, host, "matching-new", 2)
	assert_bool(result.critical).is_true()
	assert_int(result.total).is_equal(8)
	assert_dict(host.actors).is_equal(before)
