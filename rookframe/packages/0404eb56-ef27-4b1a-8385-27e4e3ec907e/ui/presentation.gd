extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/presentation.gd"

const WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
const DESKTOP_WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button_desktop.tres")

func compose() -> void:
	var experience: SDK.DeviceExperience = sdk.presentation_experience()
	var rail: SDK.Rail = sdk.rails.left
	rail.push(DESKTOP_WINDOW_BUTTON if experience.is_desktop else WINDOW_BUTTON)


func describe_actor(actor: SDK.Actor) -> SDK.ActorSummary:
	var data: Dictionary = actor.data
	var name: String = data.get("name", "Unnamed Actor")
	return SDK.ActorSummary.new(name)


func inspect_actor(actor: SDK.ActorId) -> void:
	var entry: SDK.WindowButton = DESKTOP_WINDOW_BUTTON if sdk.presentation_experience().is_desktop else WINDOW_BUTTON
	sdk.windows.open_actor(entry.window, actor)
