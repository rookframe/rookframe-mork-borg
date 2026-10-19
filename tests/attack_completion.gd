extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const WINDOW = preload(ROOT + "ui/tabletop_attack.tscn")
var _windows: Array[Node] = []

class WindowHost:
	extends "res://tests/melee_sdk_boundary.gd"
	var closed_surfaces: Array[String] = []
	var window: Control
	func WorldContext() -> Dictionary:
		return {"ok": true, "value": {"participant_id": participant, "session_id": session, "is_gm": game_master, "is_authority": true}}
	func PresentationDevice() -> int:
		return 0
	func CurrentScene() -> Dictionary:
		return {"ok": false}
	func EndTargetRange() -> Dictionary:
		return {"ok": true}
	func CloseWindow(scene: PackedScene) -> Dictionary:
		closed_surfaces.append(scene.resource_path)
		window.hide()
		window.closed.emit()
		return {"ok": true}
	func SelectedRookContext() -> Dictionary:
		return {"id": "hero-rook"}
	func ListRooks() -> Dictionary:
		return {"ok": true, "value": []}

func _host() -> WindowHost:
	var host := WindowHost.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	return host

func _window(host: WindowHost, outcome: Dictionary, incoming: bool = false):
	var window = WINDOW.instantiate()
	_windows.append(window)
	window.sdk = SDK.new(host)
	host.window = window
	add_child(window)
	window.set_process(false)
	window._actor = SDK.ActorId.new("hero")
	window._closed = false
	window._incoming = incoming
	window._new_action()
	window._action.adopt(outcome)
	return window

func _outcome(state: String) -> Dictionary:
	return {"id": "attack", "state": state, "source": "hero", "character": "Graveworm", "weapon": "Shortsword", "message": "Result already recorded in the Action Log."}

func test_completed_hit_and_miss_close_without_another_click_or_log_entry(do_hit: bool, test_parameters := [[true], [false]]) -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "1", "tabletop": true})
	host.roll("attack", [18 if do_hit else 2])
	var outcome := await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	if do_hit:
		host.roll(host.last_request, [4, 1])
		outcome = await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_str(outcome.value.state).is_equal("resolved")
	var window = _window(host, outcome.value)
	await window._refresh()
	assert_bool(window._closed).is_true()
	assert_bool(window.visible).is_false()
	assert_array(host.closed_surfaces).is_equal([ROOT + "ui/tabletop_attack.tscn"])
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("3 damage" if do_hit else "Miss")
	assert_int(host.actors.enemy.data.hit_points).is_equal(3 if do_hit else 6)
	assert_int(host.submissions.get("melee.cancel", 0)).is_equal(0)

func test_required_shield_and_fumble_choices_stay_open(state: String, test_parameters := [["shield"], ["fumble"]]) -> void:
	var host := _host()
	host.game_master = true
	var outcome := _outcome(state)
	outcome.merge({"defender": "player", "target": "hero", "loss": 3})
	var window = _window(host, outcome, true)
	await window._refresh()
	assert_bool(window._closed).is_false()
	assert_bool(window.card.body.get_node("Decision").visible).is_true()
	assert_str(window.card.body.get_node("Decision/First").text).is_equal("Take 3 damage" if state == "shield" else "Broken")
	# Complete the outstanding choice, then let the same window refresh.
	outcome.state = "resolved"
	window._action.adopt(outcome)
	await window._refresh()
	assert_array(host.closed_surfaces).is_equal([ROOT + "ui/tabletop_consequence.tscn"])

func test_broken_roll_and_followup_stay_open_then_close_on_completion() -> void:
	var host := _host()
	host.actors.hero.data.merge({"hit_points": 0, "maximum_hit_points": 6})
	var outcome := _outcome("resolved")
	outcome.merge({"defender": "player", "target": "hero"})
	var window = _window(host, outcome, true)
	await window._refresh()
	assert_bool(window._closed).is_false()
	assert_str(window.card.body.get_node("Decision/First").text).is_equal("Roll Broken")
	await window._decision(0)
	await window._refresh()
	assert_bool(window._closed).is_false()
	host.roll(host.last_request, [1])
	await window._health.refresh()
	await window._refresh()
	assert_bool(window._closed).is_false()
	assert_bool(window._health.pending).is_true()
	host.roll(host.last_request, [2, 3])
	await window._health.refresh()
	await window._refresh()
	assert_bool(window._closed).is_true()
	assert_array(host.closed_surfaces).is_equal([ROOT + "ui/tabletop_consequence.tscn"])
	assert_int(host.actors.hero.data.broken_incident.outcome).is_equal(1)
	assert_bool(host.actors.hero.data.broken_incident.has("followup_sequence")).is_true()
	assert_int(host.reports.size()).is_equal(2)

func test_completed_incoming_task_advances_to_queued_defence() -> void:
	var host := _host()
	var window = _window(host, _outcome("resolved"), true)
	var next := _outcome("ready")
	next.merge({"defender": "player", "target": "hero", "damage": "1d4"})
	next.id = "second-defence"
	window._queued.append({"actor": "hero", "task": {"incoming": true, "outcome": next}})
	await window._refresh()
	assert_bool(window._closed).is_false()
	assert_bool(host.closed_surfaces.is_empty()).is_true()
	assert_str(window._action.snapshot.id).is_equal("second-defence")
	await window._refresh()
	assert_bool(window.card.body.get_node("Combat").visible).is_true()
	# Retire without cancelling a synthetic authority action during fixture cleanup.
	window._action.pending = false
	window._queued.clear()

func test_resolved_broken_incident_does_not_require_another_roll(dead: bool, test_parameters := [[false], [true]]) -> void:
	var host := _host()
	host.actors.hero.data.merge({"hit_points": 0, "broken_incident": {"outcome": 4 if dead else 1, "dead": dead, "followup_sequence": 3}})
	var window = _window(host, _outcome("resolved"), true)
	await window._refresh()
	assert_bool(window._closed).is_true()
	assert_bool(host.requests.is_empty()).is_true()

func test_interrupted_action_keeps_its_explanation() -> void:
	var host := _host()
	var window = _window(host, _outcome("ended"))
	await window._refresh()
	assert_bool(window._closed).is_false()
	assert_bool(host.closed_surfaces.is_empty()).is_true()
	assert_str(window.card.body.get_node("Decision/First").text).is_equal("Done")

func test_pending_attack_stays_hidden_until_an_actual_decision() -> void:
	var host := _host()
	var window = _window(host, _outcome("pending"))
	window._changed()
	await window._refresh()
	assert_bool(window.visible).is_false()
	var visible_states: Array[bool] = []
	window.visibility_changed.connect(func(): visible_states.append(window.visible))
	window._action.adopt(_outcome("resolved"))
	await window._refresh()
	assert_bool(visible_states.has(true)).is_false()
	assert_bool(window._closed).is_true()

func test_attack_record_retains_roll_hit_damage_and_final_result() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", {"id": "attack", "source": "hero", "rook": "hero-rook", "item": "1", "tabletop": true})
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("In progress")
	assert_int(host.requests.attack.log_sequence).is_equal(1)
	host.roll("attack", [18])
	await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("Hit")
	assert_int(host.requests[host.last_request].log_sequence).is_equal(1)
	host.roll(host.last_request, [4, 1])
	await sdk.system_actions.submit("melee.advance", {"id": "attack"})
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("3 damage")
	assert_int(host.report_steps[1].size()).is_equal(5)
	assert_str(str(host.report_steps)).not_contains("Raw Roll #")

func after_test() -> void:
	for window in _windows:
		window.free()
	_windows.clear()
	await get_tree().process_frame
