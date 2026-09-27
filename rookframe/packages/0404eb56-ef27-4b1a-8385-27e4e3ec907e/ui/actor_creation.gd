extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

func ready() -> void:
	if sdk == null:
		return
	get_node("Create").text = sdk.translations.text("Create Character")
	get_node("Create").pressed.connect(_create)

func _create() -> void:
	var entry: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button_desktop.tres") if sdk.presentation_experience().is_desktop else preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
	var surface := SDK.ExtensionSurface.new()
	surface.initial_placement = entry.window.initial_placement
	surface.initial_floating_rect = entry.window.initial_floating_rect
	surface.initial_dock_width = entry.window.initial_dock_width
	surface.scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_window.tscn")
	sdk.windows.open(surface)
