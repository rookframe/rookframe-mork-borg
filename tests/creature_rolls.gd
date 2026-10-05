extends GdUnitTestSuite
## Severe normal-use risk: late/retried completion must not duplicate accepted reports.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const WORKFLOW = preload(ROOT + "ui/creature_roll_workflow.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func test_creature_roll_completion_is_once_immutable_and_late_abandonment_cancels() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	host.actors.hero.data.attacks[0].dice = "2d2+3"
	var sdk := SDK.new(host)
	var input := {"id": "accepted-once", "source": "hero", "part": "damage", "entry": str(host.actors.hero.data.attacks[0].id)}
	var result := await sdk.system_actions.submit("creature-roll.start", input)
	assert_str(result.value.state).is_equal("pending")
	assert_int(host.requests["accepted-once"].terms[0].faces).is_equal(4)
	assert_int(host.requests["accepted-once"].terms[0].count).is_equal(2)
	# Corrections and independent gameplay accepted while dice run do not redirect the snapshot.
	host.actors.hero.data.attacks[0].dice = "d20"
	host.actors.hero.data.attacks[0].name = "New accepted attack"
	host.actors.hero.data.inventory = [{"inventory_id": "loot", "name": "Unspent loot", "quantity": 8}]
	host.actors.hero.data.portrait = "portraits/saved-creature.png"
	var before: Dictionary = host.actors.duplicate(true)
	host.roll("accepted-once", [3, 3])
	result = await sdk.system_actions.submit("creature-roll.advance", {"id": "accepted-once"})
	assert_str(result.value.state).is_equal("resolved")
	assert_int(result.value.total).is_equal(7)
	assert_str(result.value.choice.formula).is_equal("2d2+3")
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("7")
	assert_int(host.reports[0].dice[0].sides).is_equal(4)
	assert_int(host.reports[0].dice[0].value).is_equal(3)
	for operation in ["advance", "start", "cancel", "advance"]:
		result = await sdk.system_actions.submit("creature-roll." + operation, input)
		assert_str(result.value.state).is_equal("resolved")
	assert_int(host.reports.size()).is_equal(1)
	assert_dict(host.actors).is_equal(before)
	# A failed atomic commit ends this workflow without a report or gameplay write.
	input.id = "failed-once"
	result = await sdk.system_actions.submit("creature-roll.start", input)
	host.roll("failed-once", [12])
	host.fail_commit = true
	result = await sdk.system_actions.submit("creature-roll.advance", {"id": "failed-once"})
	assert_str(result.value.state).is_equal("ended")
	host.fail_commit = false
	result = await sdk.system_actions.submit("creature-roll.advance", {"id": "failed-once"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.reports.size()).is_equal(1)
	assert_dict(host.actors).is_equal(before)
	# Abandon before the accepted start reply: existing transport orders cancellation after it.
	var action := ACTION.new(sdk)
	action._operation = "creature-roll"
	add_child(action)
	host.defer_reply = true
	action.start({"source": "hero", "part": "damage", "entry": str(input.entry)})
	var late := host.last_request
	action.retire()
	host.complete_reply()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(host.requests[late].result.status).is_equal("cancelled")
	# Even an unsolicited late raw result cannot interpret an abandoned action.
	host.roll(late, [20])
	result = await sdk.system_actions.submit("creature-roll.advance", {"id": late})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.reports.size()).is_equal(1)
	assert_dict(host.actors).is_equal(before)

	# Actual surface removal frees the poller, unlike Close. Cancellation must
	# survive that free even when its accepted start reply arrives afterward.
	for delayed in [false, true]:
		var surface := Control.new()
		add_child(surface)
		var workflow := WORKFLOW.new()
		surface.add_child(workflow)
		workflow.configure(sdk, surface)
		host.defer_reply = delayed
		workflow.start("hero", "damage", str(input.entry))
		var removed := host.last_request
		var cancellations := int(host.submissions.get("creature-roll.cancel", 0))
		# Same-Actor hide/Close preserves the accepted request.
		workflow.closed()
		assert_str(host.requests[removed].result.status).is_equal("pending")
		remove_child(surface)
		surface.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		assert_bool(is_instance_valid(workflow)).is_false()
		if delayed:
			assert_int(int(host.submissions.get("creature-roll.cancel", 0))).is_equal(cancellations)
			host.complete_reply()
			await get_tree().process_frame
			await get_tree().process_frame
		assert_str(host.requests[removed].result.status).is_equal("cancelled")
		assert_int(int(host.submissions.get("creature-roll.cancel", 0))).is_equal(cancellations + 1)
		var replacement := Control.new()
		add_child(replacement)
		var fresh := WORKFLOW.new()
		replacement.add_child(fresh)
		fresh.configure(sdk, replacement)
		fresh.opened("enemy")
		assert_bool(fresh.has_action).is_false()
		assert_bool(fresh.pending).is_false()
		assert_str(fresh.source).is_empty()
		host.roll(removed, [20])
		result = await sdk.system_actions.submit("creature-roll.advance", {"id": removed})
		assert_str(result.value.state).is_equal("ended")
		assert_int(host.reports.size()).is_equal(1)
		assert_dict(host.actors).is_equal(before)
		replacement.queue_free()
		await get_tree().process_frame
