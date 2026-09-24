extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTION = preload(ROOT + "logic/ability_throw.gd")
const BOUNDARY = preload("res://tests/creation_sdk_boundary.gd")
func test_ability_throw() -> void:
	var host = BOUNDARY.new()
	host.actors.append({"id": "character", "access_level": "Owner", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "abilities": {"Strength": {"modifier": -1}}}})
	var action = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await action.start("Strength")
	assert_bool(action.pending and host.human_requests.size() == 1).override_failure_message("Modifier requests one human Throw.").is_true()
	assert_bool(host.human_requests[0].participant == "player" and host.human_requests[0].terms == [{"name": "Strength", "faces": 20, "count": 1}]).override_failure_message("The responsible Player receives an unchanged d20 plan.").is_true()
	var id: String = action.request_id
	host.human_results[id] = {"status": "rolled", "sequence": 42, "terms": [{"name": "Strength", "faces": 20, "results": [17]}]}
	await action.refresh()
	assert_bool(not action.pending and host.reports.size() == 1).override_failure_message("Settled result finishes and reports once.").is_true()
	assert_bool(host.reports[0].result == "16" and host.reports[0].dice == [{"sides": 20, "value": 17}]).override_failure_message("Interpretation retains raw 17 and applies Strength -1.").is_true()
	await action.refresh()
	await action.cancel()
	assert_bool(host.reports.size() == 1).override_failure_message("Refresh and closure after completion do not duplicate or undo.").is_true()
	var cancelled = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await cancelled.start("Strength")
	var cancelled_id: String = cancelled.request_id
	await cancelled.cancel()
	host.human_results[cancelled_id] = {"status": "rolled", "sequence": 43, "terms": [{"name": "Strength", "faces": 20, "results": [20]}]}
	await cancelled.refresh()
	assert_bool(host.reports.size() == 2 and host.reports[1].result == "ENDED").override_failure_message("Cancellation rejects late interpreted consequences.").is_true()
	var disconnected = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await disconnected.start("Strength")
	host.human_results[disconnected.request_id].status = "cancelled"
	await disconnected.refresh()
	assert_bool(not disconnected.pending and host.reports[2].result == "ENDED").override_failure_message("A required disconnect ends the System action.").is_true()
	host.actors[0].access_level = "Viewer"
	var viewer = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await viewer.start("Strength")
	assert_bool(not viewer.pending and viewer.failed and host.human_requests.size() == 3).override_failure_message("Viewer cannot originate a modifier Throw.").is_true()
	host.actors[0].access_level = "Owner"
	host.game_master = true
	host.access_entries.append({"participant_id": "owner", "display_name": "Player", "access_level": "Owner", "is_connected": true})
	var gm = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await gm.start("Strength")
	assert_bool(host.human_requests[3].participant == "owner").override_failure_message("GM initiation routes to the Character's Player.").is_true()
	await gm.cancel()
	host.access_entries[0].is_connected = false
	var offline = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await offline.start("Strength")
	assert_bool(offline.failed and host.human_requests.size() == 4).override_failure_message("Offline owner is not replaced by the GM.").is_true()
	host.game_master = false
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	var sdk := SDK.new(host)
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(sdk.actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, sdk)
	await get_tree().process_frame
	await get_tree().process_frame
	var button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(host.human_requests.size() == 5).override_failure_message("The authored modifier directly originates its human Throw.").is_true()
	button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	assert_bool(button.disabled and button.icon != null).override_failure_message("Pending modifier is explicit and prevents duplicate actions.").is_true()
	host.actors[0].data["silver"] = 23
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	button = sheet.find_child("Strength", true, false).get_node("Padding/Content/Row/Modifier")
	assert_bool(button.disabled and button.icon != null).override_failure_message("Actor changes retain the pending modifier state.").is_true()
	sheet.close_action()
	await get_tree().process_frame
	assert_bool(host.human_results[host.human_requests[4].id].status == "cancelled").override_failure_message("Sheet closure ends its pending request.").is_true()
	sheet._roll_ability("Strength")
	await get_tree().process_frame
	host.defer_human = true
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var queued_id: String = host.human_requests[-1].id
	host.human_results[queued_id] = {"status": "rolled", "sequence": 49, "terms": [{"name": "Strength", "faces": 20, "results": [19]}]}
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	host.complete_human()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(host.reports[-1].result == "18").override_failure_message("A final update during an older pending reply is not lost.").is_true()
	sheet.free()
	host.defer_human = true
	var delayed = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	delayed.start("Strength")
	await delayed.cancel()
	var report_count: int = host.reports.size()
	host.complete_human()
	await get_tree().process_frame
	assert_bool(not delayed.pending and host.human_results[delayed.request_id].status == "cancelled" and host.reports.size() == report_count).override_failure_message("Closing before request acknowledgement cancels the accepted request without a late result.").is_true()
	var accepted = ACTION.new(SDK.new(host), SDK.ActorId.new("character"))
	await accepted.start("Strength")
	host.human_results[accepted.request_id] = {"status": "rolled", "sequence": 50, "terms": [{"name": "Strength", "faces": 20, "results": [20]}]}
	await accepted.cancel()
	await accepted.refresh()
	assert_bool(host.human_results[accepted.request_id].status == "rolled" and host.reports[-1].result == "ENDED").override_failure_message("Closure after raw acceptance preserves the Roll and rejects later interpretation.").is_true()

func after_test() -> void:
	await get_tree().process_frame
