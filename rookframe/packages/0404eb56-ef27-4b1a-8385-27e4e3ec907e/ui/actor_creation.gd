extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

func ready() -> void:
	if sdk == null:
		return
	get_node("Create").text = sdk.translations.text("Create Character")
	get_node("Create").pressed.connect(_create)

func _create() -> void:
	var surface := SDK.ExtensionSurface.new()
	surface.scene = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_window.tscn")
	sdk.windows.open(surface)
