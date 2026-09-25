extends BoxContainer
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const CHOICE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/catalogue_choice.tscn")
const CORE := ["aland-wickhead", "arbint-troll", "belze-skeleton", "bent-scum", "eulotha-wyvern", "lady-porcelain", "lich-necromancer", "nodh-zombie", "seth-goblin", "thinx-grotesque", "wrat-wraith", "zukuma-berserker"]
signal selected(entry: SDK.ContentEntry)
var _entries: Array[SDK.ContentEntry] = []
var _selected_id := ""
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/catalogue_choice.gd")
var _rows: Array[ROW] = []

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
			row.tooltip_text = entry.title
			row.theme_type_variation = "RookframeChoiceRow"
			row.custom_minimum_size = Vector2(0, 52)
			row.size_flags_horizontal = 3
			row.alignment = 0
			row.toggle_mode = true
			row.navigation.connect(_row_navigation.bind(_rows.size()))
			row.pressed.connect(_select.bind(entry))
			get_node("List/Content/DefinitionList").add_child(row)
			_rows.append(row)
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
	for index in range(_rows.size()):
		var row := _rows[index]
		var chosen := _entries[index].reference.local_id == _selected_id
		row.set_selected(chosen)
		row.focus_mode = 2 if chosen else 1
	_refresh_tab_stop()
	var definition: Dictionary = CREATURES.CORE_DEFINITIONS[_selected_id]
	(get_node("Preview/Identity/Content/Title") as Label).text = entry.title.to_upper()
	(get_node("Preview/Identity/Content/Portrait") as Control).visible = _selected_id == "seth-goblin"
	(get_node("Preview/Stats/HitPoints/Content/Value") as Label).text = str(definition.hit_points)
	var morale: Dictionary = definition.morale
	(get_node("Preview/Stats/Morale/Content/Value") as Label).text = str(morale.value) if morale.kind == "fixed" else ("Special" if morale.kind == "special" else "—")
	var attacks := ""
	for raw in definition.attacks:
		var attack: Dictionary = raw
		attacks += ("\n\n" if not attacks.is_empty() else "") + str(attack.name) + " · " + str(attack.dice)
	(get_node("Preview/Attacks/Content/Copy") as Label).text = attacks
	if notify:
		selected.emit(entry)

func filter(query: String) -> void:
	query = query.strip_edges().to_lower()
	for index in range(_rows.size()):
		_rows[index].visible = query.is_empty() or _entries[index].title.to_lower().contains(query)
	_refresh_tab_stop()

func _arrange() -> void:
	vertical = size.x < 640

func _row_navigation(direction: int, boundary: bool, current: int) -> void:
	var available: Array[int] = []
	var position := 0
	for index in range(_rows.size()):
		if _rows[index].visible and not _rows[index].disabled:
			if index == current:
				position = available.size()
			available.append(index)
	if available.is_empty():
		return
	if boundary:
		position = 0 if direction == 0 else available.size() - 1
	else:
		position = (position + direction + available.size()) % available.size()
	var next := available[position]
	_select(_entries[next])
	_rows[next].grab_focus()

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
