extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const VIEW = preload(ROOT + "ui/encounter_view.gd")
const CARD = preload(ROOT + "ui/encounter_entry.tscn")
const GROUP = preload(ROOT + "ui/encounter_group.tscn")
const LOCAL = preload(ROOT + "ui/encounter_local.tres")
var _rows: Array = []

func ready() -> void:
	resized.connect(_layout)
	if sdk == null:
		return
	sdk.world_changed.connect(refresh)
	LOCAL.updated.connect(refresh)
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
				label.theme_type_variation = "RookframeStatus" if row.active else "RookframeMeta"
			var card: Button = CARD.instantiate()
			group.get_node("Entries").add_child(card)
			card.name = str(row.rook)
			card.custom_minimum_size = Vector2(60, 64) if sdk.presentation_experience().is_phone else Vector2(88, 80)
			VIEW.new().show_preview(sdk, card.get_node("Image"), row)
			card.tooltip_text = str(row.label)
			card.accessibility_name = str(row.label) + (", active side" if row.active else "")
			card.pressed.connect(_open.bind(str(row.rook)))
	for group in entries.get_children():
		for card in group.get_node("Entries").get_children():
			for raw in rows:
				var row: Dictionary = raw
				if str(card.name) == str(row.rook):
					card.set_pressed_no_signal(bool(row.active))
	_layout()

func _layout() -> void:
	if sdk == null:
		return
	var panel: Control = get_node(^"Panel")
	var phone := sdk.presentation_experience().is_phone
	var tablet := sdk.presentation_experience().is_tablet
	var width := minf(720, 72 + _rows.size() * (76 if phone else 92))
	var x := (size.x - width) / 2
	if LOCAL.panel_visible and (phone or tablet):
		var bounds := LOCAL.panel_rect
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
		LOCAL.select_rook(rook)
		sdk.windows.open(VIEW.new().surface(sdk))
	refresh()

func _options() -> void:
	if not sdk.context().is_gm:
		return
	LOCAL.show_options()
	sdk.windows.open(VIEW.new().surface(sdk))
