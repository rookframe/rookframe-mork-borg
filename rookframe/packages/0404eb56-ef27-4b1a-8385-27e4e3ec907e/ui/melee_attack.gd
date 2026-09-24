extends VBoxContainer
const AMMUNITION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/ammunition.gd")
signal targets_requested
var _ammunition := ""
var _options := {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}

func configure(character: Dictionary, item: Dictionary, options: Dictionary, state: String, message: String) -> void:
	_options = options.duplicate(true)
	get_node(^"Context").text = "%s · Equipped %s" % [str(character.get("name", "Character")), str(item.get("name", "weapon"))]
	get_node(^"Metrics/Damage/Content/Value").text = str(item.get("damage", "—"))
	get_node(^"Metrics/Reach/Content/Value").text = str(item.get("range_feet", 0)) + " ft"
	var abilities: Dictionary = character.get("abilities", {})
	var ability_name := str(item.get("attack_ability", "Strength"))
	var ability: Dictionary = abilities.get(ability_name, {})
	get_node(^"Metrics/Strength/Content/Label").text = ability_name.to_upper()
	var ability_modifier: int = ability.get("modifier", 0)
	get_node(^"Metrics/Strength/Content/Value").text = "%+d" % ability_modifier
	var ammunition_kind := str(item.get("ammunition", ""))
	get_node(^"Ammunition").visible = not ammunition_kind.is_empty()
	var candidates := AMMUNITION.new().available(character.get("inventory", []), ammunition_kind)
	_ammunition = ""
	var resource_copy := "No ammunition available. Add it in Inventory."
	if not candidates.is_empty():
		var resource: Dictionary = candidates[0]
		_ammunition = str(resource.get("inventory_id", ""))
		var remaining: int = resource.get(str(resource.get("resource_field", "quantity")), 0)
		resource_copy = "%s · %d left · uses one per attack" % [str(resource.get("name", "Ammunition")), remaining]
	get_node(^"Ammunition/Resource").text = resource_copy
	get_node(^"Ammunition/Resource").theme_type_variation = "RookframeError" if candidates.is_empty() else "RookframeMeta"
	var difficulty: int = _options.get("difficulty", 0)
	get_node(^"Rules/Difficulty/Editor").text = "" if difficulty == 0 else str(difficulty)
	get_node(^"Rules/Modifier").value = str(_options.modifier)
	get_node(^"Rules/Lose").button_pressed = str(_options.fumble) == "lose"
	var piercing: bool = _options.get("piercing", false)
	get_node(^"Rules/Piercing").button_pressed = piercing
	get_node(^"Rules").visible = state in ["ready", "error"]
	get_node(^"Target/Change").disabled = state == "pending"
	get_node(^"Outcome").visible = state != "resolved" and not message.is_empty()
	get_node(^"Outcome").text = message
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"

func set_targets(text: String) -> void:
	get_node(^"Target/Copy").text = text

func options() -> Dictionary:
	var difficulty: String = get_node(^"Rules/Difficulty/Editor").text.strip_edges()
	var modifier: String = get_node(^"Rules/Modifier").value.strip_edges()
	if (not difficulty.is_empty() and not difficulty.is_valid_int()) or not modifier.is_valid_int():
		return {}
	return {"ammunition": _ammunition, "difficulty": int(difficulty), "modifier": int(modifier), "fumble": "lose" if get_node(^"Rules/Lose").button_pressed else "break", "piercing": get_node(^"Rules/Piercing").button_pressed}

func _ready() -> void:
	get_node(^"Target/Change").pressed.connect(_choose_targets)

func _choose_targets() -> void:
	targets_requested.emit()
