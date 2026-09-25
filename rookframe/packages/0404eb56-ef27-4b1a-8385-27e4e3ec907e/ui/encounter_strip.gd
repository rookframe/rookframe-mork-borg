extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_strip_base.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const VIEW = preload(ROOT + "ui/encounter_view.gd")
const CARD = preload(ROOT + "ui/encounter_entry.tscn")
const GROUP = preload(ROOT + "ui/encounter_group.tscn")
const STRIP = preload(ROOT + "ui/encounter_strip_base.gd")
const TOKENS = preload("res://rookframe/ui/tokens.gd")
const LOCAL_GROUP := "mork-borg-0404eb56-encounter-view"
var _rows: Array = []
var _cards: Array = []

func ready() -> void:
	var previous = get_tree().get_first_node_in_group(LOCAL_GROUP) as STRIP
	if previous != null:
		_local = previous.encounter_view_state()
	add_to_group(LOCAL_GROUP)
	resized.connect(_layout)
	if sdk == null:
		return
	sdk.world_changed.connect(refresh)
	_local.updated.connect(_local_changed)
	get_node(^"Panel/Layout/Round").pressed.connect(_options)
	refresh()

func refresh() -> void:
	if sdk == null:
		return
	var state: Dictionary = VIEW.new().snapshot(sdk)
	get_node(^"Panel").visible = not state.has("error") and bool(state.get("active", false))
	if not get_node(^"Panel").visible:
		_rows = []
		return
	var round_button: Button = get_node(^"Panel/Layout/Round")
	round_button.text = str(state.round)
	round_button.disabled = not state.is_gm
	round_button.tooltip_text = "Round %d" % int(state.round)
	round_button.accessibility_name = "Encounter options, round %d" % int(state.round) if state.is_gm else round_button.tooltip_text
	var entries := get_node(^"Panel/Layout/Scroll/Groups")
	var rows: Array = state.rows
	if rows != _rows:
		_rows = rows.duplicate(true)
		_cards.clear()
		for child in entries.get_children():
			entries.remove_child(child)
			child.queue_free()
		var group: Control
		var side := ""
		for raw_row in rows:
			var row: Dictionary = raw_row
			if str(row.side) != side:
				side = str(row.side)
				group = GROUP.instantiate()
				entries.add_child(group)
				var label := group.get_node("Side") as Label
				label.text = "Players" if side == "pc" else "Monsters"
				label.add_theme_color_override("font_color", TOKENS.COLOR_ACCENT if row.active else TOKENS.COLOR_CONTENT_MUTED)
				group.get_node("Rule").color = TOKENS.COLOR_ACCENT if row.active else TOKENS.COLOR_RULE
			var card: Button = CARD.instantiate()
			_cards.append(card)
			group.get_node("Entries").add_child(card)
			card.name = str(row.rook)
			card.custom_minimum_size = Vector2(60, 64) if sdk.presentation_experience().is_phone else Vector2(88, 80)
			VIEW.new().show_preview(sdk, card.get_node("Image") as Control, row)
			card.tooltip_text = str(row.label)
			card.accessibility_name = str(row.label) + (", active side" if row.active else "")
			card.pressed.connect(_open.bind(str(row.rook)))
	_local_changed()

func _local_changed() -> void:
	for card in _cards:
		card.set_pressed_no_signal(str(card.name) == _local.selected_rook)
	_layout()

func _layout() -> void:
	if sdk == null:
		return
	var panel: Control = get_node(^"Panel")
	var phone := sdk.presentation_experience().is_phone
	var tablet := sdk.presentation_experience().is_tablet
	var round_width: float = get_node(^"Panel/Layout/Round").size.x
	var width := minf(720, 104 + maxf(0, round_width - 44) + _rows.size() * (76 if phone else 92))
	var x := (size.x - width) / 2
	if _local.panel_visible and (phone or tablet):
		var bounds := _local.panel_rect
		var origin := get_global_rect().position.x
		var before := maxf(0, bounds.position.x - origin - 68)
		var after := maxf(0, size.x - (bounds.end.x - origin) - 12)
		width = minf(width, maxf(144, maxf(before, after)))
		x = 68 if before >= after else bounds.end.x - origin + 8
	else:
		width = minf(width, maxf(144, size.x - 144))
		x = (size.x - width) / 2
	panel.position = Vector2(x, 52 if phone else 20)
	panel.size = Vector2(width, panel.size.y)

func _open(rook: String) -> void:
	if sdk.context().is_gm:
		_local.select_rook(rook)
		sdk.windows.open(VIEW.new().surface(sdk))
	_local_changed()

func _options() -> void:
	if not sdk.context().is_gm:
		return
	_local.show_options()
	sdk.windows.open(VIEW.new().surface(sdk))
