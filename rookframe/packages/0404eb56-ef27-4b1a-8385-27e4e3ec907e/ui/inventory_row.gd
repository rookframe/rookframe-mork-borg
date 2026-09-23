extends HBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
var equipped := false
var item: Dictionary = {}
func configure(value: Dictionary, catalogue: bool = false, read_only: bool = false) -> void:
	for path in [^"Actions/Attack", ^"Actions/Edit", ^"Actions/Equip", ^"Actions/Add"]:
		get_node(path).disabled = read_only
	item = value
	equipped = item.get("equipped", false)
	get_node(^"Copy/Title").text = str(item.get("name", "Item"))
	var details: Array[String] = []
	if item.has("damage"):
		details.append(str(item.damage) + " damage")
	if item.has("range_feet"):
		details.append(str(item.range_feet) + " ft")
	if item.has("armor_tier"):
		details.append("Tier " + str(item.armor_tier) + " · −" + str(item.get("reduction", "")))
	if item.has("quantity"):
		details.append("Quantity " + str(item.quantity))
	if item.has("uses"):
		details.append(str(item.uses) + " uses")
	var detail_text := ""
	for detail in details:
		detail_text += (" · " if not detail_text.is_empty() else "") + str(detail)
	get_node(^"Copy/Details").text = detail_text
	get_node(^"Actions/Add").visible = catalogue
	get_node(^"Actions/Edit").visible = not catalogue
	get_node(^"Actions/Equip").visible = not catalogue and str(item.get("kind", "")) in ["Weapon", "Armor", "Shield"]
	get_node(^"Actions/Equip").text = "Unequip" if equipped else "Equip"
	get_node(^"Actions/Attack").visible = not catalogue and equipped and str(item.get("kind", "")) == "Weapon"
	get_node(^"Actions/Attack").pressed.connect(_attack)
	get_node(^"Actions/Edit").pressed.connect(_edit)
	get_node(^"Actions/Equip").pressed.connect(_equip)
	get_node(^"Actions/Add").pressed.connect(_add)

func _attack() -> void:
	navigate_requested.emit("attack", str(item.get("inventory_id", "")))

func _edit() -> void:
	navigate_requested.emit("item", str(item.get("inventory_id", "")))

func _equip() -> void:
	mutation_requested.emit("item", [str(item.get("inventory_id", "")), "equipped", "false" if equipped else "true"])

func _add() -> void:
	mutation_requested.emit("add", [str(item.get("source_item_id", ""))])
