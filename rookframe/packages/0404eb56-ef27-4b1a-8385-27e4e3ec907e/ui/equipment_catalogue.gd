extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const EQUIPMENT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/equipment.gd")
const ROW_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.gd")
var _rows: Array[ROW_SCRIPT] = []
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.tscn")
func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)
	get_node(^"Custom").pressed.connect(_custom)
	get_node(^"Search").value_changed.connect(_filter)
func configure(_data: Dictionary, _miniatures: Array) -> void:
	for item in EQUIPMENT.new().entries():
		var row = ROW.instantiate()
		get_node(^"Items").add_child(row)
		row.configure(item, true)
		_rows.append(row)
		row.mutation_requested.connect(_add)
	_filter("")
func _filter(query: String) -> void:
	var count := 0
	for row in _rows:
		var item: Dictionary = row.item
		row.visible = query.to_lower() in str(item.get("name", "")).to_lower()
		if row.visible:
			count += 1
	get_node(^"Empty").visible = count == 0

func _back() -> void:
	navigate_requested.emit("inventory", "")

func _custom() -> void:
	navigate_requested.emit("custom", "")

func _add(operation: String, arguments: Array) -> void:
	mutation_requested.emit(operation, arguments)
