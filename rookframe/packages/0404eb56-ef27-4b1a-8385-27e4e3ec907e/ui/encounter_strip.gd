extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_strip_base.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const VIEW = preload(ROOT + "ui/encounter_view.gd")
const CARD = preload(ROOT + "ui/encounter_entry.tscn")
const GROUP = preload(ROOT + "ui/encounter_group.tscn")
const STRIP = preload(ROOT + "ui/encounter_strip_base.gd")
const LOCAL_GROUP := "mork-borg-0404eb56-encounter-view"
var _rows: Array = []
var _cards: Array = []

func ready() -> void:
	i18n.bind(sdk)
	localize(i18n)
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
	round_button.visible = bool(state.is_gm)
	var round_label: Label = get_node(^"Panel/Layout/RoundLabel")
	round_label.text = round_button.text
	round_label.visible = not state.is_gm
	round_button.tooltip_text = _t("Round %d") % int(state.round)
	round_label.accessibility_name = round_button.tooltip_text
	round_button.accessibility_name = _t("Encounter options, round %d") % int(state.round) if state.is_gm else round_button.tooltip_text
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
				i18n.encounter_group(group)
				entries.add_child(group)
				var label := group.get_node("Side") as Label
				label.text = _t("Players") if side == "pc" else _t("Monsters")
				var active_label := group.get_node("ActiveSide") as Label
				active_label.text = label.text
				label.visible = not row.active
				active_label.visible = bool(row.active)
				var rule := group.get_node("Rule") as Control
				var active_rule := group.get_node("ActiveRule") as Control
				rule.visible = not row.active
				active_rule.visible = bool(row.active)
			var card: Button = CARD.instantiate()
			i18n.encounter_entry(card)
			_cards.append(card)
			group.get_node("Entries").add_child(card)
			card.name = str(row.rook)
			VIEW.new().show_preview(sdk, card.get_node("Image") as Control, row)
			card.tooltip_text = str(row.label)
			card.accessibility_name = str(row.label) + (_t(", active side") if row.active else "")
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
	for entry in _cards:
		var card := entry as Control
		card.custom_minimum_size = Vector2(72, 64) if phone else Vector2(88, 80)
	var round_node: Control = get_node(^"Panel/Layout/Round") if sdk.context().is_gm else get_node(^"Panel/Layout/RoundLabel")
	var round_width: float = round_node.size.x
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
	panel.size = Vector2(width, 0)

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


func localize(locale: I18N) -> void:
	i18n = locale
	get_node(^"Panel/Layout/Round").tooltip_text = _t("Round")
