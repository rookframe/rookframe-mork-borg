extends SceneTree
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTION = preload(ROOT + "logic/ability_throw.gd")
const BOUNDARY = preload("res://tests/creation_sdk_boundary.gd")
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var host = BOUNDARY.new()
	host.actors.append({"id": "character", "access_level": "Owner", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "abilities": {"Strength": {"modifier": -1}}}})
	var action = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await action.start("Strength")
	_check(action.pending and host.human_requests.size() == 1, "Modifier requests one human Throw.")
	_check(host.human_requests[0].participant == "player" and host.human_requests[0].terms == [{"name": "Strength", "faces": 20, "count": 1}], "The responsible Player receives an unchanged d20 plan.")
	var id: String = action.request_id
	host.human_results[id] = {"status": "rolled", "sequence": 42, "terms": [{"name": "Strength", "faces": 20, "results": [17]}]}
	await action.refresh()
	_check(not action.pending and host.reports.size() == 1, "Settled result finishes and reports once.")
	_check(host.reports[0].result == "16" and host.reports[0].dice == [{"sides": 20, "value": 17}], "Interpretation retains raw 17 and applies Strength -1.")
	await action.refresh()
	await action.cancel()
	_check(host.reports.size() == 1, "Refresh and closure after completion do not duplicate or undo.")
	var cancelled = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await cancelled.start("Strength")
	var cancelled_id: String = cancelled.request_id
	await cancelled.cancel()
	host.human_results[cancelled_id] = {"status": "rolled", "sequence": 43, "terms": [{"name": "Strength", "faces": 20, "results": [20]}]}
	await cancelled.refresh()
	_check(host.reports.size() == 2 and host.reports[1].result == "ENDED", "Cancellation rejects late interpreted consequences.")
	var disconnected = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await disconnected.start("Strength")
	host.human_results[disconnected.request_id].status = "cancelled"
	await disconnected.refresh()
	_check(not disconnected.pending and host.reports[2].result == "ENDED", "A required disconnect ends the System action.")
	host.actors[0].access_level = "Viewer"
	var viewer = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await viewer.start("Strength")
	_check(not viewer.pending and viewer.failed and host.human_requests.size() == 3, "Viewer cannot originate a modifier Throw.")
	host.actors[0].access_level = "Owner"
	host.game_master = true
	host.access_entries.append({"participant_id": "owner", "display_name": "Player", "access_level": "Owner", "is_connected": true})
	var gm = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await gm.start("Strength")
	_check(host.human_requests[3].participant == "owner", "GM initiation routes to the Character's Player.")
	await gm.cancel()
	host.access_entries[0].is_connected = false
	var offline = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await offline.start("Strength")
	_check(offline.failed and host.human_requests.size() == 4, "Offline owner is not replaced by the GM.")
	host.game_master = false
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	root.add_child(sheet)
	var sdk := SDK.new(host)
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(sdk.actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, sdk)
	await process_frame
	await process_frame
	var button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	button.pressed.emit()
	await process_frame
	await process_frame
	_check(host.human_requests.size() == 5, "The authored modifier directly originates its human Throw.")
	button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	_check(button.disabled and button.icon != null, "Pending modifier is explicit and prevents duplicate actions.")
	host.actors[0].data["silver"] = 23
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	_check(button.disabled and button.icon != null, "Actor changes retain the pending modifier state.")
	sheet.close_action()
	await process_frame
	_check(host.human_results[host.human_requests[4].id].status == "cancelled", "Sheet closure ends its pending request.")
	sheet._roll_ability("Strength")
	await process_frame
	host.defer_human = true
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	var queued_id: String = host.human_requests[-1].id
	host.human_results[queued_id] = {"status": "rolled", "sequence": 49, "terms": [{"name": "Strength", "faces": 20, "results": [19]}]}
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	host.complete_human()
	await process_frame
	await process_frame
	_check(host.reports[-1].result == "18", "A final update during an older pending reply is not lost.")
	sheet.free()
	host.defer_human = true
	var delayed = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	delayed.start("Strength")
	await delayed.cancel()
	var report_count: int = host.reports.size()
	host.complete_human()
	await process_frame
	_check(not delayed.pending and host.human_results[delayed.request_id].status == "cancelled" and host.reports.size() == report_count, "Closing before request acknowledgement cancels the accepted request without a late result.")
	var accepted = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await accepted.start("Strength")
	host.human_results[accepted.request_id] = {"status": "rolled", "sequence": 50, "terms": [{"name": "Strength", "faces": 20, "results": [20]}]}
	await accepted.cancel()
	await accepted.refresh()
	_check(host.human_results[accepted.request_id].status == "rolled" and host.reports[-1].result == "ENDED", "Closure after raw acceptance preserves the Roll and rejects later interpretation.")
	print("ABILITY_THROW %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
