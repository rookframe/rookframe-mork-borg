extends RefCounted

## One live modifier action. No draft or reconnect state is retained by the System.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ENDED_MESSAGE := "Action ended. Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing."
signal changed
var pending := false
var request_id := ""
var ability := ""
var message := ""
var failed := false
var _sdk: SDK
var _actor: SDK.ActorId
var _request: SDK.HumanThrowRequest
var _modifier := 0
var _name := ""
var _ended := false
var _reading := false
var _refresh_requested := false
var _submitted := false

func _init(facade: SDK, actor: SDK.ActorId) -> void:
	_sdk = facade
	_actor = actor

func start(selected_ability: String) -> void:
	if pending or _ended:
		return
	var source: SDK.ActorResult = _sdk.actors.read(_actor)
	if not source.ok or source.actor == null or source.actor.access_level != "Owner":
		_finish("Owner access is required to roll this Character.", true)
		return
	var data: Dictionary = source.actor.data
	if str(data.get("schema", "")) != "mork-borg-character/v1" or not selected_ability in ["Agility", "Presence", "Strength", "Toughness"]:
		_finish("Choose a Character modifier.", true)
		return
	var context: SDK.WorldContext = _sdk.context()
	if not context.ok:
		_finish(context.message, true)
		return
	var participant := context.participant_id
	if context.is_gm:
		var access: SDK.ActorAccessListResult = _sdk.actors.access(_actor)
		if not access.ok:
			_finish(access.message, true)
			return
		var owners: Array[SDK.ActorAccessEntry] = []
		for entry in access.items:
			if entry.access_level == "Owner":
				owners.append(entry)
		if owners.size() > 1:
			_finish("Several Players own this Character. The responsible Player can roll from their sheet.", true)
			return
		if owners.size() == 1:
			if not owners[0].is_connected:
				_finish("This Character’s Player is not connected.", true)
				return
			participant = owners[0].participant_id
	ability = selected_ability
	var abilities: Dictionary = data.get("abilities", {})
	var value: Dictionary = abilities.get(ability, {})
	_modifier = int(value.get("modifier", 0))
	_name = str(data.get("name", "Character"))
	request_id = _sdk.dice.new_request_id()
	_request = SDK.HumanThrowRequest.new(request_id, participant, [SDK.DiceTerm.new(ability, 20)])
	pending = true
	message = "Waiting for %s Throw in the Dice Tray." % ability
	changed.emit()
	_reading = true
	var result: SDK.HumanThrowResult = await _sdk.dice.request_session_throw(_request)
	_reading = false
	_submitted = result.ok
	if _ended:
		if result.ok:
			await _sdk.dice.cancel_throw(request_id)
		return
	await _accept(result)
	if _refresh_requested:
		await refresh()

func refresh() -> void:
	if not pending or _ended or _request == null:
		return
	_refresh_requested = true
	if _reading:
		return
	while _refresh_requested and pending and not _ended:
		_refresh_requested = false
		var source: SDK.ActorResult = _sdk.actors.read(_actor)
		if not source.ok or source.actor == null or source.actor.access_level != "Owner":
			await cancel()
			return
		_reading = true
		var result: SDK.HumanThrowResult = await _sdk.dice.request_session_throw(_request)
		_reading = false
		if not _ended:
			await _accept(result)

func cancel() -> void:
	if not pending or _ended:
		return
	_finish(ENDED_MESSAGE, false)
	if _submitted:
		await _sdk.dice.cancel_throw(request_id)
	await _report_ended()

func _accept(result: SDK.HumanThrowResult) -> void:
	if not result.ok:
		_finish(result.message, true)
		return
	if result.status == "pending":
		return
	if result.status == "cancelled":
		_finish(ENDED_MESSAGE, false)
		await _report_ended()
		return
	if result.status != "rolled" or result.terms.size() != 1 or result.terms[0].results.size() != 1:
		_finish("The requested Roll is incomplete. Resolve the result at the table.", true)
		return
	var raw: int = result.terms[0].results[0]
	var total := raw + _modifier
	# The direct modifier interaction supplies no DR. Do not invent success/failure.
	var report := SDK.ActionLogMessage.new("%s · %s" % [_name, ability])
	report.text = [SDK.ActionLogText.new("d20 %d %+d = %d. Compare with the agreed DR. Raw Roll #%d." % [raw, _modifier, total, result.sequence])]
	report.dice = [SDK.ActionLogDie.new(20, raw)]
	report.result = str(total)
	_finish("%s: %d. Compare with the agreed DR." % [ability, total], false)
	var published: SDK.ActionLogResult = await _sdk.action_log.publish(report)
	if not published.ok:
		message = "The raw Roll remains. The interpreted report could not be published: " + published.message
		failed = true
		changed.emit()

func _finish(text: String, error: bool) -> void:
	pending = false
	_ended = true
	message = text
	failed = error
	changed.emit()

func _report_ended() -> void:
	var report := SDK.ActionLogMessage.new("%s · %s ended" % [_name, ability])
	report.text = [SDK.ActionLogText.new("Completed rolls and changes remain. Resolve unfinished results with ordinary dice and sheet editing.")]
	report.result = "ENDED"
	report.tone = "attention"
	await _sdk.action_log.publish(report)
