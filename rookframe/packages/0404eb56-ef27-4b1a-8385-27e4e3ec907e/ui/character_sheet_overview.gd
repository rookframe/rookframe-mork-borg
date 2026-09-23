extends VBoxContainer

signal companions_requested
signal edit_requested
signal value_save_requested(key: String, value: int)

const CHECK = preload("res://rookframe/ui/icons/check.svg")
var _data: Dictionary = {}
var _editing := ""
var _short_window := false

func _ready() -> void:
	get_node(^"Body/Context/Companions").pressed.connect(_open_companions)
	resized.connect(_layout)
	get_node(^"Body/Context/Identity/Content/Header/Edit").pressed.connect(_edit)
	for resource in ["HitPoints", "Omens", "Silver"]:
		get_node("Resources/" + resource + "/Content/Row/Edit").pressed.connect(_edit_value.bind(resource))
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Edit").pressed.connect(_edit_value.bind(ability))


func configure(data: Dictionary, _miniatures: Array, short_window: bool = false) -> void:
	_short_window = short_window
	_data = data
	get_node(^"Resources/HitPoints/Content/Row/Value").text = "%s / %s" % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
	get_node(^"Resources/Omens/Content/Row/Value").text = str(data.get("omens", 0))
	get_node(^"Resources/Silver/Content/Row/Value").text = str(data.get("silver", 0))
	var abilities: Dictionary = data.get("abilities", {})
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		var value: Dictionary = abilities.get(ability, {})
		var button = get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Modifier")
		var modifier: int = value.get("modifier", 0)
		button.text = "%+d" % modifier
		button.accessibility_name = "%s modifier %s" % [ability, button.text]
	get_node(^"Body/Context/Identity/Content/Description").text = str(data.get("description", ""))
	get_node(^"Body/Context/Identity/Content/Origin").text = str(data.get("class_title", "No Class")) + "\n" + str(data.get("origin", ""))
	var rules := ""
	var class_rules: Array = data.get("class_rules", [])
	for rule in class_rules:
		rules += str(rule) + "\n"
	var traits: Array = data.get("traits", [])
	for raw_trait in traits:
		var trait_data: Dictionary = raw_trait
		rules += str(trait_data.get("name", "")) + "\n" + str(trait_data.get("rules", "")) + "\n"
	get_node(^"Body/Context/Identity/Content/Traits").text = rules.strip_edges()
	var companions: Array = data.get("starting_creature_grants", [])
	get_node(^"Body/Context/Companions").visible = true
	get_node(^"Body/Context/Companions").text = "View companions (%d)" % companions.size()
	var equipped := ""
	var inventory: Array = data.get("inventory", [])
	for entry in inventory:
		var item: Dictionary = entry
		var is_equipped: bool = item.get("equipped", false)
		if is_equipped:
			equipped += ("\n" if not equipped.is_empty() else "") + str(item.get("name", "Item"))
	get_node(^"Body/Context/Combat/Content/Equipment").text = equipped if not equipped.is_empty() else "No equipment equipped."
	_layout()


func _layout() -> void:
	var compact := size.x < 600
	var short := compact and _short_window
	get_node(^"Body").vertical = compact
	get_node(^"Body/Attributes").theme_type_variation = "RookframePackageInk" if short else "RookframeSection"
	get_node(^"Body/Attributes/Content/Heading").visible = not short
	get_node(^"Body/Attributes/Content/Abilities").columns = 2 if short else 1
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		get_node("Body/Attributes/Content/Abilities/" + ability).theme_type_variation = "RookframeSubtleFrame" if short else "RookframePackageInk"
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Title").set("theme_override_font_sizes/font_size", 13 if short else 16)
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content").vertical = short


func _edit() -> void:
	edit_requested.emit()


func _edit_value(key: String) -> void:
	var resource_key: String = {"HitPoints": "hit_points", "Omens": "omens", "Silver": "silver"}.get(key, "")
	var row: Node = get_node("Resources/" + key + "/Content/Row") if not resource_key.is_empty() else get_node("Body/Attributes/Content/Abilities/" + key + "/Padding/Content/Row")
	var input := row.get_node(^"Input") as LineEdit
	if _editing == key:
		if input.text.is_valid_int():
			value_save_requested.emit(resource_key if not resource_key.is_empty() else key, int(input.text))
		return
	if not _editing.is_empty():
		return
	_editing = key
	var value: int = _data.get(resource_key, 0)
	if resource_key.is_empty():
		var abilities: Dictionary = _data.get("abilities", {})
		var ability: Dictionary = abilities.get(key, {})
		value = ability.get("score", 0)
	input.text = str(value)
	input.visible = true
	var display := row.get_node(^"Value" if not resource_key.is_empty() else ^"Modifier") as Control
	display.visible = false
	var edit := row.get_node(^"Edit") as Button
	edit.icon = CHECK


func _open_companions() -> void:
	companions_requested.emit()
