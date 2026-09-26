extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
const AMMUNITION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/ammunition.gd")
signal targets_requested
var _ammunition := ""
var _options := {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}

func configure(character: Dictionary, item: Dictionary, options: Dictionary, state: String, message: String) -> void:
	_options = options.duplicate(true)
	var special := str(item.get("source_item_id", ""))
	var traits: Array = character.get("traits", [])
	var jab := false
	for raw in traits:
		var trait_data: Dictionary = raw
		if str(trait_data.get("id", "")) == "cowards-jab":
			jab = true
	var reach: int = item.get("range_feet", 0)
	get_node(^"Rules/Jab").visible = jab and not item.get("natural", false) and reach == 5
	get_node(^"Rules/Jab").button_pressed = str(options.get("mode", "")) == "jab"
	get_node(^"Rules/Eligible").visible = jab or special in ["shoe-of-deaths-horse", "sacred-shepherds-crook", "eurekia"]
	var eligible: bool = options.get("eligible", false)
	get_node(^"Rules/Eligible").button_pressed = eligible
	get_node(^"Rules/SmallMedium").visible = special == "shoe-of-deaths-horse"
	get_node(^"Rules/Faithless").visible = special == "sacred-shepherds-crook"
	var small_medium: bool = options.get("small_medium", false)
	get_node(^"Rules/SmallMedium").button_pressed = small_medium
	var faithless_human: bool = options.get("faithless_human", false)
	get_node(^"Rules/Faithless").button_pressed = faithless_human
	var disappointed: bool = options.get("disappointed", false)
	get_node(^"Context").text = _t("%s · Equipped %s") % [str(character.get("name", "Character")), (str(item.get("name", "weapon")) if item.get("custom", false) else _t(str(item.get("name", "weapon"))))]
	get_node(^"Metrics/Damage/Content/Value").text = str(item.get("damage", "—"))
	get_node(^"Metrics/Reach/Content/Value").text = str(item.get("range_feet", 0)) + _t(" ft")
	var abilities: Dictionary = character.get("abilities", {})
	var ability_name := str(item.get("attack_ability", "Strength"))
	var ability: Dictionary = abilities.get(ability_name, {})
	get_node(^"Metrics/Strength/Content/Label").text = _t(ability_name).to_upper()
	var creature := str(character.get("schema", "")) == "mork-borg-adversary/v1"
	if creature:
		get_node(^"Metrics/Strength/Content/Label").text = _t("FLAT TEST")
	var ability_modifier: int = 0 if creature else ability.get("modifier", 0)
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
		resource_copy = _t("%s · %d left · uses one per attack") % [_t(str(resource.get("name", "Ammunition"))), remaining]
	get_node(^"Ammunition/Resource").text = resource_copy
	get_node(^"Ammunition/Resource").theme_type_variation = "RookframeError" if candidates.is_empty() else "RookframeMeta"
	var difficulty: int = _options.get("difficulty", 0)
	get_node(^"Rules/Difficulty/Editor").text = "" if difficulty == 0 else str(difficulty)
	get_node(^"Rules/Modifier").value = str(_options.modifier)
	get_node(^"Rules/Lose").visible = not item.get("natural", false)
	get_node(^"Rules/Lose").button_pressed = str(_options.fumble) == "lose"
	var piercing: bool = _options.get("piercing", false)
	get_node(^"Rules/Piercing").button_pressed = piercing
	get_node(^"Rules").visible = state in ["ready", "error"]
	get_node(^"Target/Change").disabled = state == "pending"
	get_node(^"Outcome").visible = state != "resolved" and not message.is_empty()
	get_node(^"Outcome").text = _t(message)
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"

func set_targets(text: String) -> void:
	get_node(^"Target/Copy").text = text

func options() -> Dictionary:
	var difficulty: String = get_node(^"Rules/Difficulty/Editor").text.strip_edges()
	var modifier: String = get_node(^"Rules/Modifier").value.strip_edges()
	if (not difficulty.is_empty() and not difficulty.is_valid_int()) or not modifier.is_valid_int():
		return {}
	return {"mode": "jab" if get_node(^"Rules/Jab").button_pressed else "attack", "eligible": get_node(^"Rules/Eligible").button_pressed, "small_medium": get_node(^"Rules/SmallMedium").button_pressed, "faithless_human": get_node(^"Rules/Faithless").button_pressed, "ammunition": _ammunition, "difficulty": int(difficulty), "modifier": int(modifier), "fumble": "lose" if get_node(^"Rules/Lose").button_pressed else "break", "piercing": get_node(^"Rules/Piercing").button_pressed}

func _ready() -> void:
	get_node(^"Target/Change").pressed.connect(_choose_targets)

func _choose_targets() -> void:
	targets_requested.emit()


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Ammunition/Label").text = _t("AMMUNITION")
	get_node(^"Ammunition/Resource").text = _t("No ammunition available. Add it in Inventory.")
	get_node(^"Metrics/Damage/Content/Label").text = _t("DAMAGE")
	get_node(^"Metrics/Reach/Content/Label").text = _t("REACH")
	get_node(^"Metrics/Strength/Content/Label").text = _t("STRENGTH")
	get_node(^"Rules/Difficulty/Editor").accessibility_name = _t("Difficulty override, blank uses source rule")
	get_node(^"Rules/Difficulty/Label").text = _t("DIFFICULTY")
	get_node(^"Rules/Eligible").text = _t("Requirements confirmed")
	get_node(^"Rules/Faithless").text = _t("Target is a faithless human (ordinary staff damage)")
	get_node(^"Rules/Hint").text = _t("Blank difficulty uses the Creature’s printed rule. Choose overrides with the table. Distance uses committed Rook centers.")
	get_node(^"Rules/Jab").text = _t("Coward’s Jab (surprise, light one-handed)")
	get_node(^"Rules/Lose").text = _t("Fumble: lose instead of break")
	get_node(^"Rules/Modifier").label_text = _t("Situational modifier")
	get_node(^"Rules/Piercing").text = _t("Piercing attack")
	get_node(^"Rules/SmallMedium").text = _t("Target is small or medium-sized")
	get_node(^"Target/Change").text = _t("Change")
	get_node(^"Target/Copy").text = _t("Choose one Creature target")
