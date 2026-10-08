extends "res://rookframe/ui/components/surfaces/fullscreen_wizard.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const I18N = preload(ROOT + "ui/localization.gd")
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const PLAN = preload(ROOT + "logic/creation_roll_plan.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
var _roll_plan := PLAN.new()
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
const PACK_BUTTONS := ["/PackChoices/Options/Choice0", "/PackChoices/Options/Choice1", "/PackChoices/Options/Choice2", "/PackChoices/Options/Choice3", "/PackChoices/Options/Choice4"]
const STAGE := "Layout/Body/StageSlot/Stage"
const CONTEXT := "Layout/Body/ContextSlot/Context"
const LEFT := "Layout/Body/StageSlot/Stage/Content/Split/Left"
const DETAIL := "Layout/Body/StageSlot/Stage/Content/Split/Detail/Pages/Area/Content"
const MINIATURE := DETAIL + "/Appearance/Columns/MiniaturePanel/Inset/Content/"
signal class_selected(class_id: String)
signal scroll_selected(slot: String, disposition: String)
signal pack_selected(pack: String)
signal miniature_requested
signal miniature_reset_requested
var i18n := I18N.new()
var facade: SDK
var _draft: Dictionary = {}
var _route := ""
var _choice := ""
var _active := ""
var _records: Array[Dictionary] = []
var _preview_key := ""
var _details := false
var _review_section := "Character"
var _pending_choice := ""
var _detail_key := ""

func _ready() -> void:
	super._ready()
	get_node(LEFT + "/Choices").selected.connect(_selected_row)
	get_node(DETAIL + "/Appearance").miniature_requested.connect(_request_miniature)
	get_node(DETAIL + "/Appearance").miniature_clear_requested.connect(_reset_miniature)
	for index in range(DEFINITION.PACK_CHOICES.size()):
		get_node(DETAIL + PACK_BUTTONS[index]).pressed.connect(_request_pack.bind(DEFINITION.PACK_CHOICES[index]))
	get_node(DETAIL + "/ScrollChoice/Reroll").pressed.connect(_request_scroll.bind("reroll"))
	get_node(DETAIL + "/ScrollChoice/Eat").pressed.connect(_request_scroll.bind("eat"))
	get_node(DETAIL + "/ScrollChoice/Paper").pressed.connect(_request_scroll.bind("toilet-paper"))
	get_name_field().value_changed.connect(_name_changed)
	get_node(STAGE + "/Heading/Details").pressed.connect(_toggle_details)
	for section in ["Character", "Gear", "Traits"]:
		get_node(STAGE + "/Heading/ReviewTabs/" + section).pressed.connect(_select_review.bind(section))
	localize(i18n)
	_fit()

func _fit() -> void:
	super._fit()
	if not is_node_ready():
		return
	var phone := is_compact()
	var tablet := is_tablet()
	var context := get_node(CONTEXT)
	context.add_theme_constant_override("separation", 5 if phone else 12 if tablet else 20)
	for name in ["Heading", "HintRow", "Spacer"]:
		get_node(CONTEXT + "/" + name).visible = not phone and (name == "Heading" or not tablet)
	_text(CONTEXT + "/Heading/Title", 14 if tablet else 18,1.3)
	_text(CONTEXT + "/Heading/State", 14 if tablet else 16,1.4)
	_text(CONTEXT + "/HintRow/Hint", 17)
	get_node(CONTEXT + "/PortraitVitals").add_theme_constant_override("separation", 12 if phone else 16 if tablet else 20)
	for path in ["/PortraitVitals/PortraitFrame", "/PortraitVitals/PortraitFrame/Portrait"]:
		get_node(CONTEXT + path).custom_minimum_size = Vector2(80,100) if phone else Vector2(100,125) if tablet else Vector2(152,190)
	get_node(CONTEXT + "/PortraitVitals/Vitals").add_theme_constant_override("separation", 2 if phone else 8 if tablet else 16)
	for vital in ["HitPoints", "Omens", "Silver"]:
		var path: String = CONTEXT + "/PortraitVitals/Vitals/" + vital
		get_node(path).add_theme_constant_override("separation", 0)
		get_node(path + "/Row").add_theme_constant_override("separation", 6 if phone or tablet else 8)
		get_node(path + "/Row/Icon").custom_minimum_size = Vector2(18,18) if phone else Vector2(20,20) if tablet else Vector2(24,24)
		get_node(path + "/Row/Icon").self_modulate = Color(1, 0.505882, 0.478431, 1) if vital == "HitPoints" else Color(0.815686, 0.745098, 0.556863, 1)
		_text(path + "/Row/Value", 20 if phone else 24 if tablet else 30, 1.0 if phone else 1.05)
		_text(path + "/Label", 13 if phone else 14 if tablet else 16, 1.1 if phone else 1.2)
	_text(CONTEXT + "/Name/Title",24 if phone else 29 if tablet else 40,1.1)
	_text(CONTEXT + "/Name/Class",16 if phone else 18 if tablet else 20,1.2 if phone else 1.4)
	get_node(CONTEXT + "/Name").add_theme_constant_override("separation",0 if phone else 4)
	var has_history := not str(_draft.get("origin", "")).is_empty()
	get_node(CONTEXT + "/PhoneHistory").visible = has_history
	get_node(CONTEXT + "/History").visible = not has_history and not phone
	get_node(CONTEXT + "/PhoneHistory").add_theme_constant_override("separation",3 if phone else 8 if tablet else 12)
	_text(CONTEXT + "/History",16 if tablet else 18)
	var history_count := 0
	for row in get_node(CONTEXT + "/PhoneHistory").get_children():
		if not (row.get_node(^"Text") as Label).text.is_empty():
			history_count += 1
	for name in ["Line0", "Line1", "Line2", "Line3"]:
		var index: int = ["Line0", "Line1", "Line2", "Line3"].find(name)
		var path: String = CONTEXT + "/PhoneHistory/" + name
		_text(path + "/Text",15 if phone else 17 if tablet else 19)
		get_node(path + "/Icon").custom_minimum_size = Vector2(18,18) if phone else Vector2(24,24)
		get_node(path).visible = not (get_node(path + "/Text") as Label).text.is_empty() and (not phone or index >= maxi(0, history_count - 2))
	get_node(CONTEXT + "/Attributes").columns = 4 if phone else 2
	get_node(CONTEXT + "/Attributes").add_theme_constant_override("h_separation",6 if phone else 16)
	get_node(CONTEXT + "/Attributes").add_theme_constant_override("v_separation",0)
	for ability in ["Agility","Presence","Strength","Toughness"]:
		var path: String = CONTEXT + "/Attributes/" + ability
		get_node(path).custom_minimum_size = Vector2(0,38 if phone else 44 if tablet else 48)
		get_node(path).theme_type_variation = "WizardAttributeCompact" if phone else "WizardAttribute"
		get_node(path + "/Row").vertical = phone
		get_node(path + "/Row").add_theme_constant_override("separation",0 if phone else 5 if tablet else 8)
		get_node(path + "/Row/Icon").visible = not phone
		get_node(path + "/Row/Icon").custom_minimum_size = Vector2(20,20) if tablet else Vector2(24,24)
		_text(path + "/Row/Label",13 if phone else 14 if tablet else 17,1.1 if phone else 1.4)
		_text(path + "/Row/Value",22 if phone or tablet else 27,1.1 if phone else 1.3)
		get_node(path + "/Row/Label").horizontal_alignment = 1 if phone else 0
		get_node(path + "/Row/Value").horizontal_alignment = 1 if phone else 0
	get_node(STAGE).add_theme_constant_override("separation",4 if phone else 6 if tablet and size.y <= 740 else 10 if tablet else 24)
	var column_gap := 0 if phone else 16 if tablet else 24
	get_node(STAGE + "/Content/Split").add_theme_constant_override("separation",column_gap)
	get_node(LEFT).size_flags_stretch_ratio = 0.9 if tablet else 1.0
	get_node(STAGE + "/Content/Split/Detail").size_flags_stretch_ratio = 1.1 if tablet else 1.0
	get_node(STAGE + "/Content/Split/Detail").theme_type_variation = "WizardPlain" if phone else "WizardDivider"
	get_node(STAGE + "/Heading/Copy").add_theme_constant_override("separation",2 if tablet else 4)
	_text(STAGE + "/Heading/Copy/Kicker",16 if tablet else 18,1.3)
	_text(STAGE + "/Heading/Copy/Subtitle",17 if tablet else 20,1.3)
	for name in ["Kicker","Subtitle"]:
		get_node(STAGE + "/Heading/Copy/" + name).visible = not phone
	_text(STAGE + "/Heading/Copy/Title",25 if phone else 29 if tablet else 36,1.1 if phone else 1.2)
	get_node(STAGE + "/Heading/Copy/Title").text_overrun_behavior = 3
	get_node(STAGE + "/Heading").custom_minimum_size = Vector2(0, 44 if phone else 0)
	_text(STAGE + "/Heading/Details",17)
	for section in ["Character","Gear","Traits"]:
		_text(STAGE + "/Heading/ReviewTabs/" + section,17)
	get_node(LEFT + "/Choices").columns = 2 if phone and _route == "create-class" and size.x > 600 else 1
	get_node(LEFT + "/Identity").add_theme_constant_override("separation",0)
	get_node(LEFT + "/Identity/FieldGap").custom_minimum_size = Vector2(0, 8 if phone else 20)
	get_node(LEFT + "/Identity/DescriptionGap").custom_minimum_size = Vector2(0, 8 if phone else 12)
	for field in [get_name_field(),get_description_field()]:
		field.compact = phone
	var detail := get_node(DETAIL)
	var pages := get_node(STAGE + "/Content/Split/Detail/Pages")
	pages.enabled = true
	for edge in ["left","top","right","bottom"]:
		pages.set("offset_" + edge, column_gap + 1 if edge == "left" and not phone else 0)
	detail.add_theme_constant_override("separation",6 if tablet and _route == "create-class" else 8 if phone or tablet else 20)
	get_node(DETAIL + "/Heading").add_theme_constant_override("separation",12 if phone else 10 if tablet else 16)
	get_node(DETAIL + "/Heading/Icon").custom_minimum_size = Vector2(32,32) if phone else Vector2(36,36) if tablet else Vector2(56,56)
	get_node(DETAIL + "/Heading/Copy").add_theme_constant_override("separation",0)
	_text(DETAIL + "/Heading/Copy/Title",24 if phone else 26 if tablet else 32,1.1 if phone else 1.15)
	_text(DETAIL + "/Heading/Copy/Kicker",14 if phone else 15 if tablet else 18,1.3)
	get_node(DETAIL + "/RollInfo").vertical = not phone
	get_node(DETAIL + "/RollOutcome").vertical = not phone
	get_node(DETAIL + "/RollInfo").visible = not _route in ["create-class","create-identity"]
	get_node(DETAIL + "/RollOutcome").visible = get_node(DETAIL + "/RollOutcome/Result").visible or get_node(DETAIL + "/RollOutcome/ResultCopy").visible
	for group in ["RollInfo","RollOutcome"]:
		get_node(DETAIL + "/" + group).add_theme_constant_override("separation",16 if phone else 8 if tablet else 20)
	_text(DETAIL + "/RollInfo/FormulaRow/Row/Value",28 if phone else 30 if tablet else 40)
	_text(DETAIL + "/RollInfo/FormulaRow/Row/Caption",15 if phone else 16 if tablet else 18,1.3)
	_text(DETAIL + "/RollInfo/Flavor",17 if phone else 18 if tablet else 21,1.2 if phone else 1.25 if tablet else 1.35)
	_text(DETAIL + "/RollOutcome/ResultCopy",17 if phone else 18 if tablet else 21,1.2 if phone else 1.25 if tablet else 1.35)
	_text(DETAIL + "/RollOutcome/Result/Content/Value",22 if phone else 23 if tablet else 28)
	get_node(DETAIL + "/RollOutcome/Result/Content/Value").max_lines_visible = 2 if phone else -1
	get_node(DETAIL + "/RollOutcome/Result/Content/Value").text_overrun_behavior = 3 if phone else 0
	get_node(DETAIL + "/RollOutcome/Result/Content/Label").visible = not phone
	_text(DETAIL + "/RollOutcome/Result/Content/Label",14 if phone else 17,1.3)
	get_node(DETAIL + "/RollOutcome/Result").theme_type_variation = "WizardResultCompact" if phone else "WizardResult"
	get_node(DETAIL + "/RollInfo/FormulaRow").theme_type_variation = "WizardFormulaBoxCompact" if phone else "WizardFormulaBoxTablet" if tablet else "WizardFormulaBox"
	get_node(DETAIL + "/ClassBody").vertical = not phone
	get_node(DETAIL + "/ClassBody").add_theme_constant_override("separation",20 if phone else 6 if tablet else 20)
	get_node(DETAIL + "/ClassBody/FactsColumn").add_theme_constant_override("separation",8 if phone else 6 if tablet else 20)
	_text(DETAIL + "/ClassBody/FactsColumn/Flavor",17 if phone else 18 if tablet else 21,1.2 if phone else 1.25 if tablet else 1.35)
	if _route == "create-class":
		_present_class_rules()
	for fact in ["HitPoints","Silver","Omens"]:
		var path: String = DETAIL + "/ClassBody/FactsColumn/Facts/Row/" + fact
		get_node(path).add_theme_constant_override("separation",2 if phone else 4)
		_text(path + "/Label",14 if phone else 15 if tablet else 18)
		_text(path + "/Value",21 if phone or tablet else 26)
	get_node(DETAIL + "/ClassBody/FactsColumn/Facts").theme_type_variation = "WizardFactsCompact" if phone else "WizardFactsTablet" if tablet else "WizardFacts"
	_text(DETAIL + "/NoteRow/Note",14 if tablet else 17,1.3)
	for name in ["Spacer","NoteRule","NoteRow"]:
		get_node(DETAIL + "/" + name).visible = _route != "create-identity" and not phone and (name != "Spacer" or not tablet) and (_route != "create-equipment" or get_node(DETAIL + "/PackChoices").visible) and (_route == "create-class" or not bool(_record(_choice).get("complete", false)) or get_node(DETAIL + "/PackChoices").visible)
	get_node(DETAIL + "/Heading").visible = _route != "create-identity"
	get_node(DETAIL + "/Appearance").configure(i18n, null, false, true, phone, tablet)
	get_node(DETAIL + "/PackChoices/Options").columns = 3 if phone else 2
	get_node(DETAIL + "/PackChoices/Options").add_theme_constant_override("v_separation",6 if phone else 8)
	get_node(DETAIL + "/PackChoices/Prompt").visible = not phone
	get_node(DETAIL + "/ScrollChoice").vertical = not phone
	for group in [PACK_BUTTONS,["/ScrollChoice/Reroll","/ScrollChoice/Eat","/ScrollChoice/Paper"]]:
		for path in group:
			_text(DETAIL + path,17 if phone or tablet else 20)
	get_node(STAGE + "/Content/Review").add_theme_constant_override("separation",20 if tablet else 32)
	for column in ["Character","Belongings"]:
		get_node(STAGE + "/Content/Review/"+column+"Pages").enabled = true
		get_node(STAGE + "/Content/Review/"+column+"Pages").content_inset_left = 0 if phone or column == "Character" else 17 if tablet else 25
		get_node(STAGE + "/Content/Review/"+column+"Pages/Area/"+column).add_theme_constant_override("separation",8 if phone else 10 if tablet else 24)
	_sync_navigation()

func _text(path: String, font_size: int, line_height: float = 1.2) -> void:
	_style_text(get_node(path), font_size, line_height)

func _style_text(node: Control, font_size: int, line_height: float) -> void:
	node.add_theme_font_size_override("font_size",font_size)
	preload("res://rookframe/ui/theme/silkbound_line_height.gd").apply(node,line_height)

func _toggle_details() -> void:
	_details = not _details
	_sync_navigation()

func _select_review(section: String) -> void:
	_review_section = section
	_sync_navigation()

func _sync_navigation() -> void:
	var phone := is_compact()
	var review := _route == "create-review"
	get_node(STAGE + "/Heading/Details").visible = phone and not review
	get_node(STAGE + "/Heading/Details").text = _t(("Class list" if _details else "Class details") if _route == "create-class" else ("Identity" if _details else "Appearance") if _route == "create-identity" else ("Roll list" if _details else "Roll details"))
	get_node(STAGE + "/Heading/Details").set_pressed_no_signal(_details)
	get_node(STAGE + "/Heading/ReviewTabs").visible = phone and review
	get_node(LEFT).visible = not phone or not _details
	get_node(STAGE + "/Content/Split/Detail").visible = not phone or _details
	get_node(STAGE + "/Content/Review/CharacterPages").visible = not phone or _review_section == "Character"
	get_node(STAGE + "/Content/Review/CharacterPages/Area/Character/Abilities").visible = not phone
	get_node(STAGE + "/Content/Review/BelongingsPages").visible = not phone or _review_section != "Character"
	get_node(STAGE + "/Content/Review/BelongingsPages/Area/Belongings/Equipment").visible = not phone or _review_section == "Gear"
	get_node(STAGE + "/Content/Review/BelongingsPages/Area/Belongings/Traits").visible = not phone or _review_section == "Traits"
	for section in ["Character", "Gear", "Traits"]:
		get_node(STAGE + "/Heading/ReviewTabs/" + section).set_pressed_no_signal(_review_section == section)

func capture_state() -> Dictionary:
	return {
		"choice": _choice, "details": _details, "review": _review_section,
		"page": int(get_node(LEFT + "/Choices").capture_state().get("page", 0)),
		"detail_page": int(get_node(STAGE + "/Content/Split/Detail/Pages").capture_state().get("page", 0)),
		"character_page": int(get_node(STAGE + "/Content/Review/CharacterPages").capture_state().get("page", 0)),
		"belongings_page": int(get_node(STAGE + "/Content/Review/BelongingsPages").capture_state().get("page", 0)),
	}

func restore_state(state: Dictionary) -> void:
	_choice = str(state.get("choice", _choice))
	_details = bool(state.get("details", false))
	_review_section = str(state.get("review", "Character"))
	if ROUTES.find(_route) < 4:
		_present_choices()
		_present_detail()
	get_node(LEFT + "/Choices").restore_state({"page": int(state.get("page", 0))})
	get_node(STAGE + "/Content/Split/Detail/Pages").restore_state({"page": int(state.get("detail_page", 0))})
	get_node(STAGE + "/Content/Review/CharacterPages").restore_state({"page": int(state.get("character_page", 0))})
	get_node(STAGE + "/Content/Review/BelongingsPages").restore_state({"page": int(state.get("belongings_page", 0))})
	_sync_navigation()

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
	for path in ["/Content/Split/Detail/Pages", "/Content/Review/CharacterPages", "/Content/Review/BelongingsPages"]:
		get_node(STAGE + path + "/Pager/Previous").text = _t("Previous")
		get_node(STAGE + path + "/Pager/Next").text = _t("Next")


func get_name_field() -> Control:
	return get_node(LEFT + "/Identity/Name")

func get_description_field() -> Control:
	return get_node(LEFT + "/Identity/Description")

func present_primary(text: String, disabled: bool) -> void:
	var index := ROUTES.find(_route)
	var roll := index in [1, 2, 3] and index + 1 == int(_draft.get("furthest_step", 1)) and (bool(_draft.get("roll_pending", false)) or bool(_draft.get("equipment_roll_pending", false)))
	roll = roll and not bool(_draft.get("pack_choice_pending", false)) and str(_draft.get("scroll_choice_slot", "")).is_empty()
	var symbol: Texture2D = _icon("dice") if roll else preload("res://rookframe/ui/icons/check.svg") if index == 5 else preload("res://rookframe/ui/icons/chevron-right.svg")
	set_primary(_t(text), disabled, symbol)

func set_status(message: String, error: bool = false) -> void:
	var name_error := error and _route == "create-identity" and message == "Enter a Character name before continuing."
	get_node(STAGE + "/Heading/Copy/Status").text = _t(message)
	get_node(STAGE + "/Heading/Copy/Status").visible = error and not message.is_empty() and not name_error
	get_name_field().error_text = _t(message) if name_error else ""
	if error and _route == "create-identity":
		_details = not name_error
		_sync_navigation()
		if name_error:
			get_node(LEFT + "/Identity/Name/Editor").grab_focus()
		else:
			get_node(MINIATURE + "MiniatureButtons/ChangeMiniature").grab_focus()

func present_creation(route: String, draft: Dictionary, _compact: bool) -> void:
	var next_route := "create-abilities" if route == "create-rolling" else route
	var changed := _route != next_route
	if changed:
		_details = false
		_review_section = "Character"
		get_node(STAGE + "/Content/Review/CharacterPages").restore_state({})
		get_node(STAGE + "/Content/Review/BelongingsPages").restore_state({})
	_route = next_route
	_draft = draft
	var index := maxi(0, ROUTES.find(_route))
	set_step(index)
	get_node(STAGE + "/Heading/Copy/Kicker").text = _t("Step %02d / 06") % (index + 1)
	get_node(STAGE + "/Heading/Copy/Title").text = _t(HEADINGS[index])
	get_node(STAGE + "/Heading/Copy/Subtitle").text = _t(SUBTITLES[index])
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
	var pending_choice := "pack" if bool(draft.get("pack_choice_pending", false)) else str(draft.get("scroll_choice_slot", ""))
	if is_compact() and not pending_choice.is_empty() and pending_choice != _pending_choice:
		_details = true
	_pending_choice = pending_choice
	_fit()

func _selected_row(id: String) -> void:
	if _route == "create-class":
		class_selected.emit(id)
	else:
		_choice = id
		_details = true
		_present_choices()
		_present_detail()
		_fit()

func _present_choices() -> void:
	var completed := 0
	for record in _records:
		if bool(record.get("complete", false)):
			completed += 1
	get_node(LEFT + "/Choices").configure(_records, _choice, _t("Choose a class") if _route == "create-class" else _t("All results recorded" if completed == _records.size() else "Roll in order"), _t("%d paths") % _records.size() if _route == "create-class" else "%d / %d" % [completed, _records.size()])

func _class_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index in range(CLASS_IDS.size()):
		var profile: Dictionary = CLASSES.new().profile(CLASS_IDS[index])
		rows.append({"id": CLASS_IDS[index], "title": _t(str(profile.title)), "subtitle": "", "value": "✓" if _draft.get("class_id") == CLASS_IDS[index] else "", "icon": _icon(CLASS_ICONS[index])})
	return rows

func _roll_rows(index: int) -> Array[Dictionary]:
	var profile: Dictionary = _draft.get("class_profile", {})
	var rows: Array[Dictionary] = []
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
			var resolved := _origin_result(str(term[0]), str(term[1]))
			rows.append(_roll_row(term[0], "1d%d" % term[2], str(resolved.value), _draft.has(term[1]), term[3], _t("Your class determines this starting roll."), str(resolved.detail)))
	else:
		var values: Dictionary = _draft.get("equipment_rolls", {})
		var icons := ["silver", "psychopomp", "food", "bag", "bag", "bag", "sword", "armor"]
		for term in _roll_plan.terms(_draft, 4):
			var title := str(term.name)
			var number := EQUIPMENT.find(title)
			var formula := "%dd%d" % [int(term.count), int(term.faces)]
			if title == "Silver":
				formula += " × 10"
			elif title == "Food":
				formula = _t("1d4 days")
			if number >= 0:
				var value := _equipment_meaning(title, _draft) if values.has(title) else ""
				rows.append(_roll_row(title, formula, value, values.has(title), icons[number], _t("Roll on the starting equipment table for your class."), value))
			else:
				var resolved := _conditional_result(title) if values.has(title) else {"value": "", "detail": ""}
				rows.append(_roll_row(title, "%dd%d" % [int(term.count), int(term.faces)], str(resolved.value), values.has(title), "dice", _t("Additional roll required by your starting equipment."), str(resolved.detail)))

	return rows

func _origin_result(title: String, key: String) -> Dictionary:
	if not _draft.has(key):
		return {"value": "", "detail": ""}
	var roll := int(_draft.get(key, 0))
	if title == "Origin":
		var origin := _t(str(_draft.get("origin", "")))
		return {"value": origin, "detail": origin}
	if title == "Decoction doses":
		return {"value": _t("%d doses / day") % roll, "detail": _t("Shared decoction doses: %d") % roll}
	var feature: Dictionary = CLASSES.new().decoction(roll) if title in ["First decoction", "Second decoction"] else CLASSES.new().feature(str(_draft.get("class_id", "")), roll)
	return {"value": _t(str(feature.get("name", ""))), "detail": _t(str(feature.get("rules", "")))}

func _conditional_result(title: String) -> Dictionary:
	var values: Dictionary = _draft.get("equipment_rolls", {})
	var value := int(values.get(title, 0))
	if title == "Hermit scroll family":
		return {"value": _t("Sacred scroll" if value == 1 else "Unclean scroll"), "detail": ""}
	if title in ["Hermit scroll", "Sacred scroll", "Unclean scroll"]:
		var sacred := title == "Sacred scroll" or (title == "Hermit scroll" and int(values.get("Hermit scroll family", 0)) == 1)
		var item: Dictionary = SCROLLS.new().item("sacred" if sacred else "unclean", value)
		return {"value": _t(str(item.get("name", ""))), "detail": _t(str(item.get("rules", "")))}
	if title in ["Red poison doses", "Life elixir doses"]:
		return {"value": _t("%d doses") % value, "detail": _t(title)}
	if title == "Monkey count":
		return {"value": str(value), "detail": _t("Monkey")}
	if title == "Dog hit points" or (title.begins_with("Monkey ") and title.ends_with(" hit points")):
		return {"value": "%d HP" % (value + 2), "detail": "%d + 2 = %d HP" % [value, value + 2]}
	return {"value": str(value), "detail": ""}

func _roll_row(title: String, formula: String, value: String, complete: bool, icon_name: String, description: String, explanation: String) -> Dictionary:
	var rolling: Array = _draft.get("rolling", [])
	var in_flight := false
	for name in rolling:
		if str(name) == title:
			in_flight = true
	var current := title == str(_draft.get("active_roll", ""))
	var pending := bool(_draft.get("roll_pending", false)) or bool(_draft.get("equipment_roll_pending", false))
	return {"id": title, "title": _t(title), "subtitle": formula, "formula": formula, "value": value if complete else _t("Rolling…") if in_flight else _t("Next") if current and pending and bool(_draft.get("roll_ready", false)) else "—", "complete": complete, "pending": not complete, "icon": _icon(icon_name), "icon_name": icon_name, "description": description, "explanation": explanation}

func _reset_detail() -> Control:
	var detail := get_node(DETAIL) as Control
	for name in ["ClassBody", "RollInfo/FormulaRow", "RollOutcome/Result", "RollOutcome/ResultCopy", "PackChoices", "ScrollChoice", "Appearance"]:
		get_node(DETAIL + "/" + name).visible = false
	get_node(DETAIL + "/Heading/Icon").visible = true
	get_node(DETAIL + "/RollInfo/Flavor").text = ""
	get_node(DETAIL + "/NoteRow/Note").text = _t("Results stay with you when you go back.")
	get_node(DETAIL + "/NoteRow/Icon").texture = _icon("dice")
	return detail

func _present_detail() -> void:
	var key := _route + ":" + _choice
	if key != _detail_key:
		get_node(STAGE + "/Content/Split/Detail/Pages").restore_state({})
	_detail_key = key
	var detail := _reset_detail()
	if _route == "create-class":
		var profile: Dictionary = _draft.get("class_profile", {})
		var herb := str(_draft.get("class_id", "")) == "occult-herbmaster"
		get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("Born of the mushroom" if herb else "Starting class")
		get_node(DETAIL + "/Heading/Copy/Title").text = _t(str(profile.get("title", "No Class")))
		get_node(DETAIL + "/Heading/Icon").texture = _icon(CLASS_ICONS[maxi(0, CLASS_IDS.find(str(_draft.get("class_id", "classless"))))])
		get_node(DETAIL + "/RollInfo/Flavor").text = _t("Raised in the glade. Your body is hardy; your remedies are stranger still." if herb else "Your class determines starting rolls, equipment and traits.")
		get_node(DETAIL + "/ClassBody").visible = true
		_set_fact("HitPoints", "Hit Points", "1d%d + TOU" % int(profile.get("hp_faces", 8)))
		_set_fact("Silver", "Silver", "%dd6 × 10" % int(profile.get("silver_count", 2)))
		_set_fact("Omens", "Omens", "1d%d" % int(profile.get("omen_faces", 2)))
		get_node(DETAIL + "/ClassBody/FactsColumn/Flavor").text = get_node(DETAIL + "/RollInfo/Flavor").text
		_present_class_rules()
		get_node(DETAIL + "/NoteRow/Note").text = _t("Next: roll your four abilities, then Hit Points. Your class modifies the rolls automatically.")
		return
	var row := _record(_choice)
	if row.is_empty():
		return
	get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("Recorded result" if bool(row.get("complete", false)) else "Next roll" if _choice == _active else "Upcoming roll")
	get_node(DETAIL + "/Heading/Copy/Title").text = str(row.title)
	get_node(DETAIL + "/Heading/Icon").texture = _icon(str(row.get("icon_name", "dice")))
	get_node(DETAIL + "/RollInfo/Flavor").text = str(row.get("description", ""))
	get_node(DETAIL + "/RollInfo/FormulaRow").visible = row.has("formula")
	get_node(DETAIL + "/RollInfo/FormulaRow/Row/Value").text = str(row.get("formula", ""))
	get_node(DETAIL + "/RollOutcome/Result").visible = bool(row.get("complete", false))
	get_node(DETAIL + "/RollOutcome/Result/Content/Value").text = str(row.get("value", ""))
	var rolls: Dictionary = _draft.get("roll_faces", {})
	var raw: Array = rolls.get(_choice, [])
	var faces: Array[String] = []
	for value in raw:
		faces.append(str(int(value)))
	get_node(DETAIL + "/RollInfo/FormulaRow/Row/Caption").text = _t("rolled %s") % _lines(faces," + ") if not faces.is_empty() else _t("starting roll")
	get_node(DETAIL + "/RollOutcome/Result/Content/Label").text = str(row.title)
	get_node(DETAIL + "/RollOutcome/ResultCopy").visible = not str(row.get("explanation", "")).is_empty()
	get_node(DETAIL + "/RollOutcome/ResultCopy").text = _t(str(row.get("explanation", "")))
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
		get_node(DETAIL + "/RollInfo/Flavor").text = _t("Choose your starting container or transport.")
		get_node(DETAIL + "/RollInfo/FormulaRow").visible = false
		get_node(DETAIL + "/RollOutcome/Result").visible = false
		get_node(DETAIL + "/RollOutcome/ResultCopy").visible = false
		get_node(DETAIL + "/Heading/Copy/Kicker").text = _t("1d6 · rolled %d") % int(values.get("Equipment pack", 0))
		get_node(DETAIL + "/NoteRow/Note").text = _t("Choose one pack below") if bool(_draft.get("pack_choice_pending", true)) else _t("Selected: %s") % _t(str(_draft.get("pack", "Nothing")))

func _present_class_rules() -> void:
	var container := get_node(DETAIL + "/ClassBody/Rules") as VBoxContainer
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	var phone := is_compact()
	var tablet := is_tablet()
	container.add_theme_constant_override("separation",8 if phone else 6 if tablet else 16)
	var profile: Dictionary = _draft.get("class_profile", {})
	var offsets: Dictionary = profile.get("ability_offsets", {})
	var parts: Array[Array] = []
	if str(_draft.get("class_id", "")) == "occult-herbmaster":
		for pair in [["Tough as wood", "Toughness"], ["Low in protein", "Strength"]]:
			parts.append([_t(pair[0]), _t("%s is rolled with 3d6 %+d.") % [_t(pair[1]),int(offsets.get(pair[1],0))]])
		parts.append([_t("Portable laboratory"),_t("Two random decoctions. d4 doses a day.")])
	else:
		for ability in ["Agility","Presence","Strength","Toughness"]:
			if offsets.has(ability):
				parts.append([_t(ability),_t("Starting roll: 3d6 %+d") % int(offsets[ability])])
		var rules: Array = _draft.get("class_rules", [])
		for rule in rules:
			parts.append(["",_t(str(rule))])
	if parts.is_empty():
		parts.append([_t("Starting abilities"),_t("Roll 3d6 for each ability.")])
	for part in parts:
		var rule := preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creation_class_rule.tscn").instantiate()
		container.add_child(rule)
		rule.add_theme_constant_override("separation",2 if phone or tablet else 4)
		var title := rule.get_node(^"Title") as Label
		var copy := rule.get_node(^"Copy") as Label
		title.text = part[0]
		title.visible = not part[0].is_empty()
		copy.text = part[1]
		_style_text(title,18 if phone else 20 if tablet else 24,1.1 if phone else 1.2)
		_style_text(copy,15 if phone else 16 if tablet else 19,1.15 if phone else 1.3)

func _present_identity() -> void:
	_reset_detail()
	var appearance := get_node(DETAIL + "/Appearance")
	appearance.visible = true
	var miniature: Dictionary = _draft.get("preferred_miniature", {})
	var title := str(miniature.get("title", ""))
	var package := ""
	if not miniature.is_empty() and facade != null:
		var entry := facade.content.read(SDK.ContentReference.new(str(miniature.package_id), str(miniature.local_id)))
		if entry.ok:
			title = entry.content_entry.localized_title
			package = entry.content_entry.package_title
	appearance.miniature(i18n, title, package, not miniature.is_empty())
	var key := str(miniature.get("package_id", "")) + "/" + str(miniature.get("local_id", ""))
	if key != _preview_key and facade != null:
		_preview_key = key
		if not miniature.is_empty():
			facade.content.preview_miniature(SDK.ContentReference.new(str(miniature.package_id), str(miniature.local_id)), get_node(MINIATURE + "MiniaturePreview"))

func _present_context() -> void:
	var context := get_node(CONTEXT)
	var name := str(_draft.get("name", "")).strip_edges()
	get_node(CONTEXT + "/Name/Title").text = name if not name.is_empty() else _t("Unnamed soul")
	get_node(CONTEXT + "/Name/Class").text = _t(str(_draft.get("class_title", "No Class")))
	get_node(CONTEXT + "/PortraitVitals/Vitals/HitPoints/Row/Value").text = "%s / %s" % [int(_draft.hit_points), int(_draft.maximum_hit_points)] if _draft.has("hit_points") else "—"
	var totals: Dictionary = _draft.get("equipment_rolls", {})
	for key in ["Silver", "Omens"]:
		var value := str(int(totals[key]) * (10 if key == "Silver" else 1)) if totals.has(key) else "—" if _draft.has("equipment_rolls") else str(_draft.get(key.to_lower(), "—"))
		get_node(CONTEXT + "/PortraitVitals/Vitals/" + key + "/Row/Value").text = value
	var abilities: Dictionary = _draft.get("abilities", {})
	for key in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(key, {})
		get_node(CONTEXT + "/Attributes/" + key + "/Row/Value").text = _modifier(int(ability.get("modifier", 0))) if abilities.has(key) else "—"
	get_node(CONTEXT + "/History").text = _t(str(_draft.get("origin", ""))) if not str(_draft.get("origin", "")).is_empty() else _t("Your history, traits and belongings will appear as you create your character.")
	var history: Array[Dictionary] = []
	if not str(_draft.get("origin", "")).is_empty():
		history.append({"icon": "character", "text": _t(str(_draft.origin))})
	if _draft.has("decoction_doses"):
		history.append({"icon": "elixir", "text": _t("%d doses / day") % int(_draft.decoction_doses)})
	var inventory: Array = _draft.get("inventory", [])
	for kind in ["Weapon", "Armor"]:
		var items: Array = []
		for raw_item in inventory:
			var item: Dictionary = raw_item
			if item.get("kind", "") == kind:
				items.append(item)
		if not items.is_empty():
			history.append({"icon": "sword" if kind == "Weapon" else "armor", "text": _inventory_text(items).replace("\n", " · ")})
	for index in range(4):
		var row := get_node(CONTEXT + ["/PhoneHistory/Line0", "/PhoneHistory/Line1", "/PhoneHistory/Line2", "/PhoneHistory/Line3"][index])
		row.visible = index < history.size()
		(row.get_node(^"Text") as Label).text = ""
		if row.visible:
			(row.get_node(^"Icon") as TextureRect).texture = _icon(str(history[index].icon))
			(row.get_node(^"Text") as Label).text = str(history[index].text)
			(row.get_node(^"Text") as Label).tooltip_text = str(history[index].text)

func _present_review() -> void:
	var review := get_node(STAGE + "/Content/Review")
	var miniature: Dictionary = _draft.get("preferred_miniature", {})
	var identity: Array[Dictionary] = [_pair("Class", _t(str(_draft.get("class_title", "")))), _pair("Origin", _t(str(_draft.get("origin", ""))))]
	get_node(STAGE + "/Content/Review/CharacterPages/Area/Character/Identity").configure(_t("Character"), _icon("character"), identity, str(_draft.get("description", "")) if not str(_draft.get("description", "")).is_empty() else _t("No description added."))
	var values: Array[Dictionary] = []
	var abilities: Dictionary = _draft.get("abilities", {})
	for ability in [["Agility", "AGI"], ["Presence", "PRE"], ["Strength", "STR"], ["Toughness", "TOU"]]:
		var score: Dictionary = abilities.get(ability[0], {})
		values.append(_pair(ability[1], _modifier(int(score.get("modifier", 0)))))
	var vitals: Array[Dictionary] = [_pair("Hit Points", "%s / %s" % [int(_draft.get("hit_points", 1)), int(_draft.get("maximum_hit_points", 1))]), _pair("Preferred miniature", str(miniature.get("title", _t("None"))))]
	get_node(STAGE + "/Content/Review/CharacterPages/Area/Character/Abilities").configure(_t("Abilities"), _icon("strength"), vitals)
	get_node(STAGE + "/Content/Review/CharacterPages/Area/Character/Abilities").set_stats(values)
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
	get_node(STAGE + "/Content/Review/BelongingsPages/Area/Belongings/Equipment").configure(_t("Equipment"), _icon("bag"), equipment)
	var traits: Array[Dictionary] = []
	var traits_data: Array = _draft.get("traits", [])
	for raw_trait in traits_data:
		var trait_data: Dictionary = raw_trait
		traits.append(_pair(_t(str(trait_data.get("name", ""))), _t(str(trait_data.get("rules", "")))))
	if _draft.has("decoction_doses"):
		traits.append(_pair("Portable laboratory", _t("%d doses / day") % int(_draft.decoction_doses)))
	var modifiers: Array[String] = []
	var profile: Dictionary = _draft.get("class_profile", {})
	var offsets: Dictionary = profile.get("ability_offsets", {})
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		if offsets.has(ability):
			modifiers.append(_t("%s %+d to the starting roll.") % [_t(ability), int(offsets.get(ability, 0))])
	get_node(STAGE + "/Content/Review/BelongingsPages/Area/Belongings/Traits").configure(_t("Class traits"), _icon("herbs"), traits, _lines(modifiers))

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

func _reset_miniature() -> void:
	miniature_reset_requested.emit()

func _request_pack(pack: String) -> void:
	pack_selected.emit(pack)

func _request_scroll(disposition: String) -> void:
	scroll_selected.emit(str(_draft.get("scroll_choice_slot", "")), disposition)

func _name_changed(value: String) -> void:
	get_node(CONTEXT + "/Name/Title").text = value if not value.strip_edges().is_empty() else _t("Unnamed soul")
	if not value.strip_edges().is_empty():
		get_name_field().error_text = ""

func _record(id: String) -> Dictionary:
	for record in _records:
		if record.id == id:
			return record
	return {}

func _set_fact(id: String, label: String, value: String) -> void:
	get_node(DETAIL + "/ClassBody/FactsColumn/Facts/Row/" + id + "/Label").text = _t(label)
	get_node(DETAIL + "/ClassBody/FactsColumn/Facts/Row/" + id + "/Value").text = value
