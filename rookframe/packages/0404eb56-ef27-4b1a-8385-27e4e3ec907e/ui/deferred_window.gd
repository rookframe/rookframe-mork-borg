extends "res://rookframe/sdk/window.gd"
## The SDK owns this managed window's identity. Its complete authored view
## joins it on first opening and remains available for normal close/reopen.

enum View { LIBRARY, CREATURE_DEFINITION, ENCOUNTER }
@export var window := View.LIBRARY

const WindowView = preload("res://rookframe/sdk/window.gd")
var _scene: PackedScene
var _view: WindowView

func ready() -> void:
	if sdk == null:
		return
	var scene: PackedScene
	if window == View.LIBRARY:
		scene = load("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window.tscn")
	elif window == View.CREATURE_DEFINITION:
		scene = load("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_definition_sheet.tscn")
	else:
		scene = load("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_window.tscn")
	_scene = scene
	var view = scene.instantiate()
	view.sdk = sdk
	add_child(view)
	_view = view
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closed.connect(_close_view)

func _close_view() -> void:
	_view.closed.emit()

func opened_definition(definition: SDK.ContentReference) -> void:
	_view.opened_definition(definition)
