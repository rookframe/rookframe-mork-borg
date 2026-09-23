extends VBoxContainer

signal edit_requested
signal value_save_requested(key: String, value: int)

const CHECK = preload("res://rookframe/ui/icons/check.svg")
var _data: Dictionary = {}
var _editing := ""

func _ready() -> void:
	resized.connect(_layout)
	get_node(^"Body/Context/Identity/Content/Header/Edit").pressed.connect(_edit)
	for resource in ["HitPoints", "Omens", "Silver"]:
		get_node("Resources/" + resource + "/Content/Row/Edit").pressed.connect(_edit_value.bind(resource))
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		get_node("Body/Abilities/" + ability + "/Content/Row/Edit").pressed.connect(_edit_value.bind(ability))


func configure(data: Dictionary, _miniatures: Array) -> void:
	_data = data
	get_node(^"Resources/HitPoints/Content/Row/Value").text = str(data.get("hit_points", 0))
	get_node(^"Resources/Omens/Content/Row/Value").text = str(data.get("omens", 0))
	get_node(^"Resources/Silver/Content/Row/Value").text = str(data.get("silver", 0))
	var abilities: Dictionary = data.get("abilities", {})
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		var value: Dictionary = abilities.get(ability, {})
		var button = get_node("Body/Abilities/" + ability + "/Content/Row/Modifier")
		var modifier: int = value.get("modifier", 0)
		button.text = "%+d" % modifier
		button.accessibility_name = "%s modifier %s" % [ability, button.text]
	get_node(^"Body/Context/Identity/Content/Description").text = str(data.get("description", ""))
	var companions: Array = data.get("companion_sheets", [])
	get_node(^"Body/Context/Companions").visible = not companions.is_empty()
	get_node(^"Body/Context/Companions").text = "Companions: %d" % companions.size()
	_layout()


func _layout() -> void:
	var compact := size.x < 600
	get_node(^"Body").vertical = compact
	get_node(^"Body/Abilities").columns = 2 if compact else 1


func _edit() -> void:
	edit_requested.emit()


func _edit_value(key: String) -> void:
	var resource_key: String = {"HitPoints": "hit_points", "Omens": "omens", "Silver": "silver"}.get(key, "")
	var row: Node = get_node("Resources/" + key + "/Content/Row") if not resource_key.is_empty() else get_node("Body/Abilities/" + key + "/Content/Row")
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
