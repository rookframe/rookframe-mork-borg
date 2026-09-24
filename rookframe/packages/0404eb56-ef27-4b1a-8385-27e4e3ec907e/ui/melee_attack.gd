extends VBoxContainer
signal targets_requested
var _options := {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}

func configure(character: Dictionary, item: Dictionary, options: Dictionary, state: String, message: String) -> void:
	_options = options.duplicate(true)
	get_node(^"Context").text = "%s · Equipped %s" % [str(character.get("name", "Character")), str(item.get("name", "weapon"))]
	get_node(^"Metrics/Damage/Content/Value").text = str(item.get("damage", "—"))
	get_node(^"Metrics/Reach/Content/Value").text = str(item.get("range_feet", 0)) + " ft"
	var abilities: Dictionary = character.get("abilities", {})
	var strength: Dictionary = abilities.get("Strength", {})
	var strength_modifier: int = strength.get("modifier", 0)
	get_node(^"Metrics/Strength/Content/Value").text = "%+d" % strength_modifier
	var difficulty: int = _options.get("difficulty", 0)
	get_node(^"Rules/Difficulty/Editor").text = "" if difficulty == 0 else str(difficulty)
	get_node(^"Rules/Modifier").value = str(_options.modifier)
	get_node(^"Rules/Lose").button_pressed = str(_options.fumble) == "lose"
	var piercing: bool = _options.get("piercing", false)
	get_node(^"Rules/Piercing").button_pressed = piercing
	get_node(^"Rules").visible = state in ["ready", "error"]
	get_node(^"Target/Change").disabled = state == "pending"
	get_node(^"Outcome").visible = not message.is_empty()
	get_node(^"Outcome").text = message
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"

func set_targets(text: String) -> void:
	get_node(^"Target/Copy").text = text

func options() -> Dictionary:
	var difficulty: String = get_node(^"Rules/Difficulty/Editor").text.strip_edges()
	var modifier: String = get_node(^"Rules/Modifier").value.strip_edges()
	if (not difficulty.is_empty() and not difficulty.is_valid_int()) or not modifier.is_valid_int():
		return {}
	return {"difficulty": int(difficulty), "modifier": int(modifier), "fumble": "lose" if get_node(^"Rules/Lose").button_pressed else "break", "piercing": get_node(^"Rules/Piercing").button_pressed}

func _ready() -> void:
	get_node(^"Target/Change").pressed.connect(_choose_targets)

func _choose_targets() -> void:
	targets_requested.emit()
