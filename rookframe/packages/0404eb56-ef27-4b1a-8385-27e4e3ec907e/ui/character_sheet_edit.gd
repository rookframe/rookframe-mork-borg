extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
const RULES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_rules.gd")
const FIELD_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field.gd")
var _fields: Array[FIELD_SCRIPT] = []
var _trait_ids: Array[String] = []
const FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field.tscn")
func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)
func configure(data: Dictionary, _miniatures: Array) -> void:
	for entry in [["name", "Name"], ["description", "Description"], ["maximum_hit_points", "Maximum HP"], ["class_title", "Class"], ["origin", "Origin"], ["pack", "Pack"], ["power_uses", "Power uses remaining"]]:
		_add(entry[0], entry[1], str(data.get(entry[0], 0 if entry[0] == "power_uses" else "")))
	_add("improvements", "Improvements begun", str(data.get("improvements", 0)))
	if str(data.get("class_id", "")) == "gutterborn-scum":
		_add("scum_specialty:0", "First specialty (1–6)", _specialty_value(data, 0))
		_add("scum_specialty:1", "Second specialty (1–6; 0 = none)", _specialty_value(data, 1))
	var rules: Array = data.get("class_rules", [])
	var rule_text := ""
	for rule in rules:
		rule_text += ("\n" if not rule_text.is_empty() else "") + str(rule)
	_add("class_rules", "Class rules (one per line)", rule_text)
	_trait_ids = _current_trait_ids(data)
	_add_entries(data, "traits")
	_add_entries(data, "companion_sheets")

func _add_entries(data: Dictionary, key: String, only_index: int = -1) -> void:
	var entries: Array = data.get(key, [])
	for index in range(entries.size()):
		if only_index >= 0 and index != only_index:
			continue
		var entry: Dictionary = entries[index]
		var prefix := "trait" if key == "traits" else "companion"
		_add("%s:%d:name" % [prefix, index], ("Trait" if key == "traits" else "Companion") + " name", str(entry.get("name", "")))
		var rule := RULES.new().definition(str(entry.get("id", "")))
		if key == "traits" and rule.has("uses") and not entry.has("item"):
			var default_uses: int = rule.get("uses", 0)
			var uses: int = entry.get("uses", default_uses)
			_add("trait:%d:uses" % index, str(entry.get("name", "")) + " remaining uses", str(uses))
		_add("%s:%d:rules" % [prefix, index], str(entry.get("name", "")) + " rules", str(entry.get("rules", "")))

func _add(key: String, title: String, value: String) -> void:
	var field = FIELD.instantiate()
	get_node(^"Fields").add_child(field)
	field.configure(key, title, value)
	_fields.append(field)
	field.save_requested.connect(_save_field)

func _back() -> void:
	navigate_requested.emit("character", "")

func _save_field(name: String, text: String) -> void:
	mutation_requested.emit("correct", [name, text])

func field_result(key: String, message: String, error: bool) -> void:
	for field in _fields:
		if str(field.field) == key:
			field.show_result(message, error, not error)

func refresh_data(data: Dictionary) -> void:
	var ids := _current_trait_ids(data)
	if ids != _trait_ids:
		var previous := _trait_ids
		_trait_ids = ids
		var retained: Array[FIELD_SCRIPT] = []
		for field in _fields:
			var changed := false
			var key: String = field.field
			if key.begins_with("trait:"):
				var parts := key.split(":")
				var slot := int(parts[1])
				changed = slot >= ids.size() or slot >= previous.size() or ids[slot] != previous[slot]
			if changed:
				get_node(^"Fields").remove_child(field)
				field.queue_free()
			else:
				retained.append(field)
		_fields = retained
		for slot in range(ids.size()):
			if slot >= previous.size() or ids[slot] != previous[slot]:
				_add_entries(data, "traits", slot)
	for field in _fields:
		var key: String = field.field
		var value := str(data.get(key, ""))
		if key.begins_with("scum_specialty:"):
			value = _specialty_value(data, 0 if key == "scum_specialty:0" else 1)
		elif key == "class_rules":
			value = ""
			var rules: Array = data.get(key, [])
			for rule in rules:
				value += ("\n" if not value.is_empty() else "") + str(rule)
		elif key.begins_with("trait:") or key.begins_with("companion:"):
			var parts := key.split(":")
			var entries: Array = data.get("traits" if parts[0] == "trait" else "companion_sheets", [])
			if int(parts[1]) >= entries.size():
				continue
			var entry: Dictionary = entries[int(parts[1])]
			value = str(entry.get(parts[2], ""))
		field.refresh_value(value)

func _specialty_value(data: Dictionary, slot: int) -> String:
	var traits: Array = data.get("traits", [])
	if slot >= traits.size():
		return "0"
	var entry: Dictionary = traits[slot]
	for face in range(1, 7):
		var feature := CLASSES.new().feature("gutterborn-scum", face)
		if str(feature.id) == str(entry.get("id", "")):
			return str(face)
	return "0"

func _current_trait_ids(data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var traits: Array = data.get("traits", [])
	for raw in traits:
		var entry: Dictionary = raw
		result.append(str(entry.get("id", "")))
	return result
