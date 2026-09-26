extends RefCounted
## Package-local SDK translation capability. Saved data is never translated.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
var _translations: SDK.Translations

func bind(sdk: SDK) -> void:
	if sdk != null:
		_translations = sdk.translations

func text(source: String) -> String:
	return _translations.text(source) if _translations != null and not source.is_empty() else source

func companion_row(view: Control) -> void:
	(view.get_node(^"Actions/Open") as Button).text = text("Open sheet")
	(view.get_node(^"Actions/Place") as Button).text = text("Place Rook")

func encounter_entry(_view: Control) -> void:
	pass

func encounter_group(view: Control) -> void:
	(view.get_node(^"ActiveSide") as Label).text = text("Players")
	(view.get_node(^"Side") as Label).text = text("Players")

func miniature_choice(_view: Control) -> void:
	pass

func power_row(view: Control) -> void:
	(view.get_node(^"Cast") as Button).text = text("Cast")
