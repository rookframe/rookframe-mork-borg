extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

signal navigate_requested(route: String, item_id: String)
const RULES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_rules.gd")
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/power_row.tscn")
signal modifier_requested(ability: String)
signal companions_requested
signal edit_requested
signal powers_requested
signal omens_requested
signal value_save_requested(key: String, value: String)

const SPINNER = preload("res://rookframe/ui/icons/spinner.svg")
const CHECK = preload("res://rookframe/ui/icons/check.svg")
var _data: Dictionary = {}
var _editing := ""
var _short_window := false

func _ready() -> void:
	for route in ["rest", "improve", "broken"]:
		get_node("Body/Context/AtTable/Content/HealthActions/" + route).pressed.connect(_open_action.bind(route, ""))
	get_node(^"Body/Context/CompanionsSection/Content/Row/Companions").pressed.connect(_open_companions)
	resized.connect(_layout)
	get_node(^"Body/Context/AtTable/Content/HealthActions/OmensAction").pressed.connect(_open_omens)
	get_node(^"Body/Context/Powers/Content/Row/PowersAction").pressed.connect(_open_powers)
	get_node(^"Body/Identity/Content/Header/Edit").pressed.connect(_edit)
	for resource in ["HitPoints", "Omens", "Silver"]:
		get_node("Resources/" + resource + "/Content/Row/Edit").pressed.connect(_edit_value.bind(resource))
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Modifier").pressed.connect(_roll.bind(ability))
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Edit").pressed.connect(_edit_value.bind(ability))


func configure(data: Dictionary, _miniatures: Array, short_window: bool = false) -> void:
	_short_window = short_window
	_data = data
	var read_only: bool = data.get("read_only", false)
	for button in get_node(^"Body/Context/AtTable/Content/HealthActions").get_children():
		(button as Button).disabled = read_only
	get_node(^"Body/Identity/Content/Header/Edit").disabled = read_only
	get_node(^"Body/Context/AtTable/Content/HealthActions/OmensAction").disabled = read_only
	for resource in ["HitPoints", "Omens", "Silver"]:
		get_node("Resources/" + resource + "/Content/Row/Edit").disabled = read_only
	get_node(^"Resources/HitPoints/Content/Row/Value").text = "%s / %s" % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
	get_node(^"Resources/Omens/Content/Row/Value").text = str(data.get("omens", 0))
	get_node(^"Resources/Silver/Content/Row/Value").text = str(data.get("silver", 0))
	var abilities: Dictionary = data.get("abilities", {})
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		var value: Dictionary = abilities.get(ability, {})
		var button = get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Modifier")
		var modifier: int = value.get("modifier", 0)
		button.text = "%+d" % modifier
		var pending: String = data.get("pending_ability", "")
		button.icon = SPINNER if pending == ability else null
		button.text = "" if pending == ability else button.text
		button.disabled = read_only or not pending.is_empty()
		get_node("Body/Attributes/Content/Abilities/" + ability + "/Padding/Content/Row/Edit").disabled = read_only
		button.accessibility_name = _t("Waiting for %s Throw") % _t(ability) if pending == ability else _t("Roll %s %s") % [_t(ability), button.text]
	get_node(^"Body/Identity/Content/Description").text = str(data.get("description", ""))
	get_node(^"Body/Identity/Content/Origin").text = _t(str(data.get("class_title", "No Class"))) + "\n" + _t(str(data.get("origin", "")))
	var rules := ""
	var class_rules: Array = data.get("class_rules", [])
	for rule in class_rules:
		rules += _t(str(rule)) + "\n"
	var actions := get_node(^"Body/Identity/Content/ClassActions")
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if str(data.get("class_id", "")) == "fanged-deserter":
		_action_row(actions, "Bite", "DR10 · d6 · 5 ft. Enemy free attack on 1–2 on d6.", "attack", "class:bite", read_only)
	var traits: Array = data.get("traits", [])
	for raw_trait in traits:
		var trait_data: Dictionary = raw_trait
		var key := str(trait_data.get("id", ""))
		if not trait_data.has("item") and not RULES.new().definition(key).is_empty():
			_action_row(actions, str(trait_data.get("name", key)), _t(str(trait_data.get("rules", ""))), "use-item", "feature:" + key, read_only)
		rules += _t(str(trait_data.get("name", ""))) + "\n" + _t(str(trait_data.get("rules", ""))) + "\n"
	get_node(^"Body/Identity/Content/Traits").text = rules.strip_edges()
	var companions: Array = data.get("starting_creature_grants", [])
	get_node(^"Body/Context/CompanionsSection/Content/Row/Companions").visible = true
	var descriptions: Array = data.get("companion_sheets", [])
	get_node(^"Body/Context/CompanionsSection/Content/Row/Summary").text = _t("%d companions\nIndividual Creature sheets") % (companions.size() + descriptions.size())
	var equipped := ""
	var inventory: Array = data.get("inventory", [])
	var scrolls := 0
	for entry in inventory:
		var item: Dictionary = entry
		if str(item.get("kind", "")) == "Scroll":
			scrolls += 1
		var is_equipped: bool = item.get("equipped", false)
		if is_equipped:
			equipped += ("\n" if not equipped.is_empty() else "") + (str(item.get("name", "Item")) if item.get("custom", false) else _t(str(item.get("name", "Item"))))
	get_node(^"Body/Combat/Content/Equipment").text = equipped if not equipped.is_empty() else _t("No equipment equipped.")
	get_node(^"Body/Context/Powers/Content/Row/Summary").text = _t("%d scrolls\n%d daily uses remain") % [scrolls, int(data.get("power_uses", 0))]
	_layout()


func _layout() -> void:
	var compact := size.x < 600
	var short := compact and _short_window
	get_node(^"Body").columns = 1 if compact else 2
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
		value_save_requested.emit(resource_key if not resource_key.is_empty() else key, input.text)
		return
	if not _editing.is_empty():
		return
	_editing = key
	var value: int = _data.get(resource_key, 0)
	if resource_key.is_empty():
		var abilities: Dictionary = _data.get("abilities", {})
		var ability: Dictionary = abilities.get(key, {})
		value = ability.get("modifier", 0)
	input.text = str(value)
	input.visible = true
	var display := row.get_node(^"Value" if not resource_key.is_empty() else ^"Modifier") as Control
	display.visible = false
	var edit := row.get_node(^"Edit") as Button
	edit.icon = CHECK


func _open_companions() -> void:
	companions_requested.emit()

func _open_omens() -> void:
	omens_requested.emit()

func field_result(key: String, message: String, error: bool) -> void:
	var paths: Dictionary = {"hit_points": ^"Resources/HitPoints/Content/Error", "omens": ^"Resources/Omens/Content/Error", "silver": ^"Resources/Silver/Content/Error", "Agility": ^"Body/Attributes/Content/Abilities/Agility/Padding/Content/Error", "Presence": ^"Body/Attributes/Content/Abilities/Presence/Padding/Content/Error", "Strength": ^"Body/Attributes/Content/Abilities/Strength/Padding/Content/Error", "Toughness": ^"Body/Attributes/Content/Abilities/Toughness/Padding/Content/Error"}
	var path: NodePath = paths.get(key, ^"Resources/HitPoints/Content/Error")
	var label := get_node(path) as Label
	label.text = _t(message)
	label.visible = error

func _roll(ability: String) -> void:
	modifier_requested.emit(ability)

func _open_powers() -> void:
	powers_requested.emit()

func _action_row(parent: Node, title: String, rules: String, route: String, id: String, read_only: bool) -> void:
	var row := ROW.instantiate()
	i18n.power_row(row)
	parent.add_child(row)
	(row.get_node(^"Copy/Name") as Label).text = _t(title)
	(row.get_node(^"Copy/Rules") as Label).text = _t(rules)
	(row.get_node(^"Copy/Handling") as Label).visible = false
	(row.get_node(^"Cast") as Button).text = _t("Attack") if route == "attack" else _t("Use")
	(row.get_node(^"Cast") as Button).disabled = read_only
	(row.get_node(^"Cast") as Button).pressed.connect(_open_action.bind(route, id))

func _open_action(route: String, id: String) -> void:
	navigate_requested.emit(route, id)


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Body/Attributes/Content/Abilities/Agility/Padding/Content/Row/Edit").tooltip_text = _t("Edit Agility")
	get_node(^"Body/Attributes/Content/Abilities/Agility/Padding/Content/Row/Input").accessibility_name = _t("Edit Agility")
	get_node(^"Body/Attributes/Content/Abilities/Agility/Padding/Content/Title").text = _t("Agility")
	get_node(^"Body/Attributes/Content/Abilities/Presence/Padding/Content/Row/Edit").tooltip_text = _t("Edit Presence")
	get_node(^"Body/Attributes/Content/Abilities/Presence/Padding/Content/Row/Input").accessibility_name = _t("Edit Presence")
	get_node(^"Body/Attributes/Content/Abilities/Presence/Padding/Content/Title").text = _t("Presence")
	get_node(^"Body/Attributes/Content/Abilities/Strength/Padding/Content/Row/Edit").tooltip_text = _t("Edit Strength")
	get_node(^"Body/Attributes/Content/Abilities/Strength/Padding/Content/Row/Input").accessibility_name = _t("Edit Strength")
	get_node(^"Body/Attributes/Content/Abilities/Strength/Padding/Content/Title").text = _t("Strength")
	get_node(^"Body/Attributes/Content/Abilities/Toughness/Padding/Content/Row/Edit").tooltip_text = _t("Edit Toughness")
	get_node(^"Body/Attributes/Content/Abilities/Toughness/Padding/Content/Row/Input").accessibility_name = _t("Edit Toughness")
	get_node(^"Body/Attributes/Content/Abilities/Toughness/Padding/Content/Title").text = _t("Toughness")
	get_node(^"Body/Attributes/Content/Heading").text = _t("ATTRIBUTES")
	get_node(^"Body/Combat/Content/Title").text = _t("COMBAT")
	get_node(^"Body/Context/AtTable/Content/HealthActions/OmensAction").text = _t("Spend Omen")
	get_node(^"Body/Context/AtTable/Content/HealthActions/broken").text = _t("Broken & death")
	get_node(^"Body/Context/AtTable/Content/HealthActions/improve").text = _t("Getting better")
	get_node(^"Body/Context/AtTable/Content/HealthActions/rest").text = _t("Rest")
	get_node(^"Body/Context/AtTable/Content/Title").text = _t("AT THE TABLE")
	get_node(^"Body/Context/CompanionsSection/Content/Row/Companions").text = _t("View")
	get_node(^"Body/Context/CompanionsSection/Content/Title").text = _t("COMPANIONS")
	get_node(^"Body/Context/Powers/Content/Row/PowersAction").text = _t("View")
	get_node(^"Body/Context/Powers/Content/Title").text = _t("POWERS & SCROLLS")
	get_node(^"Body/Identity/Content/Header/Edit").text = _t("Edit sheet")
	get_node(^"Body/Identity/Content/Header/Title").text = _t("CHARACTER PROFILE")
	get_node(^"Body/Identity/Content/Origin").text = _t("No Class")
	get_node(^"Resources/HitPoints/Content/Row/Edit").tooltip_text = _t("Edit HP")
	get_node(^"Resources/HitPoints/Content/Row/Input").accessibility_name = _t("Edit HitPoints")
	get_node(^"Resources/HitPoints/Content/Title").text = _t("HP")
	get_node(^"Resources/Omens/Content/Row/Edit").tooltip_text = _t("Edit OMENS")
	get_node(^"Resources/Omens/Content/Row/Input").accessibility_name = _t("Edit Omens")
	get_node(^"Resources/Omens/Content/Title").text = _t("OMENS")
	get_node(^"Resources/Silver/Content/Row/Edit").tooltip_text = _t("Edit SILVER")
	get_node(^"Resources/Silver/Content/Row/Input").accessibility_name = _t("Edit Silver")
	get_node(^"Resources/Silver/Content/Title").text = _t("SILVER")
