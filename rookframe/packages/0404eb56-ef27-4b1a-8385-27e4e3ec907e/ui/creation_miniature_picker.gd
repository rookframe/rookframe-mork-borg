extends MarginContainer

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")

signal closed
signal selected(reference: Dictionary)
var sdk: SDK

func _ready() -> void:
	get_node(^"Picker").chosen.connect(_choose)
	get_node(^"Picker").closed.connect(_cancel)

func open(facade: SDK, locale: I18N, saved: Dictionary) -> void:
	sdk = facade
	get_node(^"Picker").open_choice(sdk, locale, saved)

func _choose(reference: Dictionary) -> void:
	selected.emit(reference)
	sdk.windows.pop(self)

func _cancel(_saved: bool) -> void:
	sdk.windows.pop(self)
