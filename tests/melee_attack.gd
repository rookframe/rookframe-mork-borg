extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/melee_authority.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")
func test_melee_attack() -> void:
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	var sdk := SDK.new(host)
	var started: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": "action-1", "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"})
	assert_bool(started.ok and started.value.state == "pending").override_failure_message("Equipped melee requests the Player's attack Throw.").is_true()
	assert_bool(host.requests["action-1"].terms == [{"name": "Attack", "faces": 20, "count": 1}]).override_failure_message("The attack plan contains one Strength d20.").is_true()
	host.roll("action-1", [17])
	await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	assert_bool(host.requests[host.last_request].terms == [{"name": "Damage", "faces": 6, "count": 1}, {"name": "Protection", "faces": 4, "count": 1}]).override_failure_message("A hit requests source damage and authority-derived protection.").is_true()
	host.roll(host.last_request, [5, 4])
	var finished: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	assert_bool(finished.ok and finished.value.state == "resolved" and host.actors.enemy.data.hit_points == 3).override_failure_message("A 5 minus 2 hit changes private HP from 6 to 3.").is_true()
	assert_bool(host.actors.enemy.access_level == "None" and not str(finished.value).contains("Seth")).override_failure_message("Public result retains the chosen label without granting private access.").is_true()
	assert_bool(host.reports.size() == 1 and str(host.reports[0]).contains("Hooded stranger")).override_failure_message("The accepted consequence reports its public target name once.").is_true()
	await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	assert_bool(host.actors.enemy.data.hit_points == 3 and host.reports.size() == 1).override_failure_message("Duplicate resolution cannot apply damage or reports twice.").is_true()
	# Natural faces govern critical/fumble even when totals miss or beat the DR.
	host.actors.enemy.data.hit_points = 20
	await sdk.system_actions.submit("melee.start", _attack_input("critical"))
	host.roll("critical", [20])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	host.roll(host.last_request, [5, 4])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	assert_bool(host.actors.enemy.data.hit_points == 12 and host.actors.enemy.data.armor.reduction == "").override_failure_message("Critical doubles damage before protection and reduces protection one tier.").is_true()
	await sdk.system_actions.submit("melee.start", _attack_input("fumble"))
	host.roll("fumble", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "fumble"})
	assert_bool(host.actors.hero.data.inventory[0].broken and not host.actors.hero.data.inventory[0].equipped).override_failure_message("Fumble preserves the chosen broken weapon consequence.").is_true()
	var after_fumble: int = host.reports.size()
	await sdk.system_actions.submit("melee.cancel", {"id": "fumble"})
	assert_bool(host.actors.hero.data.inventory[0].broken and host.reports.size() == after_fumble).override_failure_message("Closing a completed fumble preserves accepted equipment and its report.").is_true()
	host.actors.hero.data.inventory[0].broken = false
	host.actors.hero.data.inventory[0].equipped = true
	host.actors.enemy.data["definition_id"] = "seth-goblin"
	var automatic := _attack_input("quick-creature")
	automatic.difficulty = 0
	var quick: SDK.DataResult = await sdk.system_actions.submit("melee.start", automatic)
	assert_bool(quick.value.state == "pending").override_failure_message("Source-prescribed difficulty can be selected without disclosing the Creature sheet.").is_true()
	if quick.value.state == "pending":
		host.roll("quick-creature", [13])
		await sdk.system_actions.submit("melee.advance", {"id": "quick-creature"})
		assert_bool(host.reports[-1].result == "Miss").override_failure_message("The Goblin's DR14 applies to a total of 12.").is_true()
	system.free()

func _attack_input(id: String) -> Dictionary:
	return {"id": id, "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"}

func test_d2_faces() -> void:
	for face in [1, 2, 3, 4]:
		var host = BOUNDARY.new()
		var system = SYSTEM.new()
		add_child(auto_free(system))
		host.handler = system
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory[0].damage = "d2"
		host.actors.enemy.data.armor.reduction = ""
		await sdk.system_actions.submit("melee.start", _attack_input("d2-weapon"))
		host.roll("d2-weapon", [17])
		await sdk.system_actions.submit("melee.advance", {"id": "d2-weapon"})
		assert_bool(host.requests[host.last_request].terms[0].faces == 4).override_failure_message("d2 weapons request a supported physical d4.").is_true()
		host.roll(host.last_request, [face])
		await sdk.system_actions.submit("melee.advance", {"id": "d2-weapon"})
		assert_bool(host.actors.enemy.data.hit_points == [5, 5, 4, 4][face - 1]).override_failure_message("Each raw d4 face gives the prescribed d2 damage.").is_true()
		assert_bool(str(host.reports[-1]).contains("d4 halved, rounded up")).override_failure_message("d2 interpretation preserves and explains its raw d4.").is_true()
		system.free()

func test_boundaries() -> void:
	for reach in [5, 10]:
		var host = BOUNDARY.new()
		var system = SYSTEM.new()
		add_child(auto_free(system))
		host.handler = system
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory[0].range_feet = reach
		host.distance = float(reach) * 0.3048
		var legal: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input("edge"))
		assert_bool(legal.value.state == "pending").override_failure_message("%d ft includes the exact committed-center boundary." % reach).is_true()
		await sdk.system_actions.submit("melee.cancel", {"id": "edge"})
		host.distance += 0.00001
		var outside: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input("outside"))
		assert_bool(outside.value.message == "target Hooded stranger not in range").override_failure_message("Range refusal uses the exact public label.").is_true()
		var reports: int = host.reports.size()
		await sdk.system_actions.submit("melee.start", _attack_input("outside"))
		assert_bool(host.reports.size() == reports).override_failure_message("Repeated failed submission cannot duplicate reports.").is_true()
		host.rooks["enemy-two"] = "enemy"
		host.targets = PackedStringArray(["enemy-rook", "enemy-two"])
		var all_invalid: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input("all-outside"))
		assert_bool(all_invalid.value.message.split("\n").size() == 2).override_failure_message("Every out-of-range target is reported; no valid subset is resolved.").is_true()
		host.distance = 1.0
		var too_many: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input("too-many"))
		assert_bool(too_many.value.state == "error" and host.requests.size() == 1).override_failure_message("Two in-range targets refuse the whole single-target action.").is_true()
		system.free()
	for stage in ["before-roll", "after-attack", "after-damage"]:
		var host = BOUNDARY.new()
		var system = SYSTEM.new()
		add_child(auto_free(system))
		host.handler = system
		var sdk := SDK.new(host)
		await sdk.system_actions.submit("melee.start", _attack_input("cancel"))
		if stage != "before-roll":
			host.roll("cancel", [17])
			await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		if stage == "after-damage":
			host.roll(host.last_request, [5, 4])
			await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		await sdk.system_actions.submit("melee.cancel", {"id": "cancel"})
		var expected := 3 if stage == "after-damage" else 6
		if stage != "after-damage":
			host.roll(host.last_request, [17] if stage == "before-roll" else [5, 4])
		await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		assert_bool(host.actors.enemy.data.hit_points == expected).override_failure_message("Closure at %s preserves accepted consequences and refuses late results." % stage).is_true()
		system.free()
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	var sdk := SDK.new(host)
	host.actors.hero.access_level = "Viewer"
	var denied: SDK.DataResult = await sdk.system_actions.submit("melee.start", _attack_input("viewer"))
	assert_bool(denied.value.state == "error" and host.requests.is_empty()).override_failure_message("Viewer cannot attack with a Character.").is_true()
	host.actors.hero.access_level = "Owner"
	host.actors.hero.data.inventory[0].equipped = false
	denied = await sdk.system_actions.submit("melee.start", _attack_input("unequipped"))
	assert_bool(denied.value.state == "error" and host.requests.is_empty()).override_failure_message("Unequipped weapons cannot attack.").is_true()
	host.actors.hero.data.inventory[0].equipped = true
	var loss := _attack_input("loss")
	loss.fumble = "lose"
	await sdk.system_actions.submit("melee.start", loss)
	host.roll("loss", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "loss"})
	assert_bool(host.actors.hero.data.inventory.is_empty()).override_failure_message("Loss fumble removes the only held weapon.").is_true()
	system.free()

func test_lifetime() -> void:
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	var sdk := SDK.new(host)
	host.game_master = true
	host.participant = "gm"
	host.access_entries = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "owner-session"}]
	await sdk.system_actions.submit("melee.start", _attack_input("owner"))
	assert_bool(host.requests.owner.participant == "player").override_failure_message("A GM's action requests its connected Player Owner.").is_true()
	host.access_entries[0].session_id = "replacement-session"
	host.roll("owner", [20])
	var ended: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "owner"})
	assert_bool(ended.value.state == "ended" and host.requests.size() == 1).override_failure_message("A replacement Owner session cannot resume the old action.").is_true()
	host.game_master = false
	host.participant = "player"
	await sdk.system_actions.submit("melee.start", _attack_input("restart"))
	system.free()
	system = SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	ended = await sdk.system_actions.submit("melee.start", _attack_input("restart"))
	assert_bool(ended.value.state == "ended").override_failure_message("Reopened System does not resume a durable Throw identity.").is_true()
	var delayed := ACTION.new(sdk)
	add_child(auto_free(delayed))
	host.defer_reply = true
	delayed.start(_attack_input("ignored"))
	var request: String = host.last_request
	await delayed.cancel()
	host.complete_reply()
	await get_tree().process_frame
	assert_bool(not delayed.pending and host.requests[request].result.status == "cancelled").override_failure_message("Close before acknowledgement cancels the accepted Throw.").is_true()
	var coalesced := ACTION.new(sdk)
	add_child(auto_free(coalesced))
	await coalesced.start(_attack_input("ignored"))
	request = host.last_request
	host.defer_reply = true
	coalesced.refresh()
	host.roll(request, [2])
	coalesced.refresh()
	host.complete_reply()
	await get_tree().process_frame
	assert_bool(coalesced.state == "resolved" and coalesced.message.contains("misses")).override_failure_message("A settled update during a pending reply is not lost.").is_true()
	system.free()

func test_review_regressions() -> void:
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	var sdk := SDK.new(host)
	for field in ["id", "source", "rook", "item", "difficulty", "modifier", "fumble", "piercing"]:
		var malformed := _attack_input("bad-" + field)
		malformed[field] = []
		var refused: SDK.DataResult = await sdk.system_actions.submit("melee.start", malformed)
		assert_bool(refused.ok and refused.value.state == "error" and host.requests.is_empty()).override_failure_message("Malformed %s is refused without failing the World." % field).is_true()
	host.game_master = true
	host.participant = "gm"
	host.access_entries = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "owner-session"}]
	await sdk.system_actions.submit("melee.start", _attack_input("revoked-owner"))
	host.access_entries[0].access_level = "Viewer"
	host.roll("revoked-owner", [20])
	var ended: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "revoked-owner"})
	assert_bool(ended.value.state == "ended" and host.requests.size() == 1 and host.actors.enemy.data.hit_points == 6).override_failure_message("Revoked delegated ownership ends a GM-started action without consequence.").is_true()
	host.game_master = false
	host.participant = "player"
	host.actors.hero.data.name = "😀".repeat(40)
	host.actors.hero.data.inventory[0].name = "🗡".repeat(40)
	await sdk.system_actions.submit("melee.start", _attack_input("long-names"))
	host.roll("long-names", [17])
	await sdk.system_actions.submit("melee.advance", {"id": "long-names"})
	host.roll(host.last_request, [5, 4])
	var hit: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "long-names"})
	assert_bool(hit.value.state == "resolved" and host.actors.enemy.data.hit_points == 3 and host.reports[-1].title.length() <= 72).override_failure_message("Long editable names cannot prevent the accepted damage/report commit.").is_true()
	host.actors.enemy.data.defence_dr = 29
	var automatic := _attack_input("private-miss")
	automatic.difficulty = 0
	await sdk.system_actions.submit("melee.start", automatic)
	host.roll("private-miss", [13])
	await sdk.system_actions.submit("melee.advance", {"id": "private-miss"})
	assert_bool(not str(host.reports[-1]).contains("29") and not str(host.reports[-1]).contains("DR")).override_failure_message("A miss report does not expose private defence difficulty.").is_true()
	var action := ACTION.new(sdk)
	add_child(auto_free(action))
	await action.start(_attack_input("unused"))
	var request: String = host.last_request
	host.roll(request, [2])
	host.transient_failures["melee.advance"] = 1
	await action.refresh()
	assert_bool(action.state == "resolved" and not action.pending).override_failure_message("A transient advance reply retries the same live action to its accepted result.").is_true()
	await action.retire()
	action = ACTION.new(sdk)
	add_child(auto_free(action))
	await action.start(_attack_input("unused"))
	request = host.last_request
	host.transient_failures["melee.cancel"] = 1
	await action.cancel()
	assert_bool(host.requests[request].result.status == "cancelled" and action.state == "ended").override_failure_message("A transient cancellation retries until the outstanding Throw is cancelled.").is_true()
	await action.retire()
	action = ACTION.new(sdk)
	add_child(auto_free(action))
	await action.start(_attack_input("unused"))
	request = host.last_request
	host.roll(request, [17])
	host.transient_failures["melee.advance"] = 1
	host.transient_failures["melee.cancel"] = 2
	var advances_before: int = host.submissions.get("melee.advance", 0)
	action.refresh()
	action.cancel()
	action.retire()
	await get_tree().create_timer(1.2).timeout
	var closed: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": request})
	assert_bool(closed.value.state == "ended" and host.last_request == request).override_failure_message("Retirement waits for concurrent cancellation retries and cannot start a damage Throw after closure.").is_true()
	assert_bool(host.submissions["melee.advance"] == advances_before + 1).override_failure_message("Closure stops an advance before its retry is sent.").is_true()
	assert_bool(not is_instance_valid(action)).override_failure_message("Retired action releases its Node after cancellation is acknowledged.").is_true()
	system.free()

func after_test() -> void:
	await get_tree().process_frame
