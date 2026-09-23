extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.tscn")
const DIVIDER = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_divider.tscn")
func _ready() -> void:
	get_node(^"Toolbar/Add").pressed.connect(_add_item)
	resized.connect(_layout)
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
		var target: NodePath = ^"EquippedSection/Content/Items" if equipped else ^"CarriedSection/Content/Items"
		if get_node(target).get_child_count() > 0:
			get_node(target).add_child(DIVIDER.instantiate())
		get_node(target).add_child(row)
		row.configure(item, false, read_only)
		row.mutation_requested.connect(_mutation)
		row.navigate_requested.connect(_navigate)
	get_node(^"EquippedSection").visible = get_node(^"EquippedSection/Content/Items").get_child_count() > 0
	get_node(^"CarriedSection").visible = get_node(^"CarriedSection/Content/Items").get_child_count() > 0
	_layout()

func _add_item() -> void:
	navigate_requested.emit("catalogue", "")

func _mutation(operation: String, arguments: Array) -> void:
	mutation_requested.emit(operation, arguments)

func _navigate(route: String, id: String) -> void:
	navigate_requested.emit(route, id)

func _layout() -> void:
	var variant := "RookframePackageInk" if size.x < 600 else "RookframeSection"
	get_node(^"EquippedSection").theme_type_variation = variant
	get_node(^"CarriedSection").theme_type_variation = variant
