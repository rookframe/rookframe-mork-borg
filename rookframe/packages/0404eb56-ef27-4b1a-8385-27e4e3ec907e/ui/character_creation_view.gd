extends "res://rookframe/ui/components/surfaces/fullscreen_wizard.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const I18N = preload(ROOT + "ui/localization.gd")
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CLASSES = preload(ROOT + "logic/creation_classes.gd")
const DEFINITION = preload(ROOT + "logic/character_definition.gd")
const CLASS_IDS := ["classless", "fanged-deserter", "gutterborn-scum", "esoteric-hermit", "wretched-royalty", "heretical-priest", "occult-herbmaster"]
const CLASS_ICONS := ["character", "sword", "dagger", "staff", "silver", "book", "herbs"]
const ROUTES := ["create-class", "create-abilities", "create-origin", "create-equipment", "create-identity", "create-review"]
const HEADINGS := ["Choose your class", "Discover your abilities", "Find your roots", "Gather your belongings", "Give them a name", "Review your character"]
const SUBTITLES := ["A beginning, not a destiny.", "Your class is already included in each roll.", "Your origin and class traits.", "Roll your starting resources and gear.", "A name, a few words, a presence on the table.", "Everything is together. One last look before you begin."]
const ABILITIES := ["Agility", "Presence", "Strength", "Toughness", "Hit points"]
const ABILITY_DESCRIPTIONS := ["Defend, balance, swim and flee.", "Perceive, aim, charm and use Powers.", "Strike, grapple, lift and break.", "Resist poison, cold and heat.", "Roll your class Hit Points die and add Toughness. You start with at least 1 HP."]
const EQUIPMENT := ["Silver", "Omens", "Food", "Equipment pack", "Equipment first", "Equipment second", "Weapon", "Armor"]
const EQUIPMENT_FORMULAS := ["2d6 × 10", "1d2", "1d4 days", "1d6", "1d12", "1d12", "1d10", "1d4"]
const PACK_BUTTONS := ["/PackChoices/Options/Choice0", "/PackChoices/Options/Choice1", "/PackChoices/Options/Choice2", "/PackChoices/Options/Choice3", "/PackChoices/Options/Choice4"]
const STAGE := "Layout/Body/StageSlot/Stage"
const CONTEXT := "Layout/Body/ContextSlot/Context"
const LEFT := "Layout/Body/StageSlot/Stage/Content/Split/Left"
const DETAIL := "Layout/Body/StageSlot/Stage/Content/Split/Detail/Content"
signal class_selected(class_id: String)
signal scroll_selected(slot: String, disposition: String)
signal pack_selected(pack: String)
signal miniature_requested
var i18n := I18N.new()
var facade: SDK
var _draft: Dictionary = {}
var _route := ""
var _choice := ""
var _active := ""
var _records: Array[Dictionary] = []
var _preview_key := ""

func _ready() -> void:
	super._ready()
	get_node(LEFT + "/Choices").selected.connect(_selected_row)
	get_node(DETAIL + "/Appearance/Copy/PreferredMiniature").pressed.connect(_request_miniature)
	for index in range(DEFINITION.PACK_CHOICES.size()):
		get_node(DETAIL + PACK_BUTTONS[index]).pressed.connect(_request_pack.bind(DEFINITION.PACK_CHOICES[index]))
	get_node(DETAIL + "/ScrollChoice/Reroll").pressed.connect(_request_scroll.bind("reroll"))
	get_node(DETAIL + "/ScrollChoice/Eat").pressed.connect(_request_scroll.bind("eat"))
	get_node(DETAIL + "/ScrollChoice/Paper").pressed.connect(_request_scroll.bind("toilet-paper"))
	get_name_field().value_changed.connect(_name_changed)
	localize(i18n)

func localize(locale: I18N) -> void:
	i18n = locale
	var titles: Array[String] = []
	for title in ["Class", "Abilities", "Origin & Traits", "Equipment", "Identity", "Review"]:
		titles.append(_t(title))
	configure("MÖRK BORG", _t("Create a character"), titles, {"back": _t("Back"), "restart": _t("Start over"), "subtitle": _t("Character creation"), "close": _t("Close character creation")})
	get_name_field().label_text = _t("Name")
	get_name_field().help_text = _t("Required")
	get_description_field().label_text = _t("Description")
	get_description_field().help_text = _t("Optional · a few words to remember them by")

func get_name_field() -> Control:
	return get_node(LEFT + "/Identity/Name")

func get_description_field() -> Control:
	return get_node(LEFT + "/Identity/Description")

func set_status(message: String, error: bool = false) -> void:
	get_node(STAGE + "/Heading/Status").text = _t(message)
	get_node(STAGE + "/Heading/Status").visible = error and not message.is_empty()
	get_name_field().error_text = _t(message) if error and _route == "create-identity" else ""

func present_creation(route: String, draft: Dictionary, _compact: bool) -> void:
	var next_route := "create-abilities" if route == "create-rolling" else route
	var changed := _route != next_route
	_route = next_route
	_draft = draft
	var index := maxi(0, ROUTES.find(_route))
	set_step(index)
	get_node(STAGE + "/Heading/Kicker").text = _t("STEP %02d / 06") % (index + 1)
	get_node(STAGE + "/Heading/Title").text = _t(HEADINGS[index])
	get_node(STAGE + "/Heading/Subtitle").text = _t(SUBTITLES[index])
	get_node(STAGE + "/Content/Split").visible = index != 5
	get_node(STAGE + "/Content/Review").visible = index == 5
	get_node(LEFT + "/Choices").visible = index < 4
	get_node(LEFT + "/Identity").visible = index == 4
	_present_context()
	if index == 4:
		get_name_field().value = str(draft.get("name", ""))
		get_description_field().value = str(draft.get("description", ""))
		_present_identity()
	elif index == 5:
		_present_review()
	else:
		_records = _class_rows() if index == 0 else _roll_rows(index)
		var active := str(draft.get("active_roll", ""))
		if index == 3 and bool(draft.get("pack_choice_pending", false)):
			active = "Equipment pack"
		if index == 0:
			_choice = str(draft.get("class_id", "classless"))
		elif changed or _active != active or _record(_choice).is_empty():
			_choice = active if not _record(active).is_empty() else str(_records[0].id) if not _records.is_empty() else ""
		_active = active
		_present_choices()
		_present_detail()

func _selected_row(id: String) -> void:
	if _route == "create-class":
		class_selected.emit(id)
	else:
		_choice = id
		_present_choices()
		_present_detail()

func _present_choices() -> void:
	var completed := 0
	for record in _records:
		if bool(record.get("complete", false)):
			completed += 1
	get_node(LEFT + "/Choices").configure(_records, _choice, _t("CHOOSE A CLASS") if _route == "create-class" else _t("ALL RESULTS RECORDED" if completed == _records.size() else "ROLL IN ORDER"), _t("%d PATHS") % _records.size() if _route == "create-class" else "%d / %d" % [completed, _records.size()])

func _class_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index in range(CLASS_IDS.size()):
		var profile: Dictionary = CLASSES.new().profile(CLASS_IDS[index])
		rows.append({"id": CLASS_IDS[index], "title": _t(str(profile.title)), "subtitle": "", "value": "◆" if _draft.get("class_id") == CLASS_IDS[index] else "", "icon": _icon(CLASS_ICONS[index])})
	return rows

func _roll_rows(index: int) -> Array[Dictionary]:
	var profile: Dictionary = _draft.get("class_profile", {})
	var rows: Array[Dictionary] = []
	var active := str(_draft.get("active_roll", ""))
	if index == 1:
		var values: Dictionary = _draft.get("abilities", {})
		for number in range(ABILITIES.size()):
			var title: String = ABILITIES[number]
			var ability: Dictionary = values.get(title, {})
			var complete := values.has(title) if number < 4 else _draft.has("hit_points")
			var result := _modifier(int(ability.get("modifier", 0))) if complete and number < 4 else str(_draft.get("hit_points", "—")) if complete else ""
			var explanation := (_t("Score %d → modifier %s") % [int(ability.get("score", 0)), result]) if complete and number < 4 else _t("Starting and maximum Hit Points: %s") % result if complete else ""
			rows.append(_roll_row(title, _ability_formula(title, _draft), result, complete, ["agility", "presence", "strength", "toughness", "heart"][number], _t(ABILITY_DESCRIPTIONS[number]), explanation))
	elif index == 2:
		var class_id := str(_draft.get("class_id", "classless"))
		if class_id == "classless":
			rows.append({"id": "none", "title": _t("No class origin or traits"), "subtitle": _t("Continue to starting equipment."), "value": "", "icon": _icon("character"), "complete": true})
			return rows
		var herb := class_id == "occult-herbmaster"
		var royal := class_id == "wretched-royalty"
		var terms := [["Origin", "origin_roll", int(profile.get("origin_faces", 6)), "character"], ["First decoction" if herb else "First gift" if royal else "Class feature", "first_decoction_roll" if herb else "feature_roll", 8 if herb else 6, "herbs"]]
		if herb or royal:
			terms.append(["Second decoction" if herb else "Second gift", "second_decoction_roll" if herb else "second_feature_roll", 8 if herb else 6, "elixir"])
		if herb:
			terms.append(["Decoction doses", "decoction_doses", 4, "elixir"])
		for term in terms:
			rows.append(_roll_row(term[0], "1d%d" % term[2], str(_draft.get(term[1], "")), _draft.has(term[1]), term[3], _t("Your class determines this starting roll."), str(_draft.get("origin", "")) if term[0] == "Origin" else _traits_text(_draft)))
	else:
		var values: Dictionary = _draft.get("equipment_rolls", {})
		var icons := ["silver", "psychopomp", "food", "bag", "bag", "bag", "sword", "armor"]
		for number in range(EQUIPMENT.size()):
			var title: String = EQUIPMENT[number]
			var value := _equipment_meaning(title, _draft) if values.has(title) else ""
			rows.append(_roll_row(title, _equipment_formula(title, _draft, EQUIPMENT_FORMULAS[number]), value, values.has(title), icons[number], _t("Roll on the starting equipment table for your class."), value))
		if not EQUIPMENT.has(active) and not active.is_empty() and bool(_draft.get("equipment_roll_pending", false)):
			rows.append(_roll_row(active, str(_draft.get("active_roll_formula", "")), "", false, "dice", _t("Additional roll required by your starting equipment."), ""))
	return rows

func _roll_row(title: String, formula: String, value: String, complete: bool, icon_name: String, description: String, explanation: String) -> Dictionary:
	var current := title == str(_draft.get("active_roll", ""))
	var pending := bool(_draft.get("roll_pending", false)) or bool(_draft.get("equipment_roll_pending", false))
	return {"id": title, "title": _t(title), "subtitle": formula, "formula": formula, "value": value if complete else _t("Next" if bool(_draft.get("roll_ready", false)) else "Rolling…") if current and pending else "—", "complete": complete, "pending": not complete, "icon": _icon(icon_name), "icon_name": icon_name, "description": description, "explanation": explanation}

func _reset_detail() -> Control:
	var detail := get_node(DETAIL) as Control
	for name in ["Facts", "Formula", "Rules", "Result", "ResultCopy", "PackChoices", "ScrollChoice", "Appearance"]:
		get_node(DETAIL + "/" + name).visible = false
	get_node(DETAIL + "/Heading/Icon").visible = true
	get_node(DETAIL + "/Flavor").text = ""
	get_node(DETAIL + "/NoteRow/Note").text = _t("Results stay with you when you go back.")
	return detail

func _present_detail() -> void:
	var detail := _reset_detail()
	if _route == "create-class":
		var profile: Dictionary = _draft.get("class_profile", {})
		var herb := str(_draft.get("class_id", "")) == "occult-herbmaster"
		get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("BORN OF THE MUSHROOM" if herb else "STARTING CLASS")
		get_node(DETAIL + "/Heading/Copy/Title").text = _t(str(profile.get("title", "No Class")))
		get_node(DETAIL + "/Heading/Icon").texture = _icon(CLASS_ICONS[maxi(0, CLASS_IDS.find(str(_draft.get("class_id", "classless"))))])
		get_node(DETAIL + "/Flavor").text = _t("Raised in the glade. Your body is hardy; your remedies are stranger still." if herb else "Your class determines starting rolls, equipment and traits.")
		get_node(DETAIL + "/Facts").visible = true
		_set_fact("HitPoints", "Hit Points", "1d%d + TOU" % int(profile.get("hp_faces", 8)))
		_set_fact("Silver", "Silver", "%dd6 × 10" % int(profile.get("silver_count", 2)))
		_set_fact("Omens", "Omens", "1d%d" % int(profile.get("omen_faces", 2)))
		get_node(DETAIL + "/Rules").visible = true
		get_node(DETAIL + "/Rules").text = _class_rules_markup()
		get_node(DETAIL + "/NoteRow/Note").text = _t("Next: roll your four abilities, then Hit Points. Your class modifies the rolls automatically.")
		return
	var row := _record(_choice)
	if row.is_empty():
		return
	get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("RECORDED RESULT" if bool(row.get("complete", false)) else "STARTING ROLL")
	get_node(DETAIL + "/Heading/Copy/Title").text = str(row.title)
	get_node(DETAIL + "/Heading/Icon").texture = _icon(str(row.get("icon_name", "dice")))
	get_node(DETAIL + "/Flavor").text = str(row.get("description", ""))
	get_node(DETAIL + "/Formula").visible = row.has("formula")
	get_node(DETAIL + "/Formula").text = str(row.get("formula", ""))
	get_node(DETAIL + "/Result").visible = bool(row.get("complete", false))
	get_node(DETAIL + "/Result/Content/Value").text = str(row.get("value", ""))
	var rolls: Dictionary = _draft.get("roll_faces", {})
	var raw: Array = rolls.get(_choice, [])
	var faces: Array[String] = []
	for value in raw:
		faces.append(str(int(value)))
	get_node(DETAIL + "/Result/Content/Raw").visible = not faces.is_empty()
	get_node(DETAIL + "/Result/Content/Raw").text = _t("Rolled: %s") % _lines(faces, " + ")
	get_node(DETAIL + "/ResultCopy").visible = not str(row.get("explanation", "")).is_empty()
	get_node(DETAIL + "/ResultCopy").text = _t(str(row.get("explanation", "")))
	var values: Dictionary = _draft.get("equipment_rolls", {})
	var choices: Array[String] = DEFINITION.new().pack_choices_for_roll(int(values.get("Equipment pack", 0)))
	get_node(DETAIL + "/PackChoices").visible = _route == "create-equipment" and _choice == "Equipment pack" and not choices.is_empty()
	for index in range(DEFINITION.PACK_CHOICES.size()):
		var pack: String = DEFINITION.PACK_CHOICES[index]
		var choice := get_node(DETAIL + PACK_BUTTONS[index]) as Button
		choice.visible = choices.has(pack)
		choice.text = _t(pack)
		choice.set_pressed_no_signal(not bool(_draft.get("pack_choice_pending", true)) and str(_draft.get("pack", "")) == pack)
	get_node(DETAIL + "/ScrollChoice").visible = _route == "create-equipment" and not str(_draft.get("scroll_choice_slot", "")).is_empty()
	if get_node(DETAIL + "/PackChoices").visible:
		get_node(DETAIL + "/Flavor").text = _t("Choose your starting container or transport.")
		get_node(DETAIL + "/Formula").visible = false
		get_node(DETAIL + "/Result").visible = false
		get_node(DETAIL + "/ResultCopy").visible = false
		get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("1d6 · rolled %d") % int(values.get("Equipment pack", 0))
		get_node(DETAIL + "/NoteRow/Note").text = _t("Choose one pack below") if bool(_draft.get("pack_choice_pending", true)) else _t("Selected: %s") % _t(str(_draft.get("pack", "Nothing")))

func _class_rules_markup() -> String:
	var profile: Dictionary = _draft.get("class_profile", {})
	var rules: Array = _draft.get("class_rules", [])
	var parts: Array[String] = []
	if str(_draft.get("class_id", "")) == "occult-herbmaster":
		var offsets: Dictionary = profile.get("ability_offsets", {})
		for pair in [["Tough as wood", "Toughness"], ["Low in protein", "Strength"]]:
			parts.append("[color=#f0bb32][font_size=17]%s[/font_size][/color]\n%s" % [_bb(_t(pair[0])), _bb(_t("%s is rolled with 3d6 %+d.") % [_t(pair[1]), int(offsets.get(pair[1], 0))])])
		parts.append("[color=#f0bb32][font_size=17]%s[/font_size][/color]\n%s" % [_bb(_t("Portable laboratory")), _bb(_t(str(rules[1])))])
	else:
		var offsets: Dictionary = profile.get("ability_offsets", {})
		for ability in ["Agility", "Presence", "Strength", "Toughness"]:
			if not offsets.has(ability):
				continue
			parts.append("[color=#f0bb32][font_size=17]%s[/font_size][/color]\n%s" % [_bb(_t(str(ability))), _bb(_t("Starting roll: 3d6 %+d") % int(offsets[ability]))])
		for rule in rules:
			parts.append(_bb(_t(str(rule))))
	if parts.is_empty():
		parts.append("[color=#f0bb32][font_size=17]%s[/font_size][/color]\n%s" % [_bb(_t("Starting abilities")), _bb(_t("Roll 3d6 for each ability."))])
	return _lines(parts, "\n\n")

func _bb(value: String) -> String:
	return value.replace("[", "[lb]")

func _present_identity() -> void:
	var detail := _reset_detail()
	get_node(DETAIL + "/Heading/Icon").visible = false
	get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("ON THE TABLETOP")
	get_node(DETAIL + "/Heading/Copy/Title").text = _t("Preferred miniature")
	get_node(DETAIL + "/Appearance").visible = true
	var miniature: Dictionary = _draft.get("preferred_miniature", {})
	get_node(DETAIL + "/Appearance/Copy/Name").text = str(miniature.get("title", _t("None")))
	get_node(DETAIL + "/Appearance/Copy/PreferredMiniature").text = _t("Choose miniature" if miniature.is_empty() else "Change miniature")
	get_node(DETAIL + "/NoteRow/Note").text = _t("Your character portrait and tabletop miniature can be different.")
	var key := str(miniature.get("package_id", "")) + "/" + str(miniature.get("local_id", ""))
	get_node(DETAIL + "/Appearance/Preview").visible = not miniature.is_empty()
	if key != _preview_key and facade != null:
		_preview_key = key
		if not miniature.is_empty():
			facade.content.preview_miniature(SDK.ContentReference.new(str(miniature.package_id), str(miniature.local_id)), get_node(DETAIL + "/Appearance/Preview"))

func _present_context() -> void:
	var context := get_node(CONTEXT)
	var name := str(_draft.get("name", "")).strip_edges()
	get_node(CONTEXT + "/Name/Title").text = name if not name.is_empty() else _t("Unnamed soul")
	get_node(CONTEXT + "/Name/Class").text = _t(str(_draft.get("class_title", "No Class")))
	get_node(CONTEXT + "/PortraitVitals/Vitals/HitPoints/Row/Value").text = "%s / %s" % [int(_draft.hit_points), int(_draft.maximum_hit_points)] if _draft.has("hit_points") else "—"
	var totals: Dictionary = _draft.get("equipment_rolls", {})
	for key in ["Silver", "Omens"]:
		get_node(CONTEXT + "/PortraitVitals/Vitals/" + key + "/Row/Value").text = str(int(totals[key]) * (10 if key == "Silver" else 1)) if totals.has(key) else "—"
	var abilities: Dictionary = _draft.get("abilities", {})
	for key in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(key, {})
		get_node(CONTEXT + "/Attributes/" + key + "/Row/Value").text = _modifier(int(ability.get("modifier", 0))) if abilities.has(key) else "—"
	get_node(CONTEXT + "/History").text = _t(str(_draft.get("origin", ""))) if not str(_draft.get("origin", "")).is_empty() else _t("Your history, traits and belongings will appear as you create your character.")

func _present_review() -> void:
	var review := get_node(STAGE + "/Content/Review")
	var miniature: Dictionary = _draft.get("preferred_miniature", {})
	var identity: Array[Dictionary] = [_pair("Class", _t(str(_draft.get("class_title", "")))), _pair("Origin", _t(str(_draft.get("origin", ""))))]
	get_node(STAGE + "/Content/Review" + "/Character/Identity").configure(_t("Character"), _icon("character"), identity, str(_draft.get("description", "")) if not str(_draft.get("description", "")).is_empty() else _t("No description added."))
	var values: Array[Dictionary] = []
	var abilities: Dictionary = _draft.get("abilities", {})
	for ability in [["Agility", "AGI"], ["Presence", "PRE"], ["Strength", "STR"], ["Toughness", "TOU"]]:
		var score: Dictionary = abilities.get(ability[0], {})
		values.append(_pair(ability[1], _modifier(int(score.get("modifier", 0)))))
	var vitals: Array[Dictionary] = [_pair("Hit Points", "%s / %s" % [int(_draft.get("hit_points", 1)), int(_draft.get("maximum_hit_points", 1))]), _pair("Preferred miniature", str(miniature.get("title", _t("None"))))]
	get_node(STAGE + "/Content/Review" + "/Character/Abilities").configure(_t("Abilities"), _icon("strength"), vitals)
	get_node(STAGE + "/Content/Review" + "/Character/Abilities").set_stats(values)
	var inventory: Array = _draft.get("inventory", [])
	var weapon: Array = []
	var armor: Array = []
	var carried: Array = []
	for raw_item in inventory:
		var item: Dictionary = raw_item
		if item.get("kind", "") == "Weapon":
			weapon.append(item)
		elif item.get("kind", "") == "Armor":
			armor.append(item)
		else:
			carried.append(item)
	var equipment: Array[Dictionary] = [_pair("Weapon", _inventory_text(weapon)), _pair("Protection", _inventory_text(armor)), _pair("Carried", _inventory_text(carried).replace("\n", " · ")), _pair("Resources", _t("%s silver · %s Omens") % [int(_draft.get("silver", 0)), int(_draft.get("omens", 0))])]
	get_node(STAGE + "/Content/Review" + "/Belongings/Equipment").configure(_t("Equipment"), _icon("bag"), equipment)
	var traits: Array[Dictionary] = []
	var traits_data: Array = _draft.get("traits", [])
	for raw_trait in traits_data:
		var trait_data: Dictionary = raw_trait
		traits.append(_pair(_t(str(trait_data.get("name", ""))), _t(str(trait_data.get("rules", "")))))
	if _draft.has("decoction_doses"):
		traits.append(_pair("Portable laboratory", _t("%d doses / day") % int(_draft.decoction_doses)))
	get_node(STAGE + "/Content/Review" + "/Belongings/Traits").configure(_t("Class traits"), _icon("herbs"), traits)

func _pair(label: String, value: String) -> Dictionary:
	return {"label": _t(label), "value": value if not value.is_empty() else "—"}

func _icon(name: String) -> Texture2D:
	var icons := {
		"agility": preload("res://rookframe/ui/icons/character/agility.svg"),
		"armor": preload("res://rookframe/ui/icons/character/armor.svg"),
		"bag": preload("res://rookframe/ui/icons/character/bag.svg"),
		"book": preload("res://rookframe/ui/icons/character/book.svg"),
		"character": preload("res://rookframe/ui/icons/character/character.svg"),
		"dagger": preload("res://rookframe/ui/icons/character/dagger.svg"),
		"dice": preload("res://rookframe/ui/icons/character/dice.svg"),
		"elixir": preload("res://rookframe/ui/icons/character/elixir.svg"),
		"food": preload("res://rookframe/ui/icons/character/food.svg"),
		"heart": preload("res://rookframe/ui/icons/character/heart.svg"),
		"herbs": preload("res://rookframe/ui/icons/character/herbs.svg"),
		"presence": preload("res://rookframe/ui/icons/character/presence.svg"),
		"psychopomp": preload("res://rookframe/ui/icons/character/psychopomp.svg"),
		"silver": preload("res://rookframe/ui/icons/character/silver.svg"),
		"staff": preload("res://rookframe/ui/icons/character/staff.svg"),
		"strength": preload("res://rookframe/ui/icons/character/strength.svg"),
		"sword": preload("res://rookframe/ui/icons/character/sword.svg"),
		"toughness": preload("res://rookframe/ui/icons/character/toughness.svg"),
	}
	return icons.get(name, icons["dice"])


func _equipment_meaning(title: String, draft: Dictionary) -> String:
	var values: Dictionary = draft.get("equipment_rolls", {})
	var value := int(values.get(title, 0))
	if title == "Silver":
		return _t("%d silver") % (value * 10)
	if title == "Omens":
		return _t("1 omen") if value == 1 else _t("%d omens") % value
	if title == "Food":
		return _t("1 day of dried food") if value == 1 else _t("%d days of dried food") % value
	if title == "Equipment pack":
		if value == 3:
			return _t("Backpack")
		if value == 4:
			return _t("Sack")
		if value <= 2:
			return _t("No pack")
		return _t("Choose one pack below") if bool(draft.get("pack_choice_pending", true)) else _t(str(draft.get("pack", "Nothing")))
	if title == "Equipment first":
		return _t(DEFINITION.FIRST_EQUIPMENT_NAMES[value - 1]) if value >= 1 and value <= 12 else ""
	if title == "Equipment second":
		return _t(DEFINITION.SECOND_EQUIPMENT_NAMES[value - 1]) if value >= 1 and value <= 12 else ""
	if title == "Weapon" or title == "Armor":
		return _t(DEFINITION.new().resolve_equipment_name(title, value))
	return ""


func _ability_formula(title: String, draft: Dictionary) -> String:
	var profile: Dictionary = draft.get("class_profile", {})
	if title == "Hit points":
		var hp_faces: int = profile.get("hp_faces", 8)
		return _t("1d%d + Toughness") % hp_faces
	var offsets: Dictionary = profile.get("ability_offsets", {})
	var offset: int = offsets.get(title, 0)
	return "3d6" + ("%+d" % offset if offset != 0 else "")


func _equipment_formula(title: String, draft: Dictionary, fallback: String) -> String:
	var profile: Dictionary = draft.get("class_profile", {})
	if title == "Silver":
		var silver_count: int = profile.get("silver_count", 2)
		return _t("%dd6 × 10") % silver_count
	if title == "Omens":
		var omen_faces: int = profile.get("omen_faces", 2)
		return "1d%d" % omen_faces
	if title == "Weapon" or title == "Armor":
		var faces: int = profile.get("weapon_faces" if title == "Weapon" else "armor_faces", 10 if title == "Weapon" else 4)
		var totals: Dictionary = draft.get("equipment_rolls", {})
		var fixed_arms: bool = profile.get("fixed_arms", false)
		if not fixed_arms and (totals.has("Unclean scroll") or totals.has("Sacred scroll")):
			var limit := 6 if title == "Weapon" else 2
			if faces > limit:
				faces = limit
		return "1d%d" % faces
	return fallback


func _rules_text(draft: Dictionary) -> String:
	var rules: Array = draft.get("class_rules", [])
	var result := ""
	for rule in rules:
		result += ("\n" if not result.is_empty() else "") + _t(str(rule))
	return result if not result.is_empty() else _t("Normal ability rolls and starting equipment.")


func _traits_text(draft: Dictionary) -> String:
	var result := ""
	var traits: Array = draft.get("traits", [])
	for raw_trait in traits:
		var trait_data: Dictionary = raw_trait
		result += ("

" if not result.is_empty() else "") + _t(str(trait_data.get("name", ""))) + "\n" + _t(str(trait_data.get("rules", "")))
	if draft.has("decoction_doses"):
		var doses: int = draft.get("decoction_doses", 0)
		result += _t("\n\nShared decoction doses: %d") % doses
	return result


func _inventory_text(items: Array) -> String:
	var names: Array[String] = []
	for item in items:
		var item_data: Dictionary = item
		var name := _t(str(item_data.get("name", "Item")))
		var quantity := int(item_data.get("quantity", 1))
		names.append("%s × %d" % [name, quantity] if quantity != 1 else name)
	return _lines(names)


func _modifier(value: int) -> String:
	return "%+d" % value


func _lines(values: Array[String], separator: String = "\n") -> String:
	var text := ""
	for value in values:
		var line: String = value
		text += (separator if not text.is_empty() else "") + line
	return text


func _t(source: String) -> String:
	return i18n.text(source)



func _request_miniature() -> void:
	miniature_requested.emit()

func _request_pack(pack: String) -> void:
	pack_selected.emit(pack)

func _request_scroll(disposition: String) -> void:
	scroll_selected.emit(str(_draft.get("scroll_choice_slot", "")), disposition)

func _name_changed(value: String) -> void:
	get_node(CONTEXT + "/Name/Title").text = value if not value.strip_edges().is_empty() else _t("Unnamed soul")

func _record(id: String) -> Dictionary:
	for record in _records:
		if record.id == id:
			return record
	return {}

func _set_fact(id: String, label: String, value: String) -> void:
	get_node(DETAIL + "/Facts/Row/" + id + "/Label").text = _t(label)
	get_node(DETAIL + "/Facts/Row/" + id + "/Value").text = value
