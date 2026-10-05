extends GdUnitTestSuite
## Severe risks only: changed-fields reconciliation, stale identity and atomic rejection.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const PROJECTION = preload(ROOT + "logic/creature_projection.gd")
const DRAFT = preload(ROOT + "ui/sheet_draft.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	return host

func test_changed_fields_preserve_latest_state_and_invalidate_replaced_entries() -> void:
	var host := _host()
	host.actors.hero.data.rule_groups[0].entries[0]["rolls"] = [{"id": "printed:rule:roll", "name": "Printed die", "dice": "d6"}]
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var result := await actions.prepare_corrections()
	assert_bool(result.ok).is_true()
	var projection := PROJECTION.new()
	var draft := DRAFT.new()
	var data: Dictionary = result.actor.data
	assert_int(data.attacks.size()).is_equal(2)
	draft.begin(projection.fields(data), projection.identities(data))
	draft.change("name", "Named enemy")
	draft.change("attack:0:dice", "d8")
	draft.change("rule:0:text", "Local edited rule")
	draft.change("rule:1:text", "Local second rule")
	draft.change("printed:0:dice", "d8")
	# Other accepted operations arrive while the same local correction draft is open.
	await actions.add_equipment("torch")
	host.actors.hero.data.hit_points = 23
	host.actors.hero.data.rules = "Independently accepted additional prose"
	host.actors.hero.data["portrait"] = PackedByteArray([1, 2, 3])
	host.actors.hero.data["preferred_miniature"] = {"package_id": "another-package", "local_id": "miniature"}
	var incoming: Dictionary = sdk.actors.read(SDK.ActorId.new("hero")).actor.data
	assert_bool(draft.refresh(projection.fields(incoming), projection.identities(incoming))).is_false()
	assert_str(draft.value("hit_points")).is_equal("23")
	assert_str(draft.value("name")).is_equal("Named enemy")
	var old_ids := draft.identities()
	# A same-slot replacement, including a content ID with colons, must not receive old text.
	host.actors.hero.data.attacks[0] = {"id": "new:attack:id", "name": "Replacement", "dice": "d4", "rules": ""}
	host.actors.hero.data.rule_groups[0].entries[0] = {"id": "new:rule:id", "name": "Replacement rule", "text": "Accepted replacement", "rolls": [{"id": "replacement:printed:roll", "name": "Replacement die", "dice": "d4"}]}
	result = await actions.correct_many(draft.changes(), old_ids)
	assert_bool(result.ok).is_true()
	data = result.actor.data
	assert_str(data.name).is_equal("Named enemy")
	assert_str(data.attacks[0].dice).is_equal("d4")
	assert_str(data.rule_groups[0].entries[0].text).is_equal("Accepted replacement")
	assert_str(data.rule_groups[0].entries[0].rolls[0].dice).is_equal("d4")
	assert_int(data.hit_points).is_equal(23)
	assert_str(data.rules).is_equal("Independently accepted additional prose")
	assert_str(data.rule_groups[1].entries[0].text).is_equal("Local second rule")
	assert_int(data.inventory.size()).is_equal(1)
	assert_bool(data.portrait == PackedByteArray([1, 2, 3])).is_true()
	assert_str(data.preferred_miniature.local_id).is_equal("miniature")
	assert_bool(draft.refresh(projection.fields(data), projection.identities(data))).is_true()
	assert_bool(draft.changes().has("attack:0:dice")).is_false()
	assert_bool(draft.changes().has("rule:0:text")).is_false()
	assert_bool(draft.changes().has("printed:0:dice")).is_false()
	draft.discard()
	assert_str(projection.fields(data).hit_points).is_equal("23")

func test_rejected_correction_is_atomic_and_preserves_independent_accepted_state() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var result := await actions.prepare_corrections()
	assert_bool(result.ok).is_true()
	var ids := PROJECTION.new().identities(result.actor.data)
	var before: Dictionary = host.actors.hero.data.duplicate(true)
	result = await actions.correct_many({"name": "Not committed", "maximum_hit_points": "0"}, ids)
	assert_bool(result.ok).is_false()
	assert_str(actions.invalid_field).is_equal("maximum_hit_points")
	assert_dict(host.actors.hero.data).is_equal(before)
	result = await actions.correct_many({"hit_points": "1.5"}, ids)
	assert_bool(result.ok).is_false()
	for text in ["9223372036854775808", "-9223372036854775809"]:
		result = await actions.correct_many({"name": "Not committed", "hit_points": text}, ids)
		assert_bool(result.ok).is_false()
		assert_str(actions.invalid_field).is_equal("hit_points")
		assert_dict(host.actors.hero.data).is_equal(before)
	result = await actions.correct_many({"hit_points": "-11", "maximum_hit_points": "3", "armor:reduction": "1d4", "attack:1:dice": "2d6+1", "rule:0:text": "Accepted correction"}, ids)
	assert_bool(result.ok).is_true()
	assert_int(result.actor.data.hit_points).is_equal(-11)
	assert_str(result.actor.data.armor.reduction).is_equal("d4")
	assert_str(result.actor.data.attacks[1].dice).is_equal("2d6+1")
	assert_str(result.actor.data.rules).contains("Accepted correction")
	result = await actions.correct_many({"hit_points": "+20"}, ids)
	assert_bool(result.ok).is_true()
	assert_int(result.actor.data.hit_points).is_equal(20)
	result = await actions.correct_many({"hit_points": "+00020"}, ids)
	assert_bool(result.ok).is_true()
	assert_int(result.actor.data.hit_points).is_equal(20)
	before = host.actors.hero.data.duplicate(true)
	host.fail_commit = true
	result = await actions.correct_many({"hit_points": "21"}, ids)
	assert_bool(result.ok).is_false()
	assert_dict(host.actors.hero.data).is_equal(before)
	host.fail_commit = false
	host.actors.hero.access_level = "Viewer"
	result = await actions.correct_many({"hit_points": "21"}, ids)
	assert_bool(result.ok).is_false()
	assert_dict(host.actors.hero.data).is_equal(before)
