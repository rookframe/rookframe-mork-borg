extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/presentation.gd"


const WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
const DESKTOP_WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button_desktop.tres")

const ENCOUNTER_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_button.tres")
const ENCOUNTER_STRIP = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_strip.tscn")

const ENCOUNTER_ROOK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_rook.tscn")

func compose() -> void:
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_check_defences)
	add_child(timer)
	var rail: SDK.Rail = sdk.rails.left
	var creation := SDK.Contribution.new()
	creation.scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/actor_creation.tscn")
	sdk.slots.actor_creation.push(creation)
	var hud := SDK.Contribution.new()
	hud.scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_hud.tscn")
	sdk.character_hud.mount(hud)
	if sdk.context().is_gm:
		var combat_button := SDK.WindowButton.new()
		combat_button.button_scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_button_ru.tscn") if sdk.translations.text("en") == "ru" else ENCOUNTER_BUTTON.button_scene
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
	var name: String = data.get("name", sdk.translations.text("Unnamed Actor"))
	var model: Dictionary = CREATURES.new().effective_miniature(data)
	return SDK.ActorSummary.new(name, null, SDK.ContentReference.new(str(model.package_id), str(model.local_id)), true)


func inspect_actor(actor: SDK.ActorId) -> void:
	var source := sdk.actors.read(actor)
	var data: Dictionary = source.actor.data if source.ok and typeof(source.actor.data) == TYPE_DICTIONARY else {}
	if str(data.get("schema", "")) == "mork-borg-character/v1":
		sdk.windows.open_actor(preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_surface.tres"), actor)
		return
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
			# The existing defence view consumes this inbox in Window.opened.
			# Ordinary inspection continues to open the completed full sheet.
			var entry: SDK.WindowButton = DESKTOP_WINDOW_BUTTON if sdk.presentation_experience().is_desktop else WINDOW_BUTTON
			sdk.windows.open_actor(entry.window, SDK.ActorId.new(str(outcome.target)))
			return

const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const LIBRARY = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_library.gd")

func describe_actor_definition(definition: SDK.ContentEntry) -> SDK.ActorDefinitionView:
	if definition.reference.package_id != sdk.package_id() or not CREATURES.CORE_DEFINITIONS.has(definition.reference.local_id):
		return SDK.ActorDefinitionView.new()
	var surface := SDK.ExtensionSurface.new()
	surface.scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_definition_sheet.tscn")
	surface.initial_placement = "full-viewport"
	return SDK.ActorDefinitionView.new(sdk.translations.text("Creatures"), surface, sdk.context().is_gm)

func create_actor_from_definition(definition: SDK.ContentEntry, scene: SDK.SceneId = null, position: Vector2 = Vector2(0, 0)) -> void:
	await LIBRARY.new(sdk).create(definition.reference, scene, position)


func place_actor(actor: SDK.ActorId, scene: SDK.SceneId, position: Vector2) -> void:
	var result := await preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/miniature_actions.gd").new(sdk).place_at(actor, scene, position)
	if not result.ok:
		var feedback := SDK.FeedbackMessage.new()
		feedback.title = sdk.translations.text("Placement failed")
		feedback.message = sdk.translations.text(result.message)
		sdk.feedback.error(feedback)
