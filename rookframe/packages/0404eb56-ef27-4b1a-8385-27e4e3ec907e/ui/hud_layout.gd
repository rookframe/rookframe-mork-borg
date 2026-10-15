extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

## Silkbound Ledger presentation shared by every Character HUD state.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
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
const CATEGORIES := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery"]
const BUTTONS := CATEGORIES
var _category := ""
var _detail_page := 0
var _phone := false
var _tablet := false
var _rows: Array[ROW_SCRIPT] = []
var _panel_anchor: Button
var _name_check_pending := false
var _leaf_jolt := 0.0
@onready var _bar: Control = get_node("Bar")
@onready var _panel = get_node("Panel")
@onready var _list: GridContainer = get_node("Panel/Surface/Viewport/Root/Ink/Content/List")

func _schedule_name_check() -> void:
	if not _name_check_pending:
		_name_check_pending = true
		_check_names.call_deferred()

func _check_names() -> void:
	_name_check_pending = false
	for row in _rows:
		if not row.visible:
			continue
		var title: Label = row.get_node("Launch/Content/Copy/Title")
		row.get_node("FullName").visible = title.get_line_count() > title.max_lines_visible
		var detail: Label = row.get_node("Launch/Content/Copy/Detail")
		var line_height: float = 23 if _phone else 27 if _tablet else 30
		var text_height: float = mini(title.get_line_count(), 2)*line_height
		if detail.visible:
			text_height += (17 if _phone else 18 if _tablet else 20)+(2 if _phone else 4)
		var minimum := 50 if _phone and _category == "Abilities" else 58 if _phone else 64 if _tablet else 70
		var padding := 6 if _phone else 8
		var height := maxf(minimum, text_height+padding*2)
		row.custom_minimum_size = Vector2(0, height+(1 if row.separator else 0))
		row.get_node("Launch").custom_minimum_size = Vector2(0, height)
	_layout_panel()

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

func _layout() -> void:
	if not is_node_ready(): return
	var inset := 48 if _tablet else 40 if _phone else 48
	var width := minf(680.0 if _phone else 1090.0, size.x - inset * 2)
	var height := 98 if _phone else 114 if _tablet else 136
	_rect(_bar, (size.x - width) / 2, size.y - (18 if _phone else 24) - height, width, height)
	var dice_width := 44 if _phone else 64 if _tablet else 94
	var identity_width := 174 if _phone else 278 if _tablet else 390
	var gap := 6 if _phone else 14 if _tablet else 18
	var identity_x := dice_width + gap
	var category_x := identity_x + identity_width + gap
	_rect(get_node("Bar/Dice"), 0, 16 if not _phone else 18, dice_width, 58 if _phone else 78 if _tablet else 94)
	var emblem := 32 if _phone else 46 if _tablet else 60
	var dice: Control = get_node("Bar/Dice")
	_rect(get_node("Bar/Dice/Emblem"), (dice_width-emblem)/2, (dice.size.y-emblem)/2, emblem, emblem)
	var identity: Control = get_node("Bar/Identity")
	_rect(identity, identity_x, 0, identity_width, height-12)
	var portrait := Vector2(38, 52) if _phone else Vector2(64, 80) if _tablet else Vector2(82, 96)
	var pad := 10 if _phone else 12 if _tablet else 16
	_rect(identity.get_node("PortraitFrame"), pad, (identity.size.y-portrait.y)/2, portrait.x, portrait.y)
	_layout_portrait()
	var text_x := pad + portrait.x + (10 if _phone else 14 if _tablet else 16)
	var text_width := identity_width - text_x - pad - 6
	_type(identity.get_node("Name"), 18 if _phone else 26 if _tablet else 32, 1.1)
	_type(identity.get_node("Class"), 14 if _phone else 18 if _tablet else 23, 1.15)
	_type(identity.get_node("Hp"), 15 if _phone else 19 if _tablet else 22, 1.15)
	_rect(identity.get_node("Name"), text_x, 8 if _phone else 10, text_width, 24 if _phone else 32 if _tablet else 38)
	get_node("Bar/Identity/Class").visible = true
	_rect(identity.get_node("Class"), text_x, 33 if _phone else 45 if _tablet else 49, text_width, 19 if _phone else 22 if _tablet else 28)
	# Keep the health readout left of the skin's stepped lower-right corner.
	_rect(identity.get_node("Hp"), text_x, identity.size.y-34 if _phone else identity.size.y-40, identity_width-text_x-38, 24 if _phone else 28)
	get_node("Bar/Identity/Divider").visible = false
	_layout_health()
	var categories: Control = get_node("Bar/Categories")
	_rect(categories, category_x, (2 if _phone else 6)+_leaf_jolt, width-category_x, height-(2 if _phone else 6))
	var row_padding := 4 if _phone else 8
	var row_height := (categories.size.y-row_padding*2)/2
	for index in range(CATEGORIES.size()):
		var top := index < 4
		var count := 4 if top else 3
		var column := index if top else index-4
		var button_width := (categories.size.x-24)/count
		var button: Button = categories.get_node(CATEGORIES[index])
		button.visible = true
		_rect(button, 12+column*button_width, row_padding+(0 if top else row_height), button_width-2, row_height)
		_layout_category(button, button.size.x, button.size.y)
	_rect(categories.get_node("Rule"), 20, categories.size.y/2, categories.size.x-40, 1)
	_layout_bindings()
	_layout_panel()

func _layout_health() -> void:
	var identity: Control = get_node("Bar/Identity")
	var hp: Label = identity.get_node("Hp")
	var track: ProgressBar = identity.get_node("HpTrack")
	track.visible = not _phone
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if _phone else HORIZONTAL_ALIGNMENT_RIGHT
	_rect(track, hp.position.x, hp.position.y+(hp.size.y-7)/2, maxf(24, hp.size.x-hp.get_minimum_size().x-12), 7)

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
	var portrait: TextureRect = frame.get_node("Portrait")
	if portrait.texture == null or frame.size.y == 0:
		return
	var source: Vector2 = portrait.texture.get_size()
	var placeholder := portrait.texture == preload("res://rookframe/ui/icons/character/character.svg")
	var zoom := minf(frame.size.x/source.x, frame.size.y/source.y) if placeholder else maxf(frame.size.x/source.x, frame.size.y/source.y)*1.65
	var image_size := Vector2(source.x*zoom, source.y*zoom)
	_rect(portrait, (frame.size.x-image_size.x)/2.0, (frame.size.y-image_size.y)/2.0 if placeholder else 0.0, image_size.x, image_size.y)

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

func _layout_panel() -> void:
	if not is_node_ready():
		return
	var categories: Control = get_node("Bar/Categories")
	var width: float = minf(400 if _phone else 548, categories.size.x-12)
	var pad := 12 if _phone else 16 if _tablet else 20
	var header := 44 if _phone else 52 if _tablet else 62
	var footer := 44 if _phone or _tablet else 50
	var bottom := 4 if _phone else 8
	var body: float = _list.get_combined_minimum_size().y if _list.visible else 52 if _phone else 64
	var detail: Label = get_node("Panel/Surface/Viewport/Root/Ink/Content/Detail/Text")
	var detail_area: Control = get_node("Panel/Surface/Viewport/Root/Ink/Content/Detail")
	var detail_lines := 3 if _phone else 5
	if detail_area.visible:
		detail.size = Vector2(width-2-pad*2-(8 if _phone else 12), detail.size.y)
		var pages := maxi(1, ceili(float(detail.get_line_count()) / detail_lines))
		_detail_page = clampi(_detail_page, 0, pages-1)
		get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer").visible = pages > 1
		get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Page").text = "%s / %s" % [_detail_page+1, pages]
		get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Previous").disabled = _detail_page == 0
		get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Next").disabled = _detail_page == pages-1
		body = mini(detail_lines, detail.get_line_count()-_detail_page*detail_lines)*(27 if _phone else 33)+(16 if _phone else 24)
	var height: float = 2+header+body+(footer if get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer").visible else 0)+bottom
	_panel.hinge_gap = 12.0 if _phone else 20.0 if _tablet else 26.0
	_panel.hinge_inset = 36.0 if _phone else 48.0
	_rect(_panel, _bar.position.x+categories.position.x+(categories.size.x-width)/2, _bar.position.y+(2 if _phone else 6)-_panel.hinge_gap-height, width, height)
	var inner: float = width-2-pad*2
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header"), pad+1, 1, inner, header)
	var morning: Button = get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Morning")
	var show_all: CheckBox = get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll")
	var header_gap := 8 if _phone or _tablet else 12
	var morning_width: float = maxf(60, _text_width(morning)+(12 if _phone else 24)) if morning.visible else 0.0
	var all_width: float = show_all.get_minimum_size().x if show_all.visible else 0.0
	var title_width: float = inner-44-header_gap
	if morning.visible:
		title_width -= morning_width+header_gap
	if show_all.visible:
		title_width -= all_width+header_gap
	var back: Button = get_node("Panel/Surface/Viewport/Root/Ink/Content/Back")
	_rect(back, pad+1, 1+(header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Title"), 44+header_gap if back.visible else 0, 0, title_width-(44+header_gap if back.visible else 0), header)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Title"), 23 if _phone else 28 if _tablet else 31, 1.2)
	_rect(show_all, title_width+header_gap, (header-44)/2.0, all_width, 44)
	_rect(morning, inner-44-header_gap-morning_width, (header-44)/2.0, morning_width, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Close"), inner-44, (header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Rule"), 0, header-1, inner, 1)
	_rect(_list, pad+1, 1+header, inner, body)
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty"), pad+1+(4 if _phone else 8), 1+header, inner-(8 if _phone else 16), body)
	var detail_x := 4 if _phone else 6
	var detail_y := 8 if _phone else 12
	_rect(detail_area, pad+1+detail_x, 1+header+detail_y, inner-detail_x*2, body-detail_y*2)
	_rect(detail, 0, -_detail_page*detail_lines*(27 if _phone else 33), detail_area.size.x, detail.get_line_count()*(27 if _phone else 33))
	_rect(get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer"), pad+1, 1+header+body+(0 if _phone or _tablet else 6), inner, 44)

func _text_width(control: Button) -> float:
	return control.get_minimum_size().x

func _style() -> void:
	for path in ["Bar/Dice", "Bar/Identity", "Panel/Surface/Viewport/Root/Ink/Content/Back", "Panel/Surface/Viewport/Root/Ink/Content/Header/Close", "Panel/Surface/Viewport/Root/Ink/Content/Header/Morning", "Panel/Surface/Viewport/Root/Ink/Content/Empty/Sheet", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Previous", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Next"]:
		_button_style(get_node(path))
	get_node("Bar/Dice/Emblem").modulate = PICTOGRAM
	_button_style(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty/Sheet"), false, 8 if _phone else 12)
	get_node("Bar/Identity/Class").add_theme_color_override("font_color", MUTED)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty/Title").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty/Title"), 18 if _phone else 22, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Empty/Sheet"), 16 if _phone else 13, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Close"), 28, 1.0)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Close").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Back"), 28, 1.0)
	var size_header := 16 if _phone else 17 if _tablet else 18
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll"), size_header, 1.25)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Morning"), size_header, 1.25)
	var allowance_edge := StyleBoxFlat.new()
	allowance_edge.bg_color = Color(0, 0, 0, 0)
	allowance_edge.border_color = RULE
	allowance_edge.border_width_left = 1
	for side in range(4):
		allowance_edge.set_content_margin(side, 0)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Morning").add_theme_stylebox_override("normal", allowance_edge)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/Morning").add_theme_stylebox_override("disabled", allowance_edge)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Detail/Text"), 18 if _phone else 22, 1.5)
	_type(get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Page"), 16 if _phone or _tablet else 18, 1.25)
	get_node("Panel/Surface/Viewport/Root/Ink/Content/Footer/Page").add_theme_color_override("font_color", MUTED)
	for path in ["Panel/Surface/Viewport/Root/Ink/Content/Footer/Previous", "Panel/Surface/Viewport/Root/Ink/Content/Footer/Next"]:
		_type(get_node(path), 24, 1.25)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.25882353, 0.27058824, 0.25490196, 1.0)
	for side in range(4):
		track.set_content_margin(side, 0)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.65098039, 0.73333333, 0.56470588, 1.0)
	for side in range(4):
		fill.set_content_margin(side, 0)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("fill", fill)
	for category in BUTTONS:
		_button_style(get_node("Bar/Categories/"+category), true)
