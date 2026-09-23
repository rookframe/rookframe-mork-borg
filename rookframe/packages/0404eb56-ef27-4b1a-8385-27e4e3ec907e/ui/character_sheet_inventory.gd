extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.tscn")
func _ready() -> void:
	get_node(^"Toolbar/Add").pressed.connect(_add_item)
func configure(data: Dictionary, _miniatures: Array) -> void:
	var read_only: bool = data.get("read_only", false)
	get_node(^"Toolbar/Add").disabled = read_only
	var inventory: Array = data.get("inventory", [])
	get_node(^"Toolbar/Count").text = "%d items · %s silver" % [inventory.size(), str(data.get("silver", 0))]
	get_node(^"Empty").visible = inventory.is_empty()
	for raw in inventory:
		var item: Dictionary = raw
		var row = ROW.instantiate()
		var equipped: bool = item.get("equipped", false)
		var target: NodePath = ^"Equipped" if equipped else ^"Carried"
		get_node(target).add_child(row)
		row.configure(item, false, read_only)
		row.mutation_requested.connect(_mutation)
		row.navigate_requested.connect(_navigate)
	get_node(^"EquippedHeading").visible = get_node(^"Equipped").get_child_count() > 0
	get_node(^"CarriedHeading").visible = get_node(^"Carried").get_child_count() > 0

func _add_item() -> void:
	navigate_requested.emit("catalogue", "")

func _mutation(operation: String, arguments: Array) -> void:
	mutation_requested.emit(operation, arguments)

func _navigate(route: String, id: String) -> void:
	navigate_requested.emit(route, id)
