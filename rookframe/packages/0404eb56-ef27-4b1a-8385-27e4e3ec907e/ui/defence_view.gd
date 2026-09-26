extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

func _ready() -> void:
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	var compact := size.x < 700
	get_node(^"Sections").columns = 1 if compact else 2
	for metric_name in ["Attacker", "Attack", "Difficulty"]:
		var metric: Control = get_node("Metrics/" + metric_name + "/Content")
		metric.get_node(^"Label").set("theme_override_font_sizes/font_size", 12 if compact else 14)
		metric.get_node(^"Value").set("theme_override_font_sizes/font_size", (16 if metric_name == "Attacker" else 24) if compact else 28)

func configure(outcome: Dictionary, state: String, message: String) -> void:
	get_node(^"Metrics/Attacker/Content/Value").text = str(outcome.get("attacker", "Creature"))
	get_node(^"Metrics/Attack/Content/Value").text = "%s · %s" % [_t(str(outcome.get("attack", "Attack"))), str(outcome.get("damage", ""))]
	var difficulty: int = outcome.get("difficulty", 12)
	get_node(^"Metrics/Difficulty/Content/Value").text = _t("Always hits") if outcome.get("automatic_hit", false) else _t("DR%d") % difficulty
	var flat: bool = outcome.get("flat_test", false)
	get_node(^"Sections/YourDefence/Content/BodySlot/Agility/Label").text = _t("Flat test") if flat else _t("Agility")
	var agility: int = outcome.get("agility", 0)
	get_node(^"Sections/YourDefence/Content/BodySlot/Agility/Value").text = "%+d" % agility
	get_node(^"Sections/YourDefence/Content/BodySlot/Armor/Value").text = "−" + str(outcome.protection) if not str(outcome.get("protection", "")).is_empty() else "—"
	get_node(^"Sections/YourDefence/Content/BodySlot/Shield/Value").text = _t("−1 damage") if outcome.get("has_shield", false) else "—"
	get_node(^"Sections/PlayerRolls/Content/BodySlot/Rules").text = _t("This attack always hits. Roll damage and protection.") if outcome.get("automatic_hit", false) else _t("Roll %s against DR%d. A failed defence lets the attack hit. Natural 20: free attack. Natural 1: double damage and armor loses one tier; its penalties remain.") % [_t("a flat d20") if flat else _t("Agility"), difficulty]
	get_node(^"Options").visible = state == "ready" and not outcome.get("automatic_hit", false)
	get_node(^"Outcome").visible = not message.is_empty() and state != "resolved"
	get_node(^"Outcome").text = _t(message)
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"

func options() -> Dictionary:
	var difficulty: String = get_node(^"Options/Difficulty/Editor").text.strip_edges()
	var modifier: String = get_node(^"Options/Modifier/Editor").text.strip_edges()
	if (not difficulty.is_empty() and not difficulty.is_valid_int()) or not modifier.is_valid_int():
		return {}
	return {"difficulty": int(difficulty), "modifier": int(modifier)}


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Metrics/Attack/Content/Label").text = _t("ATTACK")
	get_node(^"Metrics/Attacker/Content/Label").text = _t("ATTACKER")
	get_node(^"Metrics/Difficulty/Content/Label").text = _t("DEFENCE")
	get_node(^"Options/Difficulty/Editor").accessibility_name = _t("Difficulty override")
	get_node(^"Options/Difficulty/Label").text = _t("Difficulty override")
	get_node(^"Options/Hint").text = _t("Blank difficulty uses the source rule and armor. Agree situational changes with the table.")
	get_node(^"Options/Modifier/Editor").accessibility_name = _t("Situational modifier")
	get_node(^"Options/Modifier/Label").text = _t("Situational modifier")
