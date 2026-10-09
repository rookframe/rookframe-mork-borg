extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

## Silkbound Ledger presentation shared by every Character HUD state.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
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
const CATEGORIES := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery"]
const BUTTONS := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery", "More"]
var _category := ""
var _detail_page := 0
var _phone := false
var _tablet := false
var _rows: Array[ROW_SCRIPT] = []
var _panel_anchor: Button
var _name_check_pending := false
@onready var _bar: Control = get_node("Bar")
@onready var _panel: Control = get_node("Panel")
@onready var _list: GridContainer = get_node("Panel/List")
@onready var _more: GridContainer = get_node("Panel/More")

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
		var minimum := 50 if _phone and _category == "Abilities" else 58 if _phone else 64 if _tablet else 76
		var padding := 6 if _phone else 8 if _tablet else 10
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

func _layout() -> void:
	if not is_node_ready():
		return
	# The host supplies the safe viewport; this is the reference's fixed
	# composition inside it. Collection state never changes these dimensions.
	var inset := 56 if _phone else 48 if _tablet else 256
	var height := 68 if _phone else 88 if _tablet else 120
	var bottom := 29 if _phone else 24
	_rect(_bar, inset, size.y-bottom-height, size.x-inset*2, height)
	var padding := 12 if _phone or _tablet else 16
	var top := 9 if _phone else 11 if _tablet else 15
	var content_height := height-top*2
	var dice_width := 48 if _phone else 58 if _tablet else 96
	var gap := 12 if _phone or _tablet else 20
	_rect(get_node("Bar/Dice"), 0, 6, padding+dice_width, height-12)
	var emblem := 34 if _phone else 38 if _tablet else 56
	_rect(get_node("Bar/Dice/Emblem"), (padding+dice_width-emblem)/2.0, (height-12-emblem)/2.0, emblem, emblem)
	var identity_width := 172 if _phone else 216 if _tablet else 336
	var identity: Control = get_node("Bar/Identity")
	# Each button fills its compartment between the bar edge and separators.
	var identity_inset := gap
	var identity_top := top-6
	_rect(identity, padding+dice_width+gap-identity_inset, 6, identity_width+identity_inset, height-12)
	var portrait := Vector2(38, 48) if _phone else Vector2(50, 64) if _tablet else Vector2(76, 88)
	_rect(identity.get_node("PortraitFrame"), identity_inset, identity_top+(content_height-portrait.y)/2.0, portrait.x, portrait.y)
	_layout_portrait()
	var text_x: float = identity_inset+portrait.x+(10 if _phone else 12 if _tablet else 18)
	var text_width: float = identity_width+identity_inset-text_x-(13 if _phone or _tablet else 25)
	var name_size := 20 if _phone else 22 if _tablet else 28
	var class_size := 14 if _tablet else 18
	var hp_size := 15 if _phone or _tablet else 18
	_type(identity.get_node("Name"), name_size, 1.1, true)
	_type(identity.get_node("Class"), class_size, 1.4)
	_type(identity.get_node("Hp"), hp_size, 1.25)
	var name_height := name_size*1.1
	var class_height := class_size*1.4
	var hp_height := hp_size*1.25
	var name_gap := 3 if _phone else 2
	var hp_margin := 3 if _phone else 5 if _tablet else 8
	var text_height: float = name_height+name_gap+hp_margin+hp_height
	if not _phone:
		text_height += class_height+name_gap
	var text_top: float = identity_top+(content_height-text_height)/2.0
	_rect(identity.get_node("Name"), text_x, text_top, text_width, name_height)
	_rect(identity.get_node("Class"), text_x, text_top+name_height+name_gap, text_width, class_height)
	var class_label: Label = identity.get_node("Class")
	class_label.visible = not _phone
	_rect(identity.get_node("Hp"), text_x, text_top+text_height-hp_height, text_width, hp_height)
	_layout_health()
	_rect(identity.get_node("Divider"), identity_width+identity_inset-1, 0, 1, height-12)
	var category_x: float = padding+dice_width+gap+identity_width+gap
	var category_top := 0 if _phone or _tablet else 4
	_rect(get_node("Bar/Categories"), category_x, top+category_top, _bar.size.x-category_x-padding, content_height-category_top*2)
	var buttons: Array = ["Abilities", "Attacks", "Powers", "Items", "More"] if _phone else CATEGORIES
	var category_gap := 4 if _phone or _tablet else 8
	var button_width: float = (get_node("Bar/Categories").size.x-category_gap*(buttons.size()-1))/buttons.size()
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.visible = category in buttons
		if button.visible:
			_rect(button, buttons.find(category)*(button_width+category_gap), 0, button_width, get_node("Bar/Categories").size.y)
			_layout_category(button, button_width, button.size.y)
	_layout_panel()

func _layout_health() -> void:
	var identity: Control = get_node("Bar/Identity")
	var hp: Label = identity.get_node("Hp")
	var track: ProgressBar = identity.get_node("HpTrack")
	track.visible = not _phone
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if _phone else HORIZONTAL_ALIGNMENT_RIGHT
	var text_width := hp.get_minimum_size().x
	_rect(track, hp.position.x, hp.position.y+(hp.size.y-3)/2.0, maxf(24, hp.size.x-text_width-(8 if _tablet else 12)), 3)

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

func _layout_panel() -> void:
	if _panel_anchor == null or not _panel.visible:
		return
	var width: float = minf(380 if _phone else 430 if _tablet else 510, _bar.size.x)
	var pad := 12 if _phone else 16 if _tablet else 20
	var header := 44 if _phone else 52 if _tablet else 64
	var footer := 44 if _phone or _tablet else 50
	var bottom := 4 if _phone else 8
	var body: float = 76 if _more.visible else _list.get_combined_minimum_size().y if _list.visible else 52 if _phone else 64
	var detail: Label = get_node("Panel/Detail/Text")
	var detail_area: Control = get_node("Panel/Detail")
	var detail_lines := 3 if _phone else 5
	if detail_area.visible:
		detail.size = Vector2(width-2-pad*2-(8 if _phone else 12), detail.size.y)
		var pages := maxi(1, ceili(float(detail.get_line_count()) / detail_lines))
		_detail_page = clampi(_detail_page, 0, pages-1)
		get_node("Panel/Footer").visible = pages > 1
		get_node("Panel/Footer/Page").text = "%s / %s" % [_detail_page+1, pages]
		get_node("Panel/Footer/Previous").disabled = _detail_page == 0
		get_node("Panel/Footer/Next").disabled = _detail_page == pages-1
		body = mini(detail_lines, detail.get_line_count()-_detail_page*detail_lines)*(27 if _phone else 33)+(16 if _phone else 24)
	var height: float = 2+header+body+(footer if get_node("Panel/Footer").visible else 0)+bottom
	var anchor: float = _panel_anchor.position.x+get_node("Bar/Categories").position.x+_panel_anchor.size.x/2.0
	var dice: Control = get_node("Bar/Dice")
	var clearance: float = dice.position.x+dice.size.x+8
	var left: float = maxf(0, minf(_bar.size.x-width, maxf(clearance, anchor-width/2.0)))
	_rect(_panel, _bar.position.x+left, _bar.position.y-(12 if _phone or _tablet else 14)-height, width, height)
	var inner: float = width-2-pad*2
	_rect(get_node("Panel/Header"), pad+1, 1, inner, header)
	var morning: Button = get_node("Panel/Header/Morning")
	var show_all: CheckBox = get_node("Panel/Header/ShowAll")
	var header_gap := 8 if _phone or _tablet else 12
	var morning_width: float = maxf(60, _text_width(morning)+(12 if _phone else 24)) if morning.visible else 0.0
	var all_width: float = show_all.get_minimum_size().x if show_all.visible else 0.0
	var title_width: float = inner-44-header_gap
	if morning.visible:
		title_width -= morning_width+header_gap
	if show_all.visible:
		title_width -= all_width+header_gap
	var back: Button = get_node("Panel/Back")
	_rect(back, pad+1, 1+(header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Header/Title"), 44+header_gap if back.visible else 0, 0, title_width-(44+header_gap if back.visible else 0), header)
	_type(get_node("Panel/Header/Title"), 21 if _phone else 24 if _tablet else 26, 1.2, true)
	_rect(show_all, title_width+header_gap, (header-44)/2.0, all_width, 44)
	_rect(morning, inner-44-header_gap-morning_width, (header-44)/2.0, morning_width, 44)
	_rect(get_node("Panel/Header/Close"), inner-44, (header-44)/2.0, 44, 44)
	_rect(get_node("Panel/Header/Rule"), 0, header-1, inner, 1)
	_rect(_list, pad+1, 1+header, inner, body)
	_rect(_more, pad+1, 1+header+6, inner, body-12)
	_rect(get_node("Panel/Empty"), pad+1+(4 if _phone else 8), 1+header, inner-(8 if _phone else 16), body)
	var detail_x := 4 if _phone else 6
	var detail_y := 8 if _phone else 12
	_rect(detail_area, pad+1+detail_x, 1+header+detail_y, inner-detail_x*2, body-detail_y*2)
	_rect(detail, 0, -_detail_page*detail_lines*(27 if _phone else 33), detail_area.size.x, detail.get_line_count()*(27 if _phone else 33))
	_rect(get_node("Panel/Footer"), pad+1, 1+header+body+(0 if _phone or _tablet else 6), inner, 44)
	if _category == "More":
		for category in ["Features", "Companions", "Recovery"]:
			var button: Button = get_node("Panel/More/" + category)
			_layout_category(button, (inner-16)/3.0, 64, true)

func _text_width(control: Button) -> float:
	return control.get_minimum_size().x

func _style() -> void:
	for path in ["Bar/Dice", "Bar/Identity", "Panel/Back", "Panel/Header/Close", "Panel/Header/Morning", "Panel/Empty/Sheet", "Panel/Footer/Previous", "Panel/Footer/Next"]:
		_button_style(get_node(path))
	get_node("Bar/Dice/Emblem").modulate = PICTOGRAM
	_button_style(get_node("Panel/Empty/Sheet"), false, 8 if _phone else 12)
	var dice_divider := StyleBoxFlat.new()
	dice_divider.bg_color = Color(0, 0, 0, 0)
	dice_divider.border_color = RULE
	dice_divider.border_width_right = 1
	for side in range(4):
		dice_divider.set_content_margin(side, 0)
	get_node("Bar/Dice").add_theme_stylebox_override("normal", dice_divider)
	var dice_hover := dice_divider.duplicate() as StyleBoxFlat
	dice_hover.bg_color = PANEL
	get_node("Bar/Dice").add_theme_stylebox_override("hover", dice_hover)
	var dice_pressed := dice_hover.duplicate() as StyleBoxFlat
	dice_pressed.bg_color = RAISED
	get_node("Bar/Dice").add_theme_stylebox_override("pressed", dice_pressed)
	get_node("Bar/Identity/Class").add_theme_color_override("font_color", MUTED)
	get_node("Panel/Empty/Title").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Empty/Title"), 18 if _phone else 22, 1.25)
	_type(get_node("Panel/Empty/Sheet"), 16 if _phone else 13, 1.25)
	_type(get_node("Panel/Header/Close"), 28, 1.0)
	get_node("Panel/Header/Close").add_theme_color_override("font_color", MUTED)
	_type(get_node("Panel/Back"), 28, 1.0)
	var size_header := 16 if _phone else 17 if _tablet else 18
	_type(get_node("Panel/Header/ShowAll"), size_header, 1.25)
	_type(get_node("Panel/Header/Morning"), size_header, 1.25)
	var allowance_edge := StyleBoxFlat.new()
	allowance_edge.bg_color = Color(0, 0, 0, 0)
	allowance_edge.border_color = RULE
	allowance_edge.border_width_left = 1
	for side in range(4):
		allowance_edge.set_content_margin(side, 0)
	get_node("Panel/Header/Morning").add_theme_stylebox_override("normal", allowance_edge)
	get_node("Panel/Header/Morning").add_theme_stylebox_override("disabled", allowance_edge)
	_type(get_node("Panel/Detail/Text"), 18 if _phone else 22, 1.5)
	_type(get_node("Panel/Footer/Page"), 16 if _phone or _tablet else 18, 1.25)
	get_node("Panel/Footer/Page").add_theme_color_override("font_color", MUTED)
	for path in ["Panel/Footer/Previous", "Panel/Footer/Next"]:
		_type(get_node(path), 24, 1.25)
	var track := StyleBoxFlat.new()
	track.bg_color = RAISED
	for side in range(4):
		track.set_content_margin(side, 0)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.662745098, 0.768627451, 0.71372549, 1.0)
	for side in range(4):
		fill.set_content_margin(side, 0)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("fill", fill)
	for category in BUTTONS:
		_button_style(get_node("Bar/Categories/"+category), true)
	for category in ["Features", "Companions", "Recovery"]:
		_button_style(get_node("Panel/More/"+category))
