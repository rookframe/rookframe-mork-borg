extends Node

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ABILITY = preload(ROOT + "logic/ability_throw.gd")
const RESPONSIBILITY = preload(ROOT + "logic/ability_throw_responsibility.gd")
const CONDITION = preload(ROOT + "logic/broken_incident.gd")
signal changed
var _sdk: SDK
var _ability: ABILITY
var pending: bool:
	get:
		return _ability != null and _ability.pending

func bind(facade: SDK) -> void:
	_sdk = facade
	_sdk.world_changed.connect(_refresh)

func can_roll(actor: SDK.Actor) -> bool:
	if actor == null or actor.access_level != "Owner" or pending or not CONDITION.new().can_act(actor.data):
		return false
	return RESPONSIBILITY.new().resolve(_sdk, actor.id).get("ok", false)

func roll_ability(actor: SDK.ActorId, ability: String) -> void:
	if pending or _sdk == null:
		return
	var source := _sdk.actors.read(actor)
	if not source.ok or not can_roll(source.actor):
		return
	# The action captures its own Actor. A later HUD selection only changes the view.
	_ability = ABILITY.new(_sdk, actor)
	_ability.changed.connect(_changed)
	await _ability.start(ability)

func _refresh() -> void:
	if pending:
		await _ability.refresh()

func _changed() -> void:
	changed.emit()
	if _ability.failed:
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = _sdk.translations.text("Ability roll")
		feedback.message = _sdk.translations.text(_ability.message)
		_sdk.feedback.error(feedback)

func _exit_tree() -> void:
	if pending:
		_ability.cancel()
