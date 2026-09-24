extends SceneTree
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/melee_authority.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	root.add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	var started: SDK.DataResult = await sdk.system_actions.submit("melee.start", {"id": "action-1", "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"})
	_check(started.ok and started.value.state == "pending", "Equipped melee requests the Player's attack Throw.")
	_check(host.requests["action-1"].terms == [{"name": "Attack", "faces": 20, "count": 1}], "The attack plan contains one Strength d20.")
	host.roll("action-1", [17])
	await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	_check(host.requests[host.last_request].terms == [{"name": "Damage", "faces": 6, "count": 1}, {"name": "Protection", "faces": 2, "count": 1}], "A hit requests source damage and authority-derived protection.")
	host.roll(host.last_request, [5, 2])
	var finished: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	_check(finished.ok and finished.value.state == "resolved" and host.actors.enemy.data.hit_points == 3, "A 5 minus 2 hit changes private HP from 6 to 3.")
	_check(host.actors.enemy.access_level == "None" and not str(finished.value).contains("Seth"), "Public result retains the chosen label without granting private access.")
	_check(host.reports.size() == 1 and str(host.reports[0]).contains("Hooded stranger"), "The accepted consequence reports its public target name once.")
	await sdk.system_actions.submit("melee.advance", {"id": "action-1"})
	_check(host.actors.enemy.data.hit_points == 3 and host.reports.size() == 1, "Duplicate resolution cannot apply damage or reports twice.")
	# Natural faces govern critical/fumble even when totals miss or beat the DR.
	host.actors.enemy.data.hit_points = 20
	await sdk.system_actions.submit("melee.start", _input("critical"))
	host.roll("critical", [20])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	host.roll(host.last_request, [5, 2])
	await sdk.system_actions.submit("melee.advance", {"id": "critical"})
	_check(host.actors.enemy.data.hit_points == 12 and host.actors.enemy.data.armor.reduction == "", "Critical doubles damage before protection and reduces protection one tier.")
	await sdk.system_actions.submit("melee.start", _input("fumble"))
	host.roll("fumble", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "fumble"})
	_check(host.actors.hero.data.inventory[0].broken and not host.actors.hero.data.inventory[0].equipped, "Fumble preserves the chosen broken weapon consequence.")
	var after_fumble: int = host.reports.size()
	await sdk.system_actions.submit("melee.cancel", {"id": "fumble"})
	_check(host.actors.hero.data.inventory[0].broken and host.reports.size() == after_fumble, "Closing a completed fumble preserves accepted equipment and its report.")
	host.actors.hero.data.inventory[0].broken = false
	host.actors.hero.data.inventory[0].equipped = true
	host.actors.enemy.data["definition_id"] = "seth-goblin"
	var automatic := _input("quick-creature")
	automatic.difficulty = 0
	var quick: SDK.DataResult = await sdk.system_actions.submit("melee.start", automatic)
	_check(quick.value.state == "pending", "Source-prescribed difficulty can be selected without disclosing the Creature sheet.")
	if quick.value.state == "pending":
		host.roll("quick-creature", [13])
		await sdk.system_actions.submit("melee.advance", {"id": "quick-creature"})
		_check(host.reports[-1].result == "Miss", "The Goblin's DR14 applies to a total of 12.")
	await _boundaries()
	await _lifetime()
	system.free()
	print("MELEE_ATTACK %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _input(id: String) -> Dictionary:
	return {"id": id, "source": "hero", "rook": "hero-rook", "item": "1", "difficulty": 12, "modifier": 0, "fumble": "break"}

func _boundaries() -> void:
	for reach in [5, 10]:
		var host = BOUNDARY.new()
		var system = SYSTEM.new()
		root.add_child(system)
		host.handler = system
		var sdk := SDK.new(host)
		host.actors.hero.data.inventory[0].range_feet = reach
		host.distance = float(reach) * 0.3048
		var legal: SDK.DataResult = await sdk.system_actions.submit("melee.start", _input("edge"))
		_check(legal.value.state == "pending", "%d ft includes the exact committed-center boundary." % reach)
		await sdk.system_actions.submit("melee.cancel", {"id": "edge"})
		host.distance += 0.00001
		var outside: SDK.DataResult = await sdk.system_actions.submit("melee.start", _input("outside"))
		_check(outside.value.message == "target Hooded stranger not in range", "Range refusal uses the exact public label.")
		var reports: int = host.reports.size()
		await sdk.system_actions.submit("melee.start", _input("outside"))
		_check(host.reports.size() == reports, "Repeated failed submission cannot duplicate reports.")
		host.rooks["enemy-two"] = "enemy"
		host.targets = PackedStringArray(["enemy-rook", "enemy-two"])
		var all_invalid: SDK.DataResult = await sdk.system_actions.submit("melee.start", _input("all-outside"))
		_check(all_invalid.value.message.split("\n").size() == 2, "Every out-of-range target is reported; no valid subset is resolved.")
		host.distance = 1.0
		var too_many: SDK.DataResult = await sdk.system_actions.submit("melee.start", _input("too-many"))
		_check(too_many.value.state == "error" and host.requests.size() == 1, "Two in-range targets refuse the whole single-target action.")
		system.free()
	for stage in ["before-roll", "after-attack", "after-damage"]:
		var host = BOUNDARY.new()
		var system = SYSTEM.new()
		root.add_child(system)
		host.handler = system
		var sdk := SDK.new(host)
		await sdk.system_actions.submit("melee.start", _input("cancel"))
		if stage != "before-roll":
			host.roll("cancel", [17])
			await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		if stage == "after-damage":
			host.roll(host.last_request, [5, 2])
			await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		await sdk.system_actions.submit("melee.cancel", {"id": "cancel"})
		var expected := 3 if stage == "after-damage" else 6
		if stage != "after-damage":
			host.roll(host.last_request, [17] if stage == "before-roll" else [5, 2])
		await sdk.system_actions.submit("melee.advance", {"id": "cancel"})
		_check(host.actors.enemy.data.hit_points == expected, "Closure at %s preserves accepted consequences and refuses late results." % stage)
		system.free()
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	root.add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	host.actors.hero.access_level = "Viewer"
	var denied: SDK.DataResult = await sdk.system_actions.submit("melee.start", _input("viewer"))
	_check(denied.value.state == "error" and host.requests.is_empty(), "Viewer cannot attack with a Character.")
	host.actors.hero.access_level = "Owner"
	host.actors.hero.data.inventory[0].equipped = false
	denied = await sdk.system_actions.submit("melee.start", _input("unequipped"))
	_check(denied.value.state == "error" and host.requests.is_empty(), "Unequipped weapons cannot attack.")
	host.actors.hero.data.inventory[0].equipped = true
	var loss := _input("loss")
	loss.fumble = "lose"
	await sdk.system_actions.submit("melee.start", loss)
	host.roll("loss", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "loss"})
	_check(host.actors.hero.data.inventory.is_empty(), "Loss fumble removes the only held weapon.")
	system.free()

func _lifetime() -> void:
	var host = BOUNDARY.new()
	var system = SYSTEM.new()
	root.add_child(system)
	host.handler = system
	var sdk := SDK.new(host)
	host.game_master = true
	host.participant = "gm"
	host.access_entries = [{"participant_id": "player", "display_name": "Player", "access_level": "Owner", "is_connected": true, "session_id": "owner-session"}]
	await sdk.system_actions.submit("melee.start", _input("owner"))
	_check(host.requests.owner.participant == "player", "A GM's action requests its connected Player Owner.")
	host.access_entries[0].session_id = "replacement-session"
	host.roll("owner", [20])
	var ended: SDK.DataResult = await sdk.system_actions.submit("melee.advance", {"id": "owner"})
	_check(ended.value.state == "ended" and host.requests.size() == 1, "A replacement Owner session cannot resume the old action.")
	host.game_master = false
	host.participant = "player"
	await sdk.system_actions.submit("melee.start", _input("restart"))
	system.free()
	system = SYSTEM.new()
	root.add_child(system)
	host.handler = system
	ended = await sdk.system_actions.submit("melee.start", _input("restart"))
	_check(ended.value.state == "ended", "Reopened System does not resume a durable Throw identity.")
	var delayed := ACTION.new(sdk)
	host.defer_reply = true
	delayed.start(_input("ignored"))
	var request: String = host.last_request
	await delayed.cancel()
	host.complete_reply()
	await process_frame
	_check(not delayed.pending and host.requests[request].result.status == "cancelled", "Close before acknowledgement cancels the accepted Throw.")
	var coalesced := ACTION.new(sdk)
	await coalesced.start(_input("ignored"))
	request = host.last_request
	host.defer_reply = true
	coalesced.refresh()
	host.roll(request, [2])
	coalesced.refresh()
	host.complete_reply()
	await process_frame
	_check(coalesced.state == "resolved" and coalesced.message.contains("misses"), "A settled update during a pending reply is not lost.")
	system.free()
