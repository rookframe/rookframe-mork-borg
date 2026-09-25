extends BoxContainer
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const CHOICE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/catalogue_choice.tscn")
const CORE := ["aland-wickhead", "arbint-troll", "belze-skeleton", "bent-scum", "eulotha-wyvern", "lady-porcelain", "lich-necromancer", "nodh-zombie", "seth-goblin", "thinx-grotesque", "wrat-wraith", "zukuma-berserker"]
signal selected(entry: SDK.ContentEntry)
var _entries: Array[SDK.ContentEntry] = []
var _selected_id := ""
var _rows: Array[Button] = []

func _ready() -> void:
	resized.connect(_arrange)
	_arrange()

func configure(entries: Array[SDK.ContentEntry], selected_id: String = "") -> void:
	var current: Array[SDK.ContentEntry] = []
	for entry in entries:
		if CORE.has(entry.reference.local_id):
			current.append(entry)
	var unchanged := current.size() == _entries.size()
	for index in range(current.size()):
		if index >= _entries.size() or current[index].reference.local_id != _entries[index].reference.local_id:
			unchanged = false
	_entries = current
	if not unchanged:
		for row in _rows:
			row.get_parent().remove_child(row)
			row.queue_free()
		_rows.clear()
		for entry in _entries:
			var row := CHOICE.instantiate()
			row.title = entry.title
			row.variant = 1
			row.description = ""
			row.tooltip_text = entry.title
			row.set_meta("definition_id", entry.reference.local_id)
			row.set_meta("definition_title", entry.title)
			row.theme_type_variation = "RookframeChoiceRow"
			row.custom_minimum_size = Vector2(0, 52)
			row.size_flags_horizontal = 3
			row.alignment = 0
			row.toggle_mode = true
			row.gui_input.connect(_row_input.bind(row))
			row.pressed.connect(_select.bind(entry))
			get_node("List/Content/DefinitionList").add_child(row)
			_rows.append(row)
			row.get_node("Content/Copy/Title").minimum_size_changed.connect(_fit_row.bind(row))
			_fit_row(row)
	var wanted := selected_id if not selected_id.is_empty() else (_selected_id if not _selected_id.is_empty() else "seth-goblin")
	for entry in _entries:
		if entry.reference.local_id == wanted:
			_select(entry, false)
			return
	if not _entries.is_empty():
		_select(_entries[0], false)

func selection() -> SDK.ContentEntry:
	for entry in _entries:
		if entry.reference.local_id == _selected_id:
			return entry
	return null

func _select(entry: SDK.ContentEntry, notify: bool = true) -> void:
	_selected_id = entry.reference.local_id
	for row in _rows:
		var chosen := str(row.get_meta("definition_id")) == _selected_id
		row.set_selected(chosen)
		row.get_node("Content/IndicatorLane/Indicator").modulate.a = 1.0 if chosen else 0.0
		row.focus_mode = 2 if chosen else 1
	_refresh_tab_stop()
	var definition: Dictionary = CREATURES.CORE_DEFINITIONS[_selected_id]
	(get_node("Preview/Identity/Content/Title") as Label).text = entry.title.to_upper()
	(get_node("Preview/Identity/Content/Portrait") as Control).visible = _selected_id == "seth-goblin"
	(get_node("Preview/Stats/HitPoints/Content/Value") as Label).text = str(definition.hit_points)
	var morale: Dictionary = definition.morale
	(get_node("Preview/Stats/Morale/Content/Value") as Label).text = str(morale.value) if morale.kind == "fixed" else ("Special" if morale.kind == "special" else "—")
	var attacks := PackedStringArray()
	for raw in definition.attacks:
		var attack: Dictionary = raw
		attacks.append(str(attack.name) + " · " + str(attack.dice))
	(get_node("Preview/Attacks/Content/Copy") as Label).text = "\n\n".join(attacks)
	if notify:
		selected.emit(entry)

func filter(query: String) -> void:
	query = query.strip_edges().to_lower()
	for row in _rows:
		row.visible = query.is_empty() or str(row.get_meta("definition_title")).to_lower().contains(query)
	_refresh_tab_stop()

func _arrange() -> void:
	vertical = size.x < 640

func _fit_row(row: Button) -> void:
	row.custom_minimum_size.y = maxf(52, row.get_node("Content/Copy/Title").get_minimum_size().y + 24)

func _row_input(event: InputEvent, row: Button) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var available: Array[Button] = []
	for candidate in _rows:
		if candidate.visible and not candidate.disabled:
			available.append(candidate)
	if available.is_empty():
		return
	var index := available.find(row)
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		index = (index + 1) % available.size()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		index = (index - 1 + available.size()) % available.size()
	elif event.keycode == KEY_HOME:
		index = 0
	elif event.keycode == KEY_END:
		index = available.size() - 1
	else:
		return
	var next := available[index]
	for entry in _entries:
		if entry.reference.local_id == str(next.get_meta("definition_id")):
			_select(entry)
			next.grab_focus()
			row.accept_event()
			return

func _refresh_tab_stop() -> void:
	var tab_stop: Button
	for row in _rows:
		if row.visible and not row.disabled:
			if tab_stop == null:
				tab_stop = row
			if row.button_pressed:
				tab_stop = row
				break
	for row in _rows:
		row.focus_mode = 2 if row == tab_stop else 1
