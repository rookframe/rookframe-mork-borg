extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_field.tscn")
var _id := ""
var _new := false
var _fields: Array = []
func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)
	get_node(^"Remove").pressed.connect(_remove)
	get_node(^"Create").pressed.connect(_create)
func configure(item: Dictionary, _miniatures: Array) -> void:
	_new = item.is_empty()
	_id = str(item.get("inventory_id", ""))
	get_node(^"Title").text = "CUSTOM ITEM" if _new else str(item.get("name", "Item"))
	get_node(^"Rules").text = str(item.get("rules", ""))
	get_node(^"Remove").visible = not _new
	get_node(^"Create").visible = _new
	for key in ["name", "quantity", "uses"]:
		if key == "uses" and item.has("dose_pool"):
			continue
		_add(key, str(item.get(key, 1 if key == "quantity" else "" if key == "name" else 0)))
	var custom: bool = item.get("custom", false)
	if _new or custom:
		for key in ["kind", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			_add(key, str(item.get(key, "Equipment" if key == "kind" else 0 if key in ["range_feet", "armor_tier"] else "")))
func _add(key: String, value: String) -> void:
	var field = FIELD.instantiate()
	get_node(^"Fields").add_child(field)
	field.configure(key, {"name": "Name", "quantity": "Quantity", "uses": "Uses", "kind": "Kind", "damage": "Damage", "range_feet": "Range (feet)", "armor_tier": "Armor tier", "reduction": "Reduction", "rules": "Rules"}.get(key, key), value)
	field.save_requested.connect(_save_field)
	if _new:
		field.get_node(^"Actions").visible = false
	_fields.append(field)
func _create() -> void:
	var fields: Dictionary = {}
	for field in _fields:
		fields[str(field.field)] = field.current_value()
	mutation_requested.emit("custom", [fields])

func _back() -> void:
	navigate_requested.emit("inventory", "")

func _remove() -> void:
	mutation_requested.emit("remove", [_id])

func _save_field(name: String, text: String) -> void:
	mutation_requested.emit("item", [_id, name, text])

func field_result(key: String, message: String, error: bool) -> void:
	for field in _fields:
		if str(field.field) == key:
			field.show_result(message, error, not error)

func show_missing() -> void:
	get_node(^"Title").text = "Item unavailable"
	get_node(^"Rules").text = "This item was removed. Return to Inventory to see the current items."
	get_node(^"Remove").visible = false
	get_node(^"Create").visible = false

func refresh_data(data: Dictionary) -> void:
	if _new:
		return
	var items: Array = data.get("inventory", [])
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) != _id:
			continue
		for field in _fields:
			field.refresh_value(str(item.get(str(field.field), "")))
		return
	show_missing()
	get_node(^"Fields").visible = false
