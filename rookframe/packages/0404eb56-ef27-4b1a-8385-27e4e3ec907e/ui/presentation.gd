extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/presentation.gd"

const WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
const DESKTOP_WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button_desktop.tres")

const ENCOUNTER_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_button.tres")
const ENCOUNTER_STRIP = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_strip.tscn")

const ENCOUNTER_LOCAL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_local.tres")
const ENCOUNTER_ROOK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_rook.tscn")

func compose() -> void:
	ENCOUNTER_LOCAL.activate(sdk.context().session_id)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_check_defences)
	add_child(timer)
	var experience: SDK.DeviceExperience = sdk.presentation_experience()
	var rail: SDK.Rail = sdk.rails.left
	rail.push(DESKTOP_WINDOW_BUTTON if experience.is_desktop else WINDOW_BUTTON)
	if sdk.context().is_gm:
		var combat_button := SDK.WindowButton.new()
		combat_button.button_scene = ENCOUNTER_BUTTON.button_scene
		combat_button.window = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_view.gd").new().surface(sdk)
		rail.push(combat_button)
		var contextual := SDK.Contribution.new()
		contextual.scene = ENCOUNTER_ROOK
		sdk.slots.selected_rook.push(contextual)
	var order := SDK.Contribution.new()
	order.scene = ENCOUNTER_STRIP
	sdk.ui_root.push(order)


func describe_actor(actor: SDK.Actor) -> SDK.ActorSummary:
	var data: Dictionary = actor.data
	var name: String = data.get("name", "Unnamed Actor")
	return SDK.ActorSummary.new(name)


func inspect_actor(actor: SDK.ActorId) -> void:
	var entry: SDK.WindowButton = DESKTOP_WINDOW_BUTTON if sdk.presentation_experience().is_desktop else WINDOW_BUTTON
	sdk.windows.open_actor(entry.window, actor)

var _reading_defences := false
var _seen_defences: Dictionary = {}

func _check_defences() -> void:
	if _reading_defences:
		return
	_reading_defences = true
	var result: SDK.DataResult = await sdk.system_actions.submit("defence.inbox", {})
	_reading_defences = false
	if not result.ok or typeof(result.value) != TYPE_ARRAY:
		return
	var inbox: Array = result.value
	for raw in inbox:
		var outcome: Dictionary = raw
		var id := str(outcome.id)
		if not _seen_defences.has(id) and str(outcome.state) in ["ready", "shield"]:
			_seen_defences[id] = true
			if str(outcome.initiator) == sdk.context().participant_id:
				continue
			inspect_actor(SDK.ActorId.new(str(outcome.target)))
			return
