extends GdUnitTestSuite
## Severe normal-use risk: a retried relative adjustment must never apply twice.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const REQUEST = preload(ROOT + "logic/action_request.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

class Host extends BOUNDARY:
	var commits := 0
	var lose_readback := false
	func SystemIntentCommit(token: String, changes: Array, report: Dictionary) -> Dictionary:
		var result := super.SystemIntentCommit(token, changes, report)
		if result.ok:
			commits += 1
		return result
	func SystemIntentReadActor(token: String, id: String) -> Dictionary:
		if lose_readback and commits > 0:
			lose_readback = false
			return {"ok": false, "message": "Acknowledgement unavailable"}
		return super.SystemIntentReadActor(token, id)

func test_relative_hp_retries_preserve_latest_actor_and_apply_accepted_change_once() -> void:
	var host := Host.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var untouched: Dictionary = host.actors.enemy.data.duplicate(true)
	# An older client snapshot must not overwrite accepted independent operations.
	var old := sdk.actors.read(SDK.ActorId.new("hero"))
	host.actors.hero.data.hit_points = 23
	host.actors.hero.data["portrait"] = "portraits/saved-creature.png"
	host.actors.hero.data["preferred_miniature"] = {"package_id": "package", "local_id": "miniature"}
	host.actors.hero.data["inventory"] = [{"inventory_id": "saved", "name": "Accepted loot", "quantity": 7}]
	host.actors.hero.data.rules = "Accepted rules"
	host.transient_failures["creature-health.adjust"] = 1
	host.lose_readback = true
	var result := await actions.adjust_health("relative-1", "damage", "30", REQUEST.new(sdk, host.handler))
	assert_bool(result.ok).is_false()
	assert_int(host.actors.hero.data.hit_points).is_equal(-7)
	assert_int(host.commits).is_equal(1)
	assert_int(old.actor.data.hit_points).is_equal(6)
	# The accepted marker precedes readback. A retry acknowledges without a second write.
	result = await ACTIONS.new(sdk, SDK.ActorId.new("hero")).adjust_health("relative-1", "damage", "30")
	assert_bool(result.ok).is_true()
	assert_int(result.actor.data.hit_points).is_equal(-7)
	assert_int(host.commits).is_equal(1)
	assert_int(result.actor.data.inventory[0].quantity).is_equal(7)
	assert_str(result.actor.data.rules).is_equal("Accepted rules")
	assert_bool(result.actor.data.portrait == "portraits/saved-creature.png").is_true()
	assert_str(result.actor.data.preferred_miniature.local_id).is_equal("miniature")
	# Reopening reads newer accepted HP; acknowledging an old identity cannot rewind it.
	host.actors.hero.data.hit_points = 11
	result = await actions.adjust_health("relative-1", "damage", "30")
	assert_int(result.actor.data.hit_points).is_equal(11)
	assert_int(host.commits).is_equal(1)
	result = await actions.adjust_health("relative-1", "heal", "30")
	assert_bool(result.ok).is_false()
	assert_int(host.actors.hero.data.hit_points).is_equal(11)
	host.session = "another-session"
	result = await actions.adjust_health("relative-1", "damage", "30")
	assert_bool(result.ok).is_false()
	host.session = "player-session"
	# Failed storage is atomic and is not marked accepted; a later permitted retry applies once.
	host.fail_commit = true
	var before: Dictionary = host.actors.hero.data.duplicate(true)
	result = await actions.adjust_health("relative-2", "heal", "30")
	assert_bool(result.ok).is_false()
	assert_dict(host.actors.hero.data).is_equal(before)
	host.fail_commit = false
	result = await actions.adjust_health("relative-2", "heal", "30")
	assert_bool(result.ok).is_true()
	assert_int(result.actor.data.hit_points).is_equal(41)
	result = await actions.adjust_health("relative-2", "heal", "30")
	assert_int(result.actor.data.hit_points).is_equal(41)
	assert_int(host.commits).is_equal(2)
	# Neither oversized text nor relative arithmetic may wrap accepted signed HP.
	before = host.actors.hero.data.duplicate(true)
	result = await actions.adjust_health("too-large", "heal", "9223372036854775808")
	assert_bool(result.ok).is_false()
	assert_dict(host.actors.hero.data).is_equal(before)
	for state in [{"hp": 9223372036854775807, "operation": "heal"}, {"hp": -9223372036854775807 - 1, "operation": "damage"}]:
		host.actors.hero.data.hit_points = state.hp
		before = host.actors.hero.data.duplicate(true)
		result = await actions.adjust_health("overflow-" + str(state.operation), str(state.operation), "1")
		assert_bool(result.ok).is_false()
		assert_dict(host.actors.hero.data).is_equal(before)
	assert_int(host.commits).is_equal(2)
	assert_dict(host.actors.enemy.data).is_equal(untouched)
	assert_int(host.requests.size()).is_equal(0)
	assert_int(host.reports.size()).is_equal(0)
