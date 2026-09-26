extends HBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const POWERS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/powers.gd")
const SPECIAL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_rules.gd")
var equipped := false
var item: Dictionary = {}
func _ready() -> void:
	resized.connect(_layout)
func configure(value: Dictionary, catalogue: bool = false, read_only: bool = false, can_cast: bool = true) -> void:
	for path in [^"Actions/Attack", ^"Actions/Edit", ^"Actions/Equip", ^"Actions/Add"]:
		get_node(path).disabled = read_only
	item = value
	equipped = item.get("equipped", false)
	get_node(^"Copy/Title").text = (str(item.get("name", "Item")) if item.get("custom", false) else _t(str(item.get("name", "Item"))))
	var details: Array[String] = []
	var broken: bool = item.get("broken", false)
	if broken:
		details.append(_t("Broken"))
		get_node(^"Actions/Attack").disabled = true
	if item.has("damage"):
		details.append(str(item.damage))
	if item.has("range_feet"):
		details.append(str(item.range_feet) + _t(" ft"))
	if str(item.get("kind", "")) == "Weapon" and not str(item.get("ammunition", "")).is_empty():
		details.append(_t("1 %s per attack") % _t(str(item.ammunition)))
	if item.has("armor_tier"):
		details.append(_t("Tier ") + str(item.armor_tier) + " · −" + str(item.get("reduction", "")))
	var quantity: int = item.get("quantity", 1)
	if item.has("quantity") and (quantity != 1 or details.is_empty()):
		details.append(_t("Quantity ") + str(item.quantity))
	if item.has("uses"):
		details.append(str(item.uses) + _t(" uses"))
	var detail_text := ""
	for detail in details:
		detail_text += (" · " if not detail_text.is_empty() else "") + str(detail)
	get_node(^"Copy/Details").text = detail_text
	get_node(^"Actions/Add").visible = catalogue
	get_node(^"Actions/Edit").visible = not catalogue
	get_node(^"Actions/Equip").visible = not catalogue and (str(item.get("kind", "")) in ["Weapon", "Armor", "Shield"] or str(item.get("source_item_id", "")) == "stolen-mitre")
	get_node(^"Actions/Equip").text = _t("Unequip") if equipped else _t("Equip")
	get_node(^"Actions/Attack").visible = not catalogue and equipped and str(item.get("kind", "")) == "Weapon"
	var power := POWERS.new().definition(str(item.get("source_item_id", "")))
	if not catalogue and can_cast and not power.is_empty():
		get_node(^"Actions/Attack").visible = true
		get_node(^"Actions/Attack").text = _t("Cast")
		get_node(^"Actions/Attack").disabled = read_only or not power.playable or quantity < 1
		get_node(^"Copy/Details").text += " · " + (_t(str(power.handling)) if power.playable else _t("Not playable yet"))
	if not catalogue and can_cast and str(item.get("kind", "")) != "Weapon" and not SPECIAL.new().definition(str(item.get("source_item_id", ""))).is_empty():
		get_node(^"Actions/Attack").visible = true
		get_node(^"Actions/Attack").text = _t("Use")
		get_node(^"Actions/Attack").disabled = read_only or quantity < 1 or broken
	get_node(^"Actions/Attack").pressed.connect(_attack)
	get_node(^"Actions/Edit").pressed.connect(_edit)
	get_node(^"Actions/Equip").pressed.connect(_equip)
	get_node(^"Actions/Add").pressed.connect(_add)
	_layout()

func _attack() -> void:
	if str(item.get("kind", "")) != "Weapon" and not SPECIAL.new().definition(str(item.get("source_item_id", ""))).is_empty():
		navigate_requested.emit("use-item", str(item.get("inventory_id", "")))
		return
	navigate_requested.emit("cast" if not POWERS.new().definition(str(item.get("source_item_id", ""))).is_empty() else "attack", str(item.get("inventory_id", "")))

func _edit() -> void:
	navigate_requested.emit("item", str(item.get("inventory_id", "")))

func _equip() -> void:
	mutation_requested.emit("item", [str(item.get("inventory_id", "")), "equipped", "false" if equipped else "true"])

func _add() -> void:
	mutation_requested.emit("add", [str(item.get("source_item_id", ""))])

func _layout() -> void:
	var title: String = item.get("name", "")
	get_node(^"Actions").vertical = size.x < 480 and title.length() > 40


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Actions/Add").text = _t("Add")
	get_node(^"Actions/Attack").text = _t("Attack")
	get_node(^"Actions/Edit").text = _t("Edit")
	get_node(^"Actions/Equip").text = _t("Equip")
	get_node(^"Copy/Title").text = _t("Item")
