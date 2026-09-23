extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const FIELD_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field.gd")
var _fields: Array[FIELD_SCRIPT] = []
const FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field.tscn")
func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)
func configure(data: Dictionary, _miniatures: Array) -> void:
	for entry in [["name", "Name"], ["description", "Description"], ["maximum_hit_points", "Maximum HP"], ["class_title", "Class"], ["origin", "Origin"], ["pack", "Pack"], ["power_uses", "Power uses remaining"]]:
		_add(entry[0], entry[1], str(data.get(entry[0], 0 if entry[0] == "power_uses" else "")))
	var rules: Array = data.get("class_rules", [])
	var rule_text := ""
	for rule in rules:
		rule_text += ("\n" if not rule_text.is_empty() else "") + str(rule)
	_add("class_rules", "Class rules (one per line)", rule_text)
	for key in ["traits", "companion_sheets"]:
		var entries: Array = data.get(key, [])
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			var prefix := "trait" if key == "traits" else "companion"
			_add("%s:%d:name" % [prefix, index], ("Trait" if key == "traits" else "Companion") + " name", str(entry.get("name", "")))
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
	for field in _fields:
		var key: String = field.field
		var value := str(data.get(key, ""))
		if key == "class_rules":
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
