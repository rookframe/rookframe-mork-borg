extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const RULES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/special_rules.gd")
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/power_row.tscn")
const SPINNER = preload("res://rookframe/ui/icons/spinner.svg")
const ABILITIES := ["Agility", "Presence", "Strength", "Toughness"]
var i18n := I18N.new()
signal navigate_requested(route: String, item_id: String)
signal modifier_requested(ability: String)
signal companions_requested
signal edit_requested
signal powers_requested
signal omen_adjust_requested(delta: int)
var _data: Dictionary = {}
var _omen_pending := false

func _ready() -> void:
	for route in ["rest", "improve", "broken"]:
		get_node("HealthActions/" + route).pressed.connect(_open_action.bind(route, ""))
	get_node(^"Header/Edit").pressed.connect(_edit)
	get_node(^"Body/Combat/Inventory").pressed.connect(_open_action.bind("inventory", ""))
	get_node(^"Body/Context/CompanionsSection/Companions").pressed.connect(_companions)
	get_node(^"Body/Context/Powers/PowersAction").pressed.connect(_powers)
	_omen_button("DecreaseOmens").pressed.connect(_adjust_omens.bind(-1))
	_omen_button("IncreaseOmens").pressed.connect(_adjust_omens.bind(1))
	for ability in ABILITIES:
		get_node("Abilities/" + ability + "/Modifier").pressed.connect(_roll.bind(ability))

func configure(data: Dictionary, _miniatures: Array, _short_window: bool = false) -> void:
	_data = data
	var read_only: bool = data.get("read_only", false)
	for button in get_node(^"HealthActions").get_children():
		(button as Button).disabled = read_only
	get_node(^"Header/Edit").visible = not read_only
	get_node(^"Header/Class").text = _t(str(data.get("class_title", "No Class")))
	get_node(^"Resources/HitPoints/Padding/Content/Row/Value").text = "%s / %s" % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
	get_node(^"Resources/Omens/Padding/Content/Row/Value").text = str(data.get("omens", 0))
	get_node(^"Resources/Silver/Padding/Content/Row/Value").text = str(data.get("silver", 0))
	_update_omen_buttons()
	var abilities: Dictionary = data.get("abilities", {})
	for ability in ABILITIES:
		var value: Dictionary = abilities.get(ability, {})
		var button: Button = get_node("Abilities/" + ability + "/Modifier")
		var pending: String = data.get("pending_ability", "")
		button.text = "" if pending == ability else "%+d" % int(value.get("modifier", 0))
		button.icon = SPINNER if pending == ability else null
		button.disabled = read_only or not pending.is_empty()
		button.accessibility_name = _t("Waiting for %s Throw") % _t(ability) if pending == ability else _t("Roll %s %s") % [_t(ability), button.text]
		button.tooltip_text = button.accessibility_name
	_copy("Description", str(data.get("description", "")))
	_copy("Origin", _t(str(data.get("origin", ""))))
	var rules := ""
	var class_rules: Array = data.get("class_rules", [])
	for rule in class_rules:
		if not str(rule).strip_edges().is_empty():
			rules += ("\n" if not rules.is_empty() else "") + _t(str(rule))
	var actions := get_node(^"Body/Identity/ClassActions")
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
			_action_row(actions, str(trait_data.get("name", key)), str(trait_data.get("rules", "")), "use-item", "feature:" + key, read_only)
		else:
			rules += ("\n" if not rules.is_empty() else "") + _t(str(trait_data.get("name", ""))) + "\n" + _t(str(trait_data.get("rules", "")))
	_copy("Traits", rules.strip_edges())
	actions.visible = actions.get_child_count() > 0
	var identity_visible := false
	for child in get_node(^"Body/Identity").get_children():
		identity_visible = identity_visible or (child as Control).visible
	get_node(^"Body/Identity").visible = identity_visible
	var companions: Array = data.get("starting_creature_grants", [])
	var descriptions: Array = data.get("companion_sheets", [])
	get_node(^"Body/Context/CompanionsSection/Summary").text = _t("Companions · %d") % (companions.size() + descriptions.size())
	var equipped := ""
	var scrolls := 0
	var inventory: Array = data.get("inventory", [])
	for entry in inventory:
		var item: Dictionary = entry
		if str(item.get("kind", "")) == "Scroll":
			scrolls += 1
		if item.get("equipped", false):
			equipped += (" · " if not equipped.is_empty() else "") + (str(item.get("name", "Item")) if item.get("custom", false) else _t(str(item.get("name", "Item"))))
	get_node(^"Body/Combat/Equipment").text = equipped if not equipped.is_empty() else _t("Nothing equipped")
	get_node(^"Body/Context/Powers/Summary").text = _t("Scrolls · %d   Uses · %d") % [scrolls, int(data.get("power_uses", 0))]

func _copy(key: String, value: String) -> void:
	var label: Label = get_node("Body/Identity/" + key)
	label.text = value
	label.visible = not value.strip_edges().is_empty()

func _omen_button(key: String) -> Button:
	return get_node("Resources/Omens/Padding/Content/Row/" + key)

func _update_omen_buttons() -> void:
	var locked: bool = _omen_pending or _data.get("read_only", false)
	_omen_button("DecreaseOmens").disabled = locked or int(_data.get("omens", 0)) <= 0
	_omen_button("IncreaseOmens").disabled = locked

func _adjust_omens(delta: int) -> void:
	if _omen_pending or _data.get("read_only", false) or (delta < 0 and int(_data.get("omens", 0)) <= 0):
		return
	_omen_pending = true
	get_node(^"OmenStatus").text = _t("Saving…")
	get_node(^"OmenStatus").theme_type_variation = "RookframeMeta"
	get_node(^"OmenStatus").visible = true
	_update_omen_buttons()
	omen_adjust_requested.emit(delta)

func field_result(key: String, message: String, error: bool) -> void:
	if key != "omens":
		return
	_omen_pending = false
	get_node(^"OmenStatus").text = _t(message)
	get_node(^"OmenStatus").theme_type_variation = "RookframeError"
	get_node(^"OmenStatus").visible = error
	_update_omen_buttons()

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

func localize(locale: I18N) -> void:
	i18n = locale
	for ability in ABILITIES:
		get_node("Abilities/" + ability + "/Title").text = _t(ability)
	for entry in [["Header/Edit", "Edit sheet"], ["Resources/Omens/Padding/Content/Row/DecreaseOmens", "Decrease Omens"], ["Resources/Omens/Padding/Content/Row/IncreaseOmens", "Increase Omens"], ["Body/Combat/Inventory", "Open Inventory"], ["Body/Context/Powers/PowersAction", "Open Powers & scrolls"], ["Body/Context/CompanionsSection/Companions", "Open Companions"]]:
		var button: Button = get_node(entry[0])
		button.tooltip_text = _t(entry[1])
		button.accessibility_name = _t(entry[1])
	for entry in [["HitPoints", "HP"], ["Omens", "OMENS"], ["Silver", "SILVER"]]:
		get_node("Resources/" + entry[0] + "/Padding/Content/Title").text = _t(entry[1])
	for entry in [["rest", "Rest"], ["improve", "Level up"], ["broken", "Broken / death"]]:
		get_node("HealthActions/" + entry[0]).text = _t(entry[1])
	get_node(^"Body/Combat/Title").text = _t("COMBAT")

func _edit() -> void:
	edit_requested.emit()

func _companions() -> void:
	companions_requested.emit()

func _powers() -> void:
	powers_requested.emit()

func _roll(ability: String) -> void:
	modifier_requested.emit(ability)
