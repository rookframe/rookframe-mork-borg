extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

## Silkbound Ledger typography, surfaces and measured Creature HUD rows.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HUD_ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW_SCRIPT = preload(ROOT + "ui/hud_row.gd")
const LINE_HEIGHT = preload("res://rookframe/ui/theme/silkbound_line_height.gd")
const REGULAR = preload("res://rookframe/ui/theme/silkbound_regular.tres")
const MEDIUM = preload("res://rookframe/ui/theme/silkbound_medium.tres")
const PLAIN = preload("res://rookframe/ui/theme/silkbound_plain.tres")
const CONTENT := Color(0.905882353, 0.905882353, 0.866666667, 1.0)
const MUTED := Color(0.682352941, 0.729411765, 0.745098039, 1.0)
const PICTOGRAM := Color(0.815686275, 0.745098039, 0.556862745, 1.0)
const NEUTRAL := Color(0.807843137, 0.8, 0.701960784, 1.0)
const INK := Color(0.082352941, 0.090196078, 0.098039216, 1.0)
const PANEL := Color(0.137254902, 0.156862745, 0.168627451, 1.0)
const RAISED := Color(0.203921569, 0.239215686, 0.254901961, 1.0)
const RULE := Color(0.244353, 0.262784, 0.272745, 1)
const EDGE := Color(0.358353, 0.384235, 0.395686, 1)
var _category := ""
var _phone := false
var _tablet := false
var _rows: Array[ROW_SCRIPT] = []
var _panel_anchor: Button
@onready var _bar: Control = get_node("Bar")
@onready var _panel: Control = get_node("Panel")
@onready var _list: GridContainer = get_node("Panel/List")
@onready var _more: GridContainer = get_node("Panel/More")

func _rect(control: Control, x: float, y: float, w: float, h: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(0, w), maxf(0, h))

func _type(control: Control, pixels: int, line_height: float, medium := false) -> void:
	control.add_theme_font_override("font", MEDIUM if medium else REGULAR)
	control.add_theme_font_size_override("font_size", pixels)
	LINE_HEIGHT.apply(control, line_height)

func _button_style(button: Button, category := false, inset := 0) -> void:
	var normal := PLAIN.duplicate() as StyleBoxFlat
	# Godot Side order: left, top, right, bottom.
	for side in range(4):
		normal.set_content_margin(side, inset if side % 2 == 0 else 0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = PANEL
	for side in range(4):
		hover.set_content_margin(side, inset if side % 2 == 0 else 0)
	if category:
		hover.border_color = EDGE
		hover.set_border_width_all(1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = NEUTRAL if category else RAISED
	if button.toggle_mode and not category:
		pressed.bg_color = Color(0, 0, 0, 0)
	pressed.border_color = NEUTRAL if category else RULE
	button.add_theme_stylebox_override("pressed", pressed)
	var hover_pressed := pressed.duplicate() as StyleBoxFlat
	if category:
		hover_pressed.bg_color = CONTENT
	elif button.toggle_mode:
		hover_pressed.bg_color = PANEL
	button.add_theme_stylebox_override("hover_pressed", hover_pressed)
	button.add_theme_color_override("font_disabled_color", MUTED)

func _layout_category(button: Button, width: float, height: float, more_menu := false) -> void:
	var icon_control: TextureRect = button.get_node("Icon")
	var title_control: Label = button.get_node("Title")
	var icon := 24 if more_menu else 23 if _phone else 25 if _tablet else 29
	var gap := 6 if more_menu else 2 if _phone else 5 if _tablet else 8
	var font_size := 17 if more_menu else 16 if _phone else 15 if _tablet else 19
	var line_height := 1.1 if _phone and not more_menu else 1.25
	var label_height := font_size*line_height
	var top: float = (height-icon-gap-label_height)/2.0
	_rect(icon_control, (width-icon)/2.0, top, icon, icon)
	_rect(title_control, 0, top+icon+gap, width, label_height)
	_type(title_control, font_size, line_height)
	if button.name == "More":
		icon_control.visible = false
		var glyph: Label = button.get_node("Glyph")
		_type(glyph, 22, 14.0/22.0)
		_rect(glyph, 0, top, width, icon)

func _render_entry(row: ROW_SCRIPT, entry: HUD_ENTRY, fixed: bool, favorite_pending := false) -> void:
	var ability_grid := _phone and _category == "Abilities"
	var height := 50 if ability_grid else 58 if _phone else 64 if _tablet else 76
	row.custom_minimum_size = Vector2(0, height)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var launch: Button = row.get_node("Launch")
	launch.disabled = not entry.available
	launch.accessibility_name = entry.title
	_button_style(launch)
	var content: HBoxContainer = launch.get_node("Content")
	content.add_theme_constant_override("separation", 8 if ability_grid else 10 if _phone else 12 if _tablet else 16)
	content.offset_left = 8 if _phone else 10 if _tablet else 12
	content.offset_right = -content.offset_left
	content.offset_top = 6 if _phone else 8 if _tablet else 10
	content.offset_bottom = -content.offset_top
	var icon: TextureRect = content.get_node("Icon")
	icon.texture = entry.icon
	var icon_size := 20 if ability_grid else 24 if _phone else 26 if _tablet else 30
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.modulate = PICTOGRAM if entry.available else MUTED
	var copy: VBoxContainer = content.get_node("Copy")
	copy.add_theme_constant_override("separation", 2 if _phone else 4)
	var title: Label = copy.get_node("Title")
	title.text = entry.title
	_type(title, 18 if _phone else 20 if _tablet else 22, 1.25 if _phone else 1.35)
	var detail: Label = copy.get_node("Detail")
	detail.text = entry.detail
	detail.visible = not entry.detail.is_empty()
	_type(detail, 14 if _phone else 15 if _tablet else 17, 1.2)
	detail.add_theme_color_override("font_color", MUTED)
	title.max_lines_visible = 2
	row.get_node("FullName").visible = false
	var value: Label = content.get_node("Value")
	value.text = entry.value
	value.visible = not entry.value.is_empty() and not entry.value_is_action
	_type(value, 18 if _phone else 17 if _tablet else 21, 1.25)
	value.add_theme_color_override("font_color", CONTENT if entry.available else MUTED)
	value.custom_minimum_size = Vector2(0, 0)
	value.custom_minimum_size = Vector2(value.get_minimum_size().x+8, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", CONTENT if entry.available else MUTED)
	var use: Button = row.get_node("Use")
	use.visible = entry.value_is_action
	use.text = entry.value
	use.disabled = not entry.available
	use.accessibility_name = entry.value + " " + entry.title
	_button_style(use, false, 8 if _phone else 12)
	_type(use, 18 if _phone else 17 if _tablet else 21, 1.25)
	var star: Button = row.get_node("Favorite")
	star.visible = not fixed
	star.disabled = favorite_pending
	star.set_pressed_no_signal(bool(entry.favorite))
	star.text = "★" if entry.favorite else "☆"
	_button_style(star)
	_type(star, 22, 1.25)
	star.accessibility_name = sdk.translations.text("Remove %s from favorites" if entry.favorite else "Add %s to favorites") % entry.title
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		star.add_theme_color_override(state, NEUTRAL if entry.favorite else MUTED)
	var full_name: Button = row.get_node("FullName")
	full_name.accessibility_name = sdk.translations.text("Show full name")
	_button_style(full_name)
	_type(full_name, 18, 1.25)


## The approved fixed HUD composition, with independent HP and four categories.
const CREATURE_CATEGORIES := ["Attacks", "Special", "Checks", "Scene"]

func _layout() -> void:
	if not is_node_ready():
		return
	var inset := 56 if _phone else 48 if _tablet else 256
	var height := 68 if _phone else 88 if _tablet else 120
	var bottom := 29 if _phone else 24
	_rect(_bar, inset, size.y-bottom-height, size.x-inset*2, height)
	var dice := 60 if _phone else 70 if _tablet else 112
	var gap := 12 if _phone or _tablet else 20
	var identity_width := 184 if _phone else 228 if _tablet else 356
	var hp_width := 100 if _phone else 112 if _tablet else 140
	var inner_height := height-12
	_rect(get_node("Bar/Dice"), 0, 6, dice, inner_height)
	var emblem := 34 if _phone else 38 if _tablet else 56
	_rect(get_node("Bar/Dice/Emblem"), (dice-emblem)/2.0, (inner_height-emblem)/2.0, emblem, emblem)
	var identity: Control = get_node("Bar/Identity")
	_rect(identity, dice, 6, identity_width, inner_height)
	var portrait := Vector2(38, 48) if _phone else Vector2(50, 64) if _tablet else Vector2(76, 88)
	_rect(identity.get_node("PortraitFrame"), gap, (inner_height-portrait.y)/2.0, portrait.x, portrait.y)
	_layout_portrait()
	var text_x: float = gap+portrait.x+(10 if _phone else 12 if _tablet else 18)
	var width: float = identity_width-text_x-(12 if _phone or _tablet else 24)
	var name_size := 20 if _phone else 22 if _tablet else 28
	var meta_size := 14 if _tablet else 18
	var name_height: float = name_size*1.1*(2 if _phone or _tablet else 1)
	var meta_height: float = 0 if _phone else meta_size*1.4+2
	var y: float = (inner_height-name_height-meta_height)/2.0
	_rect(identity.get_node("Name"), text_x, y, width, name_height)
	_type(identity.get_node("Name"), name_size, 1.1, true)
	var title: Label = identity.get_node("Name")
	title.autowrap_mode = 3 if _phone or _tablet else 0
	title.max_lines_visible = 2 if _phone or _tablet else 1
	var meta: Label = get_node("Bar/Identity/Class")
	meta.visible = not _phone
	_rect(identity.get_node("Class"), text_x, y+name_height+2, width, meta_height)
	_type(identity.get_node("Class"), meta_size, 1.4)
	_rect(identity.get_node("Divider"), identity_width-1, 0, 1, inner_height)
	var hp: Control = get_node("Bar/Health")
	_rect(hp, dice+identity_width, 6, hp_width, inner_height)
	_rect(hp.get_node("Divider"), hp_width-1, 0, 1, inner_height)
	var hp_size := 18 if _phone else 20 if _tablet else 24
	var hp_pad := 10 if _phone else 12
	_rect(hp.get_node("Value"), hp_pad, inner_height/2.0-hp_size*0.8, hp_width-hp_pad*2, hp_size*1.1)
	_type(hp.get_node("Value"), hp_size, 1.1, true)
	_rect(hp.get_node("Track"), hp_pad, inner_height/2.0+hp_size*0.3+6, hp_width-hp_pad*2, 3)
	var categories: Control = get_node("Bar/Categories")
	var left: float = dice+identity_width+hp_width+gap
	var top := 9 if _phone else 11 if _tablet else 19
	_rect(categories, left, top, _bar.size.x-left-(12 if _phone or _tablet else 16), height-top*2)
	var category_gap := 4 if _phone or _tablet else 8
	var button_width: float = (categories.size.x-category_gap*3)/4
	for index in range(4):
		var button: Button = categories.get_node(CREATURE_CATEGORIES[index])
		_rect(button, index*(button_width+category_gap), 0, button_width, categories.size.y)
		_layout_category(button, button_width, categories.size.y)
	_layout_panel()

func _layout_portrait() -> void:
	var frame: Control = get_node("Bar/Identity/PortraitFrame")
	_rect(frame.get_node("Portrait"), 0, 0, frame.size.x, frame.size.y)

func _layout_panel() -> void:
	if not _panel.visible or _panel_anchor == null:
		return
	var width: float = minf(380 if _phone else 430 if _tablet else 510, _bar.size.x)
	var pad := 12 if _phone else 16 if _tablet else 20
	var header := 44 if _phone else 52 if _tablet else 64
	var inner: float = width-pad*2-2
	var search := 52 if get_node("Panel/Search").visible else 0
	var footer := 44 if get_node("Panel/Footer").visible else 0
	var body: float = _list.get_combined_minimum_size().y if _list.visible else 52 if _phone else 64
	if get_node("Panel/Health").visible:
		body = 138 if _phone else 166
		if get_node("Panel/Health/Error").visible:
			body += 38
	var height: float = header+search+body+footer+(6 if _phone else 10)
	var anchor: float = _panel_anchor.get_global_rect().position.x-_bar.get_global_rect().position.x+_panel_anchor.size.x/2
	var left: float = clampf(anchor-width/2, 0, _bar.size.x-width)
	_rect(_panel, _bar.position.x+left, _bar.position.y-height-(12 if _phone or _tablet else 14), width, height)
	_rect(get_node("Panel/Header"), pad+1, 1, inner, header)
	var all: CheckBox = get_node("Panel/Header/ShowAll")
	var all_width: float = all.get_minimum_size().x if all.visible else 0
	var current: Label = get_node("Panel/Header/CurrentHP")
	_type(current, 17 if _phone or _tablet else 20, 1.4)
	var measure: Label = get_node("MeasureCurrentHP")
	_type(measure, 17 if _phone or _tablet else 20, 1.4)
	measure.text = current.text
	var current_width: float = minf(measure.get_minimum_size().x, inner * 0.45) if current.visible else 0
	var trailing: float = current_width if current.visible else all_width
	_rect(current, inner-56-current_width, 0, current_width, header)
	_rect(get_node("Panel/Header/Title"), 0, 0, inner-56-trailing, header)
	_type(get_node("Panel/Header/Title"), 21 if _phone else 24 if _tablet else 26, 1.2, true)
	_rect(all, inner-52-all_width, (header-44)/2.0, all_width, 44)
	_rect(get_node("Panel/Header/Close"), inner-44, (header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Header/Rule"), 0, header-1, inner, 1)
	_rect(get_node("Panel/Search"), pad+1, header+5, inner, 44)
	_rect(_list, pad+1, header+search, inner, body)
	_rect(get_node("Panel/Empty"), pad+1, header+search, inner, body)
	_rect(get_node("Panel/Footer"), pad+1, header+search+body, inner, 44)
	_rect(get_node("Panel/Health"), pad+1, header, inner, body)
	_layout_hp(inner)

func _layout_hp(width: float) -> void:
	var health: Control = get_node("Panel/Health")
	var step := 44 if _phone else 48
	var input_width := 80 if _phone else 96
	var y := 12 if _phone else 16
	var h := 46 if _phone else 50
	var x: float = width-step*2-input_width
	_rect(health.get_node("AmountLabel"), 0, y, x-8, h)
	_type(health.get_node("AmountLabel"), 18 if _phone else 22, 1.2)
	_rect(health.get_node("StepperFrame"), x-1, y, step*2+input_width+2, h)
	_rect(health.get_node("Minus"), x, y+1, step, h-2)
	_rect(health.get_node("Amount"), x+step, y+1, input_width, h-2)
	_rect(health.get_node("Plus"), x+step+input_width, y+1, step, h-2)
	_type(health.get_node("Amount"), 22 if _phone else 26, 1.1)
	var actions_y := y*2+h
	var error: Label = get_node("Panel/Health/Error")
	if error.visible:
		_rect(health.get_node("Error"), 0, actions_y, width, 38)
		_type(health.get_node("Error"), 14 if _phone else 17, 1.2)
		actions_y += 38
	var gap := 6 if _phone else 8
	var button_width: float = (width-gap*2)/3
	var button_height := 64 if _phone else 76
	for index in range(3):
		var button: Button = health.get_node(["damage", "heal", "set"][index])
		_rect(button, index*(button_width+gap), actions_y, button_width, button_height)
		var title: Label = button.get_node("Title")
		var title_size := 18 if _phone else 21
		_type(title, title_size, 1.4)
		var label_width := title.get_minimum_size().x
		var icon_gap := 4 if _phone else 6
		var group_width: float = title_size+icon_gap+label_width
		var top := 7 if _phone else 11
		_rect(button.get_node("Icon"), (button_width-group_width)/2, top+title_size*0.2, title_size, title_size)
		_rect(title, (button_width-group_width)/2+title_size+icon_gap, top, label_width, title_size*1.4)
		var preview_size := 14 if _phone else 17
		_type(button.get_node("Preview"), preview_size, 1.4)
		_rect(button.get_node("Preview"), 4, top+title_size*1.4+(6 if _phone else 8), button_width-8, preview_size*1.4)

func _style() -> void:
	for path in ["Bar/Dice", "Bar/Identity", "Bar/Health", "Panel/Header/Close", "Panel/Footer/Previous", "Panel/Footer/Next", "Panel/Health/Minus", "Panel/Health/Plus"]:
		_button_style(get_node(path))
	var health: Button = get_node("Bar/Health")
	for state in ["pressed", "hover_pressed"]:
		var surface := health.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		surface.bg_color = RAISED
		health.add_theme_stylebox_override(state, surface)
	for category in CREATURE_CATEGORIES:
		_button_style(get_node("Bar/Categories/"+category), true)
	for key in ["damage", "heal", "set"]:
		var button: Button = get_node("Panel/Health/"+key)
		_button_style(button)
		var normal := StyleBoxFlat.new()
		normal.bg_color = PANEL
		normal.border_color = EDGE
		normal.set_border_width_all(1)
		button.add_theme_stylebox_override("normal", normal)
		for state in ["hover", "pressed", "hover_pressed"]:
			var active := normal.duplicate() as StyleBoxFlat
			active.bg_color = RAISED
			button.add_theme_stylebox_override(state, active)
		var disabled := normal.duplicate() as StyleBoxFlat
		disabled.bg_color = Color(0, 0, 0, 0)
		disabled.border_color = RULE
		button.add_theme_stylebox_override("disabled", disabled)
	var stepper := StyleBoxFlat.new()
	stepper.bg_color = RAISED
	stepper.border_color = EDGE
	stepper.set_border_width_all(1)
	get_node("Panel/Health/StepperFrame").add_theme_stylebox_override("panel", stepper)
	var amount := StyleBoxFlat.new()
	amount.bg_color = INK
	amount.border_color = RULE
	amount.border_width_left = 1
	amount.border_width_right = 1
	amount.content_margin_left = 4
	amount.content_margin_right = 4
	get_node("Panel/Health/Amount").add_theme_stylebox_override("normal", amount)
	for path in ["Panel/Health/Minus", "Panel/Health/Plus"]:
		_type(get_node(path), 22 if _phone else 26, 1.0)
	get_node("Panel/Header/CurrentHP").add_theme_color_override("font_color", MUTED)
	get_node("Bar/Dice/Emblem").modulate = PICTOGRAM
	get_node("Bar/Identity/Class").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Header/ShowAll"), 16 if _phone else 17 if _tablet else 18, 1.25)
	_type(get_node("Panel/Header/Close"), 28, 1)
	_type(get_node("Panel/Empty/Title"), 18 if _phone else 22, 1.25)
	_type(get_node("Panel/Footer/Page"), 16 if _phone else 18, 1.25)
	_type(get_node("Panel/Search"), 17 if _phone else 18, 1.25)
	for path in ["Panel/Footer/Previous", "Panel/Footer/Next"]:
		_type(get_node(path), 24, 1.25)
	var background := StyleBoxFlat.new()
	background.bg_color = RAISED
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.662745, 0.768627, 0.713725, 1)
	get_node("Bar/Health/Track").add_theme_stylebox_override("background", background)
	get_node("Bar/Health/Track").add_theme_stylebox_override("fill", fill)
