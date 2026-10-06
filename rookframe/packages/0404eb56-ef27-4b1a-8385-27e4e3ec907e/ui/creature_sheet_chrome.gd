extends Control
## Authored sheet chrome and responsive tab presentation.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const CHROME = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_icon_actions.gd")
var _chrome := CHROME.new()
var _locale: I18N = I18N.new()
var _phone := false
var _tablet := false
@export var chapter_frame: StyleBoxFlat = StyleBoxFlat.new()
@export var chapter_normal: StyleBoxFlat = StyleBoxFlat.new()
@export var chapter_selected: StyleBoxFlat = StyleBoxFlat.new()
@export var source_frame: StyleBoxFlat = StyleBoxFlat.new()
const NAV := "Inset/Layout/Body/Workspace/Tabs/"
const SOURCE := "Inset/Layout/Footer/SourceNote/Source"

func _style_chapter(button: Button, section: bool = false) -> void:
	button.clip_text = false
	var normal: StyleBoxFlat = chapter_normal.duplicate()
	var selected: StyleBoxFlat = chapter_selected.duplicate()
	for style in [normal, selected]:
		style.set_border_width_all(1)
		style.border_width_bottom = 0
		style.content_margin_left = 12 if section else 8 if _phone or _tablet else 12
		style.content_margin_right = style.content_margin_left
		style.content_margin_top = 5 if _tablet else 8
		style.content_margin_bottom = style.content_margin_top
	if section:
		normal.bg_color = Color(0,0,0,0)
		normal.set_border_width_all(0)
		normal.border_width_bottom = 0
		selected.bg_color = Color(0.203922,0.239216,0.254902,1)
		selected.set_border_width_all(0)
		selected.border_width_bottom = 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", selected)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.203922,0.239216,0.254902,1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("hover_pressed", selected)
	for item in ["font_pressed_color", "font_hover_pressed_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		button.add_theme_color_override(item, Color(0.905882,0.905882,0.866667,1) if section else Color(0.082353,0.090196,0.098039,1))
	button.add_theme_color_override("font_color", Color(0.905882,0.905882,0.866667,1) if section else Color(0.682353,0.729412,0.745098,1))
	button.add_theme_color_override("icon_normal_color", Color(0.815686,0.745098,0.556863,1))

func _layout_chapters() -> void:
	get_node("Inset/Layout/Body/Workspace/Tabs").add_theme_constant_override("separation", 4 if _phone else 6 if _tablet else 8)
	for title in ["Encounter", "Inventory", "Appearance"]:
		var button: Button = get_node(NAV + title)
		button.text = _locale.text("Creature chapter: Encounter" if title == "Encounter" else title)
		button.custom_minimum_size = Vector2(44, 44 if _phone else 48 if _tablet else 54)
		button.size_flags_horizontal = 3
		button.add_theme_font_size_override("font_size", 18 if _phone else 19 if _tablet else 23)
		button.add_theme_constant_override("h_separation", 12)
		button.add_theme_constant_override("icon_max_width", 20 if _phone else 22 if _tablet else 26)
		button.alignment = 1
		button.icon_alignment = 0
		button.expand_icon = false
		button.icon = preload("res://rookframe/ui/icons/character/sword.svg") if title == "Encounter" else preload("res://rookframe/ui/icons/character/bag.svg") if title == "Inventory" else preload("res://rookframe/ui/icons/character/character.svg")
		var row: HBoxContainer = button.get_node("Center/Row")
		var label: Label = row.get_node("Title")
		label.text = button.text
		button.accessibility_name = button.text
		button.text = ""
		label.add_theme_font_size_override("font_size", 18 if _phone else 19 if _tablet else 23)
		label.theme_type_variation = "SilkCreatureTab" + ("Phone" if _phone else "Tablet" if _tablet else "Desktop")
		(row.get_node("Icon") as TextureRect).texture = preload("res://rookframe/ui/icons/character/sword.svg") if title == "Encounter" else preload("res://rookframe/ui/icons/character/bag.svg") if title == "Inventory" else preload("res://rookframe/ui/icons/character/character.svg")
		var extent := 20 if _phone else 22 if _tablet else 26
		(row.get_node("Icon") as TextureRect).custom_minimum_size = Vector2(extent,extent)
		button.icon = null
		_style_chapter(button)
	var source: Button = get_node(SOURCE)
	source.text = _locale.text("Published source")
	_chrome.icon_action(source, "info")
	source.add_theme_constant_override("icon_max_width", 16)

	get_node(SOURCE).add_theme_stylebox_override("normal", source_frame)

func _set_chapter_frame(clear: bool) -> void:
	var panel: PanelContainer = get_node("Inset/Layout/Body/Workspace/Chapter")
	var frame: StyleBoxFlat = chapter_frame.duplicate()
	frame.content_margin_left = 11 if _phone else 13 if _tablet else 25
	frame.content_margin_right = frame.content_margin_left
	frame.content_margin_top = 7 if _phone else 13 if _tablet else 21
	frame.content_margin_bottom = frame.content_margin_top
	if clear:
		frame.bg_color = Color(0,0,0,0)
		frame.set_border_width_all(0)
		frame.content_margin_left = 0
		frame.content_margin_right = 0
		frame.content_margin_top = 0
		frame.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", frame)

