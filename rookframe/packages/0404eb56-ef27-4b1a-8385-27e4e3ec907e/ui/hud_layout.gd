extends "res://rookframe/sdk/window.gd"

## Layout shared by every Character HUD state. The look comes from the World
## theme: the UI Kit HUD bar and its components, type variations and
## `RookframeTokens` reads that follow a live World theme change.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const ROW_SCRIPT = preload(ROOT + "ui/hud_row.gd")
const TOKENS := &"RookframeTokens"
const CATEGORIES := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery"]
const BUTTONS := CATEGORIES
## The folding list keeps the hinged leaf's own measure, narrower on a phone.
const PANEL_WIDTH := 548.0
const PHONE_PANEL_WIDTH := 400.0
## Full-name copy shows this many lines per page.
const DETAIL_LINES := 5
const PHONE_DETAIL_LINES := 3
const CONTENT := "Panel/Surface/Viewport/Root/Ink/Content/Layout/"
var _category := ""
var _detail_page := 0
var _phone := false
var _tablet := false
var _rows: Array[ROW_SCRIPT] = []
var _panel_anchor: Button
var _name_check_pending := false
var _restyle_pending := false
## Entries on one page: a page gives up rows until the list stands above the bar.
const ROW_LIMIT := 4
var _row_limit := ROW_LIMIT
var _page_size := ROW_LIMIT
var _refit_pending := false
@onready var _bar = get_node(^"Bar")
@onready var _panel = get_node(^"Panel")
@onready var _content: Control = get_node(^"Panel/Surface/Viewport/Root/Ink/Content/Layout")
@onready var _list: GridContainer = get_node(CONTENT + "List")

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready() and not _restyle_pending:
		# Kit components and the leaf's bridged content settle their own theme first.
		_restyle_pending = true
		_restyle.call_deferred()

func _restyle() -> void:
	_restyle_pending = false
	_style()
	_layout()
	_schedule_name_check()

func _space(step: int) -> int:
	return get_theme_constant(StringName("space_%d" % step), TOKENS)

func _schedule_name_check() -> void:
	if not _name_check_pending:
		_name_check_pending = true
		_check_names.call_deferred()

## Rows grow with their wrapped copy; a name beyond two lines offers its full text.
func _check_names() -> void:
	_name_check_pending = false
	for row in _rows:
		if not row.visible:
			continue
		row.get_node(^"FullName").visible = _needs_full_name(row)
		var launch: Button = row.get_node(^"Launch")
		var content: Control = launch.get_node(^"Content")
		var padding := content.offset_top - content.offset_bottom
		var height := maxf(_row_minimum(), content.get_combined_minimum_size().y + padding)
		row.custom_minimum_size = Vector2(0, height)
		launch.custom_minimum_size = Vector2(0, height)
	_layout_panel()

## Measures the name at the width it has without the full-name action, so
## showing that action never feeds back into the decision.
func _needs_full_name(row: Control) -> bool:
	var title: Label = row.get_node(^"Launch/Content/Copy/Title")
	var content: Control = row.get_node(^"Launch/Content")
	var width := row.size.x - content.offset_left + content.offset_right
	var row_gap := row.get_theme_constant(&"separation")
	for path in [^"Use", ^"Favorite"]:
		var action: Control = row.get_node(path)
		if action.visible:
			width -= action.get_combined_minimum_size().x + row_gap
	var gap := content.get_theme_constant(&"separation")
	for path in [^"Icon", ^"Value"]:
		var part: Control = content.get_node(path)
		if part.visible:
			width -= part.get_combined_minimum_size().x + gap
	if width <= 0.0:
		return not title.text.is_empty()
	var font := title.get_theme_font(&"font")
	var font_size := title.get_theme_font_size(&"font_size")
	var wrapped := font.get_multiline_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, -1,
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
	return roundi(wrapped.y / font.get_height(font_size)) > title.max_lines_visible

func _row_minimum() -> float:
	return get_theme_constant(&"target_minimum", TOKENS) + _space(1 if _phone else 2) * 2

func _rect(control: Control, x: float, y: float, w: float, h: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(0, w), maxf(0, h))

func _layout() -> void:
	if not is_node_ready():
		return
	# Bottom-centre anchoring lets the kit bar size itself from its profile.
	var minimum: Vector2 = _bar.get_combined_minimum_size()
	var gap := _space(4 if _phone else 5)
	_bar.offset_left = -minimum.x / 2
	_bar.offset_right = minimum.x / 2
	_bar.offset_bottom = -gap
	_bar.offset_top = -gap - minimum.y
	_layout_panel()

func _layout_panel() -> void:
	if not is_node_ready():
		return
	var outer := _space(2)
	var width: float = minf(PHONE_PANEL_WIDTH if _phone else PANEL_WIDTH, size.x - outer * 2)
	var pad := _space(3 if _phone else 4)
	var top := _space(1)
	var bottom := _space(1 if _phone else 2)
	_content.offset_left = pad
	_content.offset_right = -pad
	_content.offset_top = top
	_content.offset_bottom = -bottom
	var inner := width - pad * 2
	var detail_area: Control = get_node(CONTENT + "Detail")
	if detail_area.visible:
		var detail: Label = detail_area.get_node(^"Text")
		var lines := PHONE_DETAIL_LINES if _phone else DETAIL_LINES
		detail.size = Vector2(inner, detail.size.y)
		var count := detail.get_line_count()
		var pages := maxi(1, ceili(float(count) / lines))
		_detail_page = clampi(_detail_page, 0, pages - 1)
		get_node(CONTENT + "Footer").visible = pages > 1
		get_node(CONTENT + "Footer/Page").text = "%s / %s" % [_detail_page + 1, pages]
		get_node(CONTENT + "Footer/Previous").disabled = _detail_page == 0
		get_node(CONTENT + "Footer/Next").disabled = _detail_page == pages - 1
		var pitch := _line_pitch(detail)
		detail_area.custom_minimum_size = Vector2(0, mini(lines, count - _detail_page * lines) * pitch)
		_rect(detail, 0, -_detail_page * lines * pitch, inner, count * pitch)
	get_node(CONTENT + "Empty").custom_minimum_size = Vector2(0, _row_minimum())
	_panel.hinge_gap = float(_space(3 if _phone else 5))
	_panel.hinge_inset = float(_space(6 if _phone else 7))
	var height: float = _content.get_combined_minimum_size().y + top + bottom
	# The list folds out above its category lane, or above the bar when the lane overflowed.
	var hud := get_global_rect()
	var bar: Rect2 = _bar.get_global_rect()
	var slot: Control = _bar.get_category_slot()
	var lane := slot.get_global_rect() if slot.is_visible_in_tree() else bar
	var x := clampf(lane.get_center().x - hud.position.x - width / 2, outer, maxf(outer, size.x - width - outer))
	var room: float = bar.position.y - hud.position.y - _panel.hinge_gap
	var y := maxf(0.0, room - height)
	_rect(_panel, x, y, width, height)
	# Rows grow with the theme's type scale and the bar with its content, so a
	# short canvas shows fewer entries on a page instead of covering the bar.
	var step := _list.columns
	var listing: bool = _list.visible and not get_node(CONTENT + "Detail").visible
	if _panel.is_open and listing and height > room + _panel.hinge_gap and _page_size > step and not _refit_pending:
		_refit_pending = true
		_row_limit = _page_size - step
		_refit.call_deferred()

func _refit() -> void:
	_refit_pending = false
	_render_panel()

func _render_panel() -> void:
	pass

## Distance between the tops of two wrapped lines of a Label.
func _line_pitch(label: Label) -> int:
	return label.get_line_height() + label.get_theme_constant(&"line_spacing")

func _style() -> void:
	# A phone steps the heading one role down instead of shrinking pixels.
	get_node(CONTENT + "Header/Title").theme_type_variation = &"RookframeBody" if _phone else &"RookframeHeading"
