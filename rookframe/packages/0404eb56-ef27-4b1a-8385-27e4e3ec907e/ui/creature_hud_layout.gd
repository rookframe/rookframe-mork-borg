extends "res://rookframe/sdk/window.gd"

## Silkbound Ledger typography, surfaces and measured Creature HUD rows.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HUD_ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW_SCRIPT = preload(ROOT + "ui/hud_row.gd")
const LINE_HEIGHT = preload("res://rookframe/ui/theme/silkbound_line_height.gd")
const REGULAR = preload("res://rookframe/ui/theme/silkbound_regular.tres")
const MEDIUM = preload("res://rookframe/ui/theme/silkbound_medium.tres")
const PLAIN = preload("res://rookframe/ui/theme/silkbound_plain.tres")
const CONTENT := Color(0.905882353, 0.905882353, 0.866666667, 1.0)
const MUTED := Color(0.76862745, 0.77254902, 0.72156863, 1.0)
const PICTOGRAM := Color(0.8745098, 0.72941176, 0.45490196, 1.0)
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
var _leaf_jolt := 0.0
@onready var _bar: Control = get_node("Bar")
@onready var _panel = get_node("Panel")
@onready var _list: GridContainer = get_node("Panel/Surface/Viewport/Root/Ink/Content/List")
@onready var _more: GridContainer = get_node("Panel/Surface/Viewport/Root/Ink/Content/More")

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
	hover.bg_color = Color(0.85, 0.76, 0.57, 0.10)
	for side in range(4):
		hover.set_content_margin(side, inset if side % 2 == 0 else 0)
	if category:
		hover.border_color = Color(0, 0, 0, 0)
		hover.set_border_width_all(1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.90196078, 0.87843137, 0.8, 1.0) if category else Color(0.85, 0.76, 0.57, 0.20)
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

func _layout_category(button: Button, width: float, height: float) -> void:
	var icon: TextureRect = button.get_node("Icon")
	var title: Label = button.get_node("Title")
	var icon_size := 18 if _phone else 26 if _tablet else 29
	var font_size := 15 if _phone else 19 if _tablet else 22
	_type(title, font_size, 1.2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.clip_text = false
	title.text_overrun_behavior = 0
	var label_width := title.get_minimum_size().x
	title.clip_text = true
	title.text_overrun_behavior = 3
	var start := maxf(2, (width-icon_size-8-label_width)/2)
	_rect(icon, start, (height-icon_size)/2, icon_size, icon_size)
	_rect(title, start+icon_size+8, 0, maxf(0,width-start-icon_size-10), height)

func _render_entry(row: ROW_SCRIPT, entry: HUD_ENTRY, fixed: bool, favorite_pending := false) -> void:
	var ability_grid := _phone and _category == "Abilities"
	var height := 50 if ability_grid else 58 if _phone else 64 if _tablet else 70
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
	content.offset_top = 6 if _phone else 8
	content.offset_bottom = -content.offset_top
	var icon: TextureRect = content.get_node("Icon")
	icon.texture = entry.icon
	var icon_size := 20 if ability_grid else 24 if _phone else 26 if _tablet else 34
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.modulate = PICTOGRAM if entry.available else MUTED
	var copy: VBoxContainer = content.get_node("Copy")
	copy.add_theme_constant_override("separation", 2 if _phone else 4)
	var title: Label = copy.get_node("Title")
	title.max_lines_visible = 3 if _category == "Scene" else 2
	title.text = entry.title
	_type(title, 18 if _phone else 22 if _tablet else 26, 1.25 if _phone else 1.15)
	var detail: Label = copy.get_node("Detail")
	detail.text = entry.detail
	detail.visible = not entry.detail.is_empty()
	_type(detail, 14 if _phone else 16 if _tablet else 19, 1.2)
	detail.add_theme_color_override("font_color", MUTED)
	row.get_node("FullName").visible = false
	var value: Label = content.get_node("Value")
	value.text = entry.value
	value.visible = not entry.value.is_empty() and not entry.value_is_action
	_type(value, 18 if _phone else 21 if _tablet else 26, 1.25)
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
	if not is_node_ready(): return
	var dice_width := 44 if _phone else 64 if _tablet else 94
	var identity_width := 206 if _phone else 278 if _tablet else 390
	var gap := 6 if _phone else 14 if _tablet else 18
	var category_width := 282 if _phone else 320 if _tablet else 380
	var width: float = minf(dice_width+identity_width+category_width+gap*2, size.x-80)
	var height := 98 if _phone else 114 if _tablet else 136
	_rect(_bar, (size.x-width)/2, size.y-(18 if _phone else 24)-height, width, height)
	_rect(get_node("Bar/Dice"), 0, 18 if _phone else 16, dice_width, 58 if _phone else 78 if _tablet else 94)
	var dice: Control = get_node("Bar/Dice")
	var emblem := 32 if _phone else 46 if _tablet else 60
	_rect(dice.get_node("Emblem"), (dice_width-emblem)/2, (dice.size.y-emblem)/2, emblem, emblem)
	var identity: Control = get_node("Bar/Identity")
	_rect(identity, dice_width+gap, 0, identity_width, height-(4 if _phone or _tablet else 12))
	var portrait := Vector2(38,52) if _phone else Vector2(64,80) if _tablet else Vector2(82,96)
	var pad := 10 if _phone else 12 if _tablet else 16
	_rect(identity.get_node("PortraitFrame"), pad, (identity.size.y-portrait.y)/2, portrait.x, portrait.y)
	_layout_portrait()
	var text_x := pad+portrait.x+(10 if _phone else 14 if _tablet else 16)
	var text_width := identity_width-text_x-pad-6
	_rect(identity.get_node("Name"), text_x, 3 if _phone else 6 if _tablet else 8, text_width, 24 if _phone else 31 if _tablet else 38)
	_type(identity.get_node("Name"), 18 if _phone else 26 if _tablet else 32, 1.1)
	_rect(identity.get_node("Class"), text_x, 28 if _phone else 38 if _tablet else 46, text_width, 16 if _phone else 20 if _tablet else 27)
	_type(identity.get_node("Class"), 14 if _phone else 18 if _tablet else 23, 1.1)
	# Independent HP action sits inside the identity leather, clear of its notch.
	_rect(get_node("Bar/Health"), identity.position.x+text_x, identity.size.y-50, identity_width-text_x-38, 44)
	_layout_health()
	var categories: Control = get_node("Bar/Categories")
	var category_x := identity.position.x+identity_width+gap
	_rect(categories, category_x, (2 if _phone else 6)+_leaf_jolt, width-category_x, height-(2 if _phone else 6))
	var row_padding := 4 if _phone else 8
	var row_height := (categories.size.y-row_padding*2)/2
	var button_width := (categories.size.x-24)/2
	for index in range(CREATURE_CATEGORIES.size()):
		var button: Button = categories.get_node(CREATURE_CATEGORIES[index])
		_rect(button, 12+(index%2)*button_width, row_padding+(0 if index<2 else row_height), button_width-2, row_height)
		_layout_category(button, button.size.x, button.size.y)
	_rect(categories.get_node("Rule"), 20, categories.size.y/2, categories.size.x-40, 1)
	_layout_bindings()
	_layout_panel()

func _layout_health() -> void:
	var hp: Button = get_node("Bar/Health")
	var value: Label = hp.get_node("Value")
	_type(value, 15 if _phone else 19 if _tablet else 22, 1.15)
	var measure: Label = get_node("MeasureCurrentHP")
	_type(measure, 15 if _phone else 19 if _tablet else 22, 1.15)
	measure.text = value.text
	var text_width := measure.get_minimum_size().x
	var track: ProgressBar = hp.get_node("Track")
	track.visible = not _phone and hp.size.x-text_width >= 40
	var left := hp.size.x-text_width if track.visible else 0.0
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if track.visible else HORIZONTAL_ALIGNMENT_LEFT
	_rect(value, left, 0, hp.size.x-left, hp.size.y)
	_rect(track, 0, (hp.size.y-7)/2, maxf(24, left-12), 7)

func _leaf_reaction(offset: float) -> void:
	_leaf_jolt = offset
	var categories: Control = get_node("Bar/Categories")
	categories.position = Vector2(categories.position.x, (2 if _phone else 6)+offset)
	_layout_bindings()

func _layout_bindings() -> void:
	var leaves: Array[Control] = [get_node("Bar/Dice"), get_node("Bar/Identity"), get_node("Bar/Categories")]
	for index in range(2):
		var left := leaves[index]
		var right := leaves[index+1]
		var top := maxf(left.position.y, right.position.y)+8
		var bottom := minf(left.position.y+left.size.y, right.position.y+right.size.y)-8
		_rect(get_node("Bar/LeftBindings" if index == 0 else "Bar/RightBindings"), left.position.x+left.size.x-9, top, right.position.x-left.position.x-left.size.x+18, bottom-top)

func _layout_portrait() -> void:
	var frame: Control = get_node("Bar/Identity/PortraitFrame")
	_rect(frame.get_node("Portrait"), 0, 0, frame.size.x, frame.size.y)

func _layout_panel() -> void:
	if not is_node_ready():
		return
	var width: float = minf(380 if _phone else 430 if _tablet else 510, _bar.size.x)
	var pad := 12 if _phone else 16 if _tablet else 20
	var header := 52 if _phone else 60 if _tablet else 68
	var inner: float = width-pad*2-2
	var search := 52 if get_node("Panel/Surface/Viewport/Root/Ink/Content/Search").visible else 0
	var footer := 44 if get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer").visible else 0
	var body: float = _list.get_combined_minimum_size().y if _list.visible else 52 if _phone else 64
	if get_node("Panel/Surface/Viewport/Root/Ink/Content/Health").visible:
		body = 138 if _phone else 166
		if get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/Error").visible:
			body += 38
	var height: float = header+search+body+footer+(6 if _phone else 10)
	var categories: Control = get_node("Bar/Categories")
	_panel.hinge_gap = 12.0 if _phone else 20.0 if _tablet else 26.0
	_panel.hinge_inset = maxf(32, (width-categories.size.x)/2+32)
	var left: float = clampf(_bar.position.x+categories.position.x+(categories.size.x-width)/2, 12, size.x-width-12)
	_rect(_panel, left, _bar.position.y+(2 if _phone else 6)-_panel.hinge_gap-height, width, height)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header"), pad+1, 1, inner, header)
	var all: CheckBox = get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll")
	var all_width: float = all.get_minimum_size().x if all.visible else 0
	var current: Label = get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/CurrentHP")
	_type(current, 17 if _phone or _tablet else 20, 1.4)
	var measure: Label = get_node("MeasureCurrentHP")
	_type(measure, 17 if _phone or _tablet else 20, 1.4)
	measure.text = current.text
	var current_width: float = minf(measure.get_minimum_size().x, inner * 0.45) if current.visible else 0
	var trailing: float = current_width if current.visible else all_width
	_rect(current, inner-56-current_width, 0, current_width, header)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Title"), 0, 0, inner-56-trailing, header)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Title"), 23 if _phone else 28 if _tablet else 31, 1.2)
	_rect(all, inner-52-all_width, (header-44)/2.0, all_width, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Close"), inner-44, (header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Rule"), 0, header-1, inner, 1)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Search"), pad+1, header+5, inner, 44)
	_rect(_list, pad+1, header+search, inner, body)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty"), pad+1, header+search, inner, body)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer"), pad+1, header+search+body, inner, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Health"), pad+1, header, inner, body)
	_layout_hp(inner)

func _layout_hp(width: float) -> void:
	var health: Control = get_node("Panel/Surface/Viewport/Root/Ink/Content/Health")
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
	var error: Label = get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/Error")
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
	for path in ["Bar/Dice", "Bar/Identity", "Bar/Health", "Panel/Surface/Viewport/Root/Ink/Content/Header/Close", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Previous", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Next", "Panel/Surface/Viewport/Root/Ink/Content/Health/Minus", "Panel/Surface/Viewport/Root/Ink/Content/Health/Plus"]:
		_button_style(get_node(path))
	var health: Button = get_node("Bar/Health")
	for state in ["pressed", "hover_pressed"]:
		var surface := health.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		surface.bg_color = Color(0.85, 0.76, 0.57, 0.20)
		health.add_theme_stylebox_override(state, surface)
	for category in CREATURE_CATEGORIES:
		_button_style(get_node("Bar/Categories/"+category), true)
	for key in ["damage", "heal", "set"]:
		var button: Button = get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/"+key)
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
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/StepperFrame").add_theme_stylebox_override("panel", stepper)
	var amount := StyleBoxFlat.new()
	amount.bg_color = INK
	amount.border_color = RULE
	amount.border_width_left = 1
	amount.border_width_right = 1
	amount.content_margin_left = 4
	amount.content_margin_right = 4
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/Amount").add_theme_stylebox_override("normal", amount)
	for path in ["Panel/Surface/Viewport/Root/Ink/Content/Health/Minus", "Panel/Surface/Viewport/Root/Ink/Content/Health/Plus"]:
		_type(get_node(path), 22 if _phone else 26, 1.0)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/CurrentHP").add_theme_color_override("font_color", MUTED)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll").add_theme_color_override(state, MUTED)
	get_node("Bar/Dice/Emblem").modulate = PICTOGRAM
	get_node("Bar/Identity/Class").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll"), 16 if _phone else 17 if _tablet else 18, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Close"), 28, 1)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty/Title"), 18 if _phone else 22, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Page"), 16 if _phone else 18, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Search"), 17 if _phone else 18, 1.25)
	for path in ["Panel/Surface/Viewport/Root/Ink/Content/Footer/Previous", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Next"]:
		_type(get_node(path), 24, 1.25)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.25882353, 0.27058824, 0.25490196, 1.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.65098039, 0.73333333, 0.56470588, 1.0)
	get_node("Bar/Health/Track").add_theme_stylebox_override("background", background)
	get_node("Bar/Health/Track").add_theme_stylebox_override("fill", fill)
