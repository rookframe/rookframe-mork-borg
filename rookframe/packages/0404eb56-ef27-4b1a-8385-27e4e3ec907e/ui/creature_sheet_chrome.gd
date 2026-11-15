extends Control
## Creature sheet chrome: chapter tabs, the published source action and the
## chapter frame, all in the World theme's look.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const CHROME = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_icon_actions.gd")
const TYPE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_type.gd")
const TOKENS := &"RookframeTokens"
var _chrome := CHROME.new()
var _locale: I18N = I18N.new()
var _phone := false
var _tablet := false
const NAV := "Inset/Layout/Body/Workspace/Tabs/"
const SOURCE := "Inset/Layout/Footer/SourceNote/Source"

func _layout_chapters() -> void:
	get_node("Inset/Layout/Body/Workspace/Tabs").set(&"gap", &"space_1" if _phone else &"space_2")
	for title in ["Encounter", "Inventory", "Appearance"]:
		var button: Button = get_node(NAV + title)
		button.text = _locale.text("Creature chapter: Encounter" if title == "Encounter" else title)
		button.accessibility_name = button.text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = false
	var source: Button = get_node(SOURCE)
	source.text = _locale.text("Published source")
	source.compact = true
	_chrome.icon_action(source, "info")

func _set_chapter_frame(clear: bool) -> void:
	var panel: PanelContainer = get_node("Inset/Layout/Body/Workspace/Chapter")
	panel.set(&"padding_horizontal", &"" if clear else &"space_1")
