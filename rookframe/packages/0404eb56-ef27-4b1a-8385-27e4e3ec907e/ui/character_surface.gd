extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const ACTIONS = preload(ROOT + "logic/character_actions.gd")
const PROJECTION = preload(ROOT + "ui/sheet_projection.gd")
const DRAFT = preload(ROOT + "ui/sheet_draft.gd")
const FIELD = preload(ROOT + "ui/sheet_entry_field.tscn")
const BROKEN = preload(ROOT + "logic/broken_incident.gd")
const ABILITY = preload(ROOT + "logic/ability_throw.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const HEALTH = preload(ROOT + "logic/health_action.gd")
const POWER = preload(ROOT + "logic/power_action.gd")
const SPECIAL = preload(ROOT + "logic/special_action.gd")
const RULES = preload(ROOT + "logic/special_rules.gd")
const POWERS = preload(ROOT + "logic/powers.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const EQUIPMENT = preload(ROOT + "logic/equipment.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const HEART = preload("res://rookframe/ui/icons/character/heart.svg")
const MAGIC = preload("res://rookframe/ui/icons/character/palms.svg")
const DICE = preload("res://rookframe/ui/icons/character/dice.svg")
const CHAPTERS := ["Character", "Powers", "Inventory", "Journal", "Appearance"]
@export var navigation: Resource
@onready var _chapters = [get_node(^"Margin/Layout/Body/Chapter/Tabs/TabCharacter"), get_node(^"Margin/Layout/Body/Chapter/Tabs/TabPowers"), get_node(^"Margin/Layout/Body/Chapter/Tabs/TabInventory"), get_node(^"Margin/Layout/Body/Chapter/Tabs/TabJournal"), get_node(^"Margin/Layout/Body/Chapter/Tabs/TabAppearance")]
const _ability_paths := {
	"Strength": ^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength",
	"Agility": ^"Margin/Layout/Body/Core/Abilities/AgilityRow/Agility",
	"Presence": ^"Margin/Layout/Body/Core/Abilities/PresenceRow/Presence",
	"Toughness": ^"Margin/Layout/Body/Core/Abilities/ToughnessRow/Toughness",
}
const _ability_edit_paths := {
	"StrengthEdit": ^"Margin/Layout/Body/Core/Abilities/StrengthRow/StrengthEdit",
	"AgilityEdit": ^"Margin/Layout/Body/Core/Abilities/AgilityRow/AgilityEdit",
	"PresenceEdit": ^"Margin/Layout/Body/Core/Abilities/PresenceRow/PresenceEdit",
	"ToughnessEdit": ^"Margin/Layout/Body/Core/Abilities/ToughnessRow/ToughnessEdit",
}
const _vital_paths := {
	"HitPoints": ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPoints",
	"PowerUses": ^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUses",
	"Omens": ^"Margin/Layout/Body/Core/Likeness/Vitals/Omens",
}
const _vital_group_paths := {
	"HitPointsEdit": ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit",
	"PowerUsesEdit": ^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUsesEdit",
	"OmensEdit": ^"Margin/Layout/Body/Core/Likeness/Vitals/OmensEdit",
}
const _vital_edit_paths := {
	"HitPointsCurrent": ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrent",
	"HitPointsMaximum": ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsMaximum",
	"PowerUsesCurrent": ^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUsesEdit/PowerUsesCurrent",
	"OmensCurrent": ^"Margin/Layout/Body/Core/Likeness/Vitals/OmensEdit/OmensCurrent",
}
const _incident_paths := {
	"NextRound": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/NextRound",
	"UndoRound": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/UndoRound",
	"Recover": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Recover",
	"AdvanceHour": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/AdvanceHour",
	"UndoHour": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/UndoHour",
	"Treat": ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Treat",
}
var _projection := PROJECTION.new()
var _draft := DRAFT.new()
var _actor: SDK.Actor
var _nav: Dictionary = {}
var _items: Array = []
var _weapons: Array[Dictionary] = []
var _detail := ""
var _detail_tab := 0
var _item_edit := false
var _fields: Array = []
var _opener
var _opened_entry := ""
var _return_detail := ""
var _focus_detail_action := false
var _action: ACTION
var _ability: ABILITY
var _action_kind := ""
var _action_input: Dictionary = {}
var _rest := "breath"
var _selection := ""
var _rerolls: Array[int] = []
var _new_item: Dictionary = {}
var _busy := false
var _refresh_pending := false
var _action_pending := false
var _detail_pending := false
var _elapsed := 0.0
var _phone := false
var _setting := false
var _end_after_roll := false
var _rendered_chapter := -1
var _locale := I18N.new()

func ready() -> void:
	_locale.bind(sdk)
	for index in range(CHAPTERS.size()):
		_chapters[index].pressed.connect(_chapter.bind(index))
	get_node(^"Margin/Layout/Header/Edit").pressed.connect(_edit)
	get_node(^"Margin/Layout/Header/SaveSheet").pressed.connect(_save_sheet)
	get_node(^"Margin/Layout/Header/CancelSheet").pressed.connect(_cancel_edit)
	get_node(^"Margin/Layout/Header/Close").pressed.connect(_close)
	get_node(^"Margin/Layout/Header/Rest").pressed.connect(_workflow.bind("rest", ""))
	get_node(^"Margin/Layout/Header/Improve").pressed.connect(_workflow.bind("improve", ""))
	get_node(^"Margin/Layout/Header/Name").pressed.connect(_name_pressed)
	get_node(^"Margin/Layout/Header/NameEdit").value_changed.connect(_core_typed.bind("name"))
	get_node(^"Margin/Layout/Body/Core/Origin").pressed.connect(_open_detail.bind("profile"))
	for key in PROJECTION.ABILITIES:
		get_node(_ability_paths.get(str(key), ^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength")).pressed.connect(_open_detail.bind("ability:" + str(key)))
		get_node(_ability_edit_paths.get(str(key) + "Edit", ^"Margin/Layout/Body/Core/Abilities/StrengthRow/StrengthEdit")).value_changed.connect(_core_typed.bind(str(key)))
	for pair in [["HitPointsCurrent", "hit_points"], ["HitPointsMaximum", "maximum_hit_points"], ["PowerUsesCurrent", "power_uses"], ["OmensCurrent", "omens"]]:
		get_node(_vital_edit_paths.get(str(pair[0]), ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrent")).value_changed.connect(_core_typed.bind(str(pair[1])))
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/HitPoints").pressed.connect(_open_detail.bind("resource:hit_points"))
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUses").pressed.connect(_open_detail.bind("resource:power_uses"))
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/Omens").pressed.connect(_open_detail.bind("resource:omens"))
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmensEdit").value_changed.connect(_core_typed.bind("omens"))
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmens").pressed.connect(_open_detail.bind("resource:omens"))
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickSilver").pressed.connect(_open_detail.bind("resource:silver"))
	get_node(^"Margin/Layout/Body/Core/ReadyWeapon").pressed.connect(_open_detail.bind("ready_weapon"))
	get_node(^"Margin/Layout/Body/Core/Weapon").item_selected.connect(_weapon_selected)
	get_node(^"Margin/Layout/Body/Core/WeaponActions/Attack").pressed.connect(_roll_combat.bind("attack"))
	get_node(^"Margin/Layout/Body/Core/WeaponActions/Damage").pressed.connect(_roll_combat.bind("damage"))
	get_node(^"Margin/Layout/Body/Core/ManageEquipment").pressed.connect(_chapter.bind(2))
	get_node(^"Margin/Layout/Body/Core/Protection").pressed.connect(_open_detail.bind("protection"))
	get_node(^"Margin/Layout/Body/Core/Dodge").pressed.connect(_workflow.bind("ability", "Agility"))
	get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").selected.connect(_open_detail)
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").selected.connect(_open_detail)
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").selected.connect(_open_detail)
	get_node(^"Margin/Layout/Body/Chapter/Section").item_selected.connect(_section_selected)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/Back").pressed.connect(_back)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailTabs/Overview").pressed.connect(_detail_tab_selected.bind(0))
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailTabs/Details").pressed.connect(_detail_tab_selected.bind(1))
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").pressed.connect(_primary_action)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/SecondaryAction").pressed.connect(_secondary_action)
	get_node(^"Margin/Layout/Body/Core/ConditionReminder").pressed.connect(_chapter.bind(0))
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Broken").pressed.connect(_start_broken)
	for pair in [["NextRound", "next"], ["UndoRound", "undo"], ["Recover", "recover"], ["AdvanceHour", "next"], ["UndoHour", "undo"], ["Treat", "treat"]]:
		get_node(_incident_paths.get(str(pair[0]), ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/NextRound")).pressed.connect(_incident.bind(str(pair[1])))
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureButtons/ChangeMiniature").pressed.connect(_choose_miniature)
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureButtons/ClearMiniature").pressed.connect(_clear_miniature)
	get_node(^"Margin/Layout/Picker").closed.connect(_picker_closed)
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitButtons/ChangePortrait").pressed.connect(_choose_portrait)
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitButtons/ClearPortrait").pressed.connect(_clear_portrait)
	closed.connect(_closed)
	resized.connect(_density)
	if sdk != null:
		sdk.world_changed.connect(_world_changed)
	_density()

func opened(id: SDK.ActorId) -> void:
	if sdk == null:
		return
	var source := sdk.actors.read(id)
	if not source.ok:
		_status(source.message)
		return
	if _actor != null and _actor.id.value != id.value:
		_remember()
		_end_action()
		_draft.discard()
	_actor = source.actor
	_nav = navigation.read(sdk.context().session_id, id.value)
	_detail = ""
	_refresh()

func _world_changed() -> void:
	_refresh_pending = true

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.5:
		_elapsed = 0.0
		if _action != null:
			_action.refresh()
		if _ability != null:
			_ability.refresh()
	if _refresh_pending and not _busy and _actor != null:
		_refresh_pending = false
		var latest := sdk.actors.read(_actor.id)
		if latest.ok:
			var before := int(_data().get("hit_points", 0))
			_actor = latest.actor
			if before > 0 and int(_data().get("hit_points", 0)) <= 0:
				_nav["chapter"] = 0
				_detail = ""
			_refresh()
		else:
			_draft.discard()
			_end_action()
			_close()
	if _action_pending:
		_action_pending = false
		if _end_after_roll and _action != null and _action.pending and _action.state != "pending":
			_end_action()
			_status(ACTION.ENDED)
		_present_roll()
		if _detail.begins_with("workflow:"):
			_request_detail()
		elif _action != null:
			_status(_action.message)

	if _detail_pending:
		_detail_pending = false
		_render_detail()
		if _focus_detail_action:
			_focus_detail_action = false
			get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").grab_focus()

func _request_detail() -> void:
	_detail_pending = true

func _refresh() -> void:
	if _actor == null:
		return
	var data: Dictionary = _actor.data
	_items = ACTIONS.new(sdk, _actor.id).inventory(data)
	if _draft.active:
		if _draft.refresh(_projection.fields(data), _projection.identities(data)):
			_request_detail()
	_core(data)
	_collections(data)
	_render_condition(data)
	_show_route()
	if not _detail.is_empty():
		_refresh_detail()
	_remember()

func _core(data: Dictionary) -> void:
	_setting = true
	get_node(^"Margin/Layout/Header/Name").visible = not _draft.active
	get_node(^"Margin/Layout/Header/NameEdit").visible = _draft.active
	get_node(^"Margin/Layout/Header/NameEdit").value = _draft.value("name") if _draft.active else str(data.get("name", ""))
	get_node(^"Margin/Layout/Header/Name").text = str(data.get("name", "Character"))
	get_node(^"Margin/Layout/Body/Core/Class").text = str(data.get("class_title", "Character"))
	get_node(^"Margin/Layout/Body/Core/Origin").text = str(data.get("origin", "Origin"))
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/HitPoints").configure("Hit points", int(data.get("hit_points", 0)), "/ %d" % int(data.get("maximum_hit_points", 1)), int(data.get("maximum_hit_points", 1)))
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUses").configure("Power uses", int(data.get("power_uses", 0)), "/ %d" % int(data.get("power_uses_total", 0)) if data.has("power_uses_total") else "")
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/Omens").configure("Omens", int(data.get("omens", 0)), "available")
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmensEdit").visible = _phone and _draft.active
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmensEdit").value = _draft.value("omens") if _draft.active else str(data.get("omens", 0))
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmens").visible = not _draft.active
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmens").text = "%d Omens" % int(data.get("omens", 0))
	get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickSilver").text = "%d Silver" % int(data.get("silver", 0))
	var values := _projection.fields(data)
	for pair in [["HitPointsCurrent", "hit_points"], ["HitPointsMaximum", "maximum_hit_points"], ["PowerUsesCurrent", "power_uses"], ["OmensCurrent", "omens"]]:
		get_node(_vital_edit_paths.get(str(pair[0]), ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrent")).value = _draft.value(str(pair[1])) if _draft.active else str(values.get(str(pair[1]), ""))
	for ability in PROJECTION.ABILITIES:
		var key := str(ability)
		get_node(_ability_paths.get(key, ^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength")).configure({"Strength": "STR", "Agility": "AGI", "Presence": "PRE", "Toughness": "TOU"}.get(key, key) if _phone else key, int(values.get(key, 0)))
		get_node(_ability_paths.get(key, ^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength")).visible = not _draft.active
		get_node(_ability_edit_paths.get(key + "Edit", ^"Margin/Layout/Body/Core/Abilities/StrengthRow/StrengthEdit")).value = _draft.value(key) if _draft.active else str(values.get(key, "0"))
		get_node(_ability_edit_paths.get(key + "Edit", ^"Margin/Layout/Body/Core/Abilities/StrengthRow/StrengthEdit")).visible = _draft.active
	for vital in ["HitPoints", "PowerUses", "Omens"]:
		get_node(_vital_paths.get(str(vital), ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPoints")).visible = not _draft.active and (not _phone or vital != "Omens")
		get_node(_vital_group_paths.get(str(vital) + "Edit", ^"Margin/Layout/Body/Core/Likeness/Vitals/HitPointsEdit")).visible = _draft.active and (not _phone or vital != "Omens")
	_weapons = []
	get_node(^"Margin/Layout/Body/Core/Weapon").clear()
	for raw in _items:
		var item: Dictionary = raw
		if str(item.get("kind", "")) == "Weapon" and item.get("equipped", false) and int(item.get("quantity", 0)) > 0 and not item.get("broken", false):
			_weapons.append(item)
	if str(data.get("class_id", "")) == "fanged-deserter":
		_weapons.append({"inventory_id": "class:bite", "name": "Bite", "damage": "d6", "equipped": true, "quantity": 1})
	var selected := 0
	for index in range(_weapons.size()):
		var item: Dictionary = _weapons[index]
		get_node(^"Margin/Layout/Body/Core/Weapon").add_item(str(item.get("name", "Weapon")) + " · " + str(item.get("damage", "")))
		if str(item.inventory_id) == str(_nav.get("weapon", "")):
			selected = index
	if _weapons.is_empty():
		get_node(^"Margin/Layout/Body/Core/Weapon").add_item("No ready weapon")
		_nav["weapon"] = ""
	else:
		_nav["weapon"] = str(_weapons[selected].inventory_id)
	get_node(^"Margin/Layout/Body/Core/Weapon").select(selected)
	get_node(^"Margin/Layout/Body/Core/ReadyWeapon").text = "No ready weapon ›" if _weapons.is_empty() else str(_weapons[selected].get("name", "Weapon")) + " · " + str(_weapons[selected].get("damage", "")) + " ›"
	var protection: Array[String] = []
	for raw in _items:
		var item: Dictionary = raw
		if item.get("equipped", false) and str(item.get("kind", "")) in ["Armor", "Shield"]:
			protection.append(str(item.get("name", "")) + " " + str(item.get("reduction", "")))
	get_node(^"Margin/Layout/Body/Core/Protection").text = "Protection & reactions ›" if protection.is_empty() else _projection.text(protection) + " ›"
	var playable := _owner() and not _draft.active and BROKEN.new().can_act(data)
	get_node(^"Margin/Layout/Body/Core/WeaponActions/Attack").disabled = not playable or _weapons.is_empty()
	get_node(^"Margin/Layout/Body/Core/WeaponActions/Damage").disabled = not _owner() or _draft.active or _weapons.is_empty()
	get_node(^"Margin/Layout/Body/Core/Dodge").disabled = not playable
	get_node(^"Margin/Layout/Header/Edit").disabled = not _owner() or _action_live()
	get_node(^"Margin/Layout/Header/Rest").disabled = not _owner() or _draft.active or _action_live() or BROKEN.new().is_dead(data)
	get_node(^"Margin/Layout/Header/Improve").disabled = not _owner() or _draft.active or _action_live()
	get_node(^"Margin/Layout/Header/Edit").visible = not _draft.active
	get_node(^"Margin/Layout/Header/SaveSheet").visible = _draft.active
	get_node(^"Margin/Layout/Header/CancelSheet").visible = _draft.active
	_render_portrait(data)
	_setting = false

func _collections(data: Dictionary) -> void:
	_capture_pages()
	var chapter := int(_nav.get("chapter", 0))
	var rows := _projection.collections(data, _items, chapter, _actor.id.value, sdk)
	var primary: Array[Dictionary] = rows.primary
	var resources: Array[Dictionary] = rows.resources
	var companions: Array[Dictionary] = rows.companions
	var heading := str(rows.heading)
	get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").configure(primary, "", heading, str(primary.size()))
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").configure(resources, "", "RESOURCES" if chapter == 0 else "DECOCTIONS & RESOURCES", str(resources.size()))
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").configure(companions, "", "COMPANIONS", str(companions.size()))
	_rendered_chapter = chapter
	_restore_pages()

func _capture_pages() -> void:
	if _nav.is_empty():
		return
	var pages: Dictionary = _nav.get("pages", {})
	var chapter := str(_rendered_chapter)
	if _rendered_chapter < 0:
		return
	pages[chapter + ":primary"] = get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").capture_state()
	pages[chapter + ":resources"] = get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").capture_state()
	pages[chapter + ":companions"] = get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").capture_state()
	_nav["pages"] = pages

func _restore_pages() -> void:
	var pages: Dictionary = _nav.get("pages", {})
	var chapter := str(_nav.get("chapter", 0))
	var primary: Dictionary = pages.get(chapter + ":primary", {})
	var resources: Dictionary = pages.get(chapter + ":resources", {})
	var companions: Dictionary = pages.get(chapter + ":companions", {})
	get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").restore_state(primary)
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").restore_state(resources)
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").restore_state(companions)

func _show_route() -> void:
	var chapter := int(_nav.get("chapter", 0))
	var details := not _detail.is_empty()
	get_node(^"Margin/Layout/Header/Rest").visible = not _phone or _detail == "profile"
	get_node(^"Margin/Layout/Header/Improve").visible = not _phone or _detail == "profile"
	get_node(^"Margin/Layout/Body/Chapter/Tabs").visible = not details
	get_node(^"Margin/Layout/Body/Core").visible = not (_phone and (details or chapter == 4))
	get_node(^"Margin/Layout/Body/Chapter/Collections").visible = not details and chapter in [0, 1, 2]
	get_node(^"Margin/Layout/Body/Chapter/JournalPanel").visible = not details and chapter == 3
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel").visible = not details and chapter == 4
	get_node(^"Margin/Layout/Body/Chapter/Detail").visible = details
	get_node(^"Margin/Layout/Body/Chapter/Condition").visible = not details and chapter == 0 and not _projection.condition(_actor.data).is_empty()
	get_node(^"Margin/Layout/Body/Chapter/Section").visible = _phone and not details and chapter in [0, 1, 2]
	get_node(^"Margin/Layout/Body/Chapter/QuickResources").visible = _phone and not details and chapter != 4
	get_node(^"Margin/Layout/Body/Chapter/Section").clear()
	for title in (["Features & traits", "Resources", "Companions"] if chapter == 0 else ["Powers", "Decoctions & resources"] if chapter == 1 else ["Inventory", "Resources"]):
		get_node(^"Margin/Layout/Body/Chapter/Section").add_item(str(title))
	get_node(^"Margin/Layout/Body/Chapter/Section").select(mini(int(_nav.get("section", 0)), get_node(^"Margin/Layout/Body/Chapter/Section").item_count - 1))
	get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").visible = not _phone or get_node(^"Margin/Layout/Body/Chapter/Section").selected == 0
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary").visible = not _phone or get_node(^"Margin/Layout/Body/Chapter/Section").selected != 0
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").visible = not _phone or get_node(^"Margin/Layout/Body/Chapter/Section").selected == 1
	get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").visible = chapter == 0 and (not _phone or get_node(^"Margin/Layout/Body/Chapter/Section").selected == 2)
	if _phone and get_node(^"Margin/Layout/Body/Chapter/Condition").visible:
		get_node(^"Margin/Layout/Body/Chapter/Collections").visible = false
		get_node(^"Margin/Layout/Body/Chapter/Section").visible = false
	for index in range(CHAPTERS.size()):
		_chapters[index].set_pressed_no_signal(index == chapter)
	if chapter == 4:
		_appearance()

func _chapter(index: int) -> void:
	_capture_pages()
	_leave_workflow()
	_detail = ""
	_nav["chapter"] = index
	_nav["section"] = 0
	_collections(_actor.data)
	_show_route()
	_remember()
	_chapters[index].grab_focus()

func _section_selected(index: int) -> void:
	_nav["section"] = index
	_show_route()
	_remember()

func _weapon_selected(index: int) -> void:
	if not _setting and index < _weapons.size():
		_nav["weapon"] = str(_weapons[index].inventory_id)
		_remember()

func _remember() -> void:
	if _actor != null and not _nav.is_empty():
		navigation.remember(_actor.id.value, _nav)

func _owner() -> bool:
	return _actor != null and _actor.access_level == "Owner"

func _edit() -> void:
	if not _owner() or _action_live():
		return
	_draft.begin(_projection.fields(_actor.data), _projection.identities(_actor.data))
	_refresh()

func _core_typed(text: String, field: String) -> void:
	if _draft.active and not _setting:
		_draft.change(field, text)

func _save_sheet() -> void:
	if _busy or not _draft.active:
		return
	_busy = true
	get_node(^"Margin/Layout/Header/SaveSheet").disabled = true
	var result := await ACTIONS.new(sdk, _actor.id).correct_many(_draft.changes(), _draft.identities())
	_busy = false
	get_node(^"Margin/Layout/Header/SaveSheet").disabled = false
	if result.ok:
		_draft.discard()
		_actor = result.actor
		_refresh()
		_request_detail()
		_status("Sheet saved.")
	else:
		_status(result.message)

func _cancel_edit() -> void:
	_draft.discard()
	_refresh_pending = true
	_refresh()
	_request_detail()

func _name_pressed() -> void:
	_open_detail("profile")

func _open_detail(id: String) -> void:
	if id == "empty":
		return
	_capture_pages()
	_remember_opener(id)
	_detail = id
	_detail_tab = 0
	_item_edit = false
	_new_item = {}
	_request_detail()
	_show_route()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/Back").grab_focus()

func _detail_tab_selected(index: int) -> void:
	_detail_tab = index
	_request_detail()

func _clear_detail() -> void:
	_fields = []
	for child in get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").get_children():
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").remove_child(child)
		child.queue_free()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").visible = false
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/SecondaryAction").visible = false
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailTabs").visible = not _detail.begins_with("workflow:") and _detail not in ["catalogue", "custom"]
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailTabs/Overview").set_pressed_no_signal(_detail_tab == 0)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailTabs/Details").set_pressed_no_signal(_detail_tab == 1)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages").restore_state({})

func _render_detail() -> void:
	if _detail.is_empty() or _actor == null:
		return
	_clear_detail()
	var data: Dictionary = _actor.data
	if _detail.begins_with("workflow:"):
		_render_workflow()
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages").refresh()
		return
	if _detail in ["profile", "class"]:
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = str(data.get("name", "Character")) if _detail == "profile" else str(data.get("class_title", "Class"))
		if _detail_tab == 0:
			_text(str(data.get("description", "")))
			_text(str(data.get("origin", "")))
			_text(_projection.text(data.get("class_rules", [])))
			_text("Improvements: %d · %s" % [int(data.get("improvements", 0)), str(data.get("pack", ""))])
		else:
			for field in (["name", "description", "origin", "pack", "improvements"] if _detail == "profile" else ["class_title", "class_rules"]):
				_character_field(str(field), str(field).replace("_", " ").capitalize())
			if _detail == "class" and str(data.get("class_id", "")) == "gutterborn-scum":
				_character_field("scum_specialty:0", "First specialty · 1–6")
				_character_field("scum_specialty:1", "Second specialty · 0–6")
		if str(data.get("class_id", "")) == "occult-herbmaster":
			_secondary("Inspect laboratory")
	elif _detail.begins_with("resource:"):
		var key := _detail.trim_prefix("resource:")
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = key.replace("_", " ").capitalize()
		if _detail_tab == 1:
			_character_field(key, get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text)
			if key == "hit_points":
				_character_field("maximum_hit_points", "Maximum HP")
		else:
			_text("%s: %s" % [get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text, str(data.get(key, 0))])
			if key == "hit_points":
				_text("At 0 HP roll Broken; below 0 HP means death. Rest restores d4 or d6 HP, up to maximum HP. Table-resolved healing can be entered with Edit sheet.")
			elif key == "power_uses":
				_text("Each morning roll d4 + current Presence. This is independent of Rest. Casting reads current Presence; printed outcomes remain at the table.")
				_primary("Roll morning Power uses", not _draft.active and _owner())
			elif key == "omens":
				_text("Resolve Omen benefits at the table. Depleted Omens may be restored after at least six hours' rest using the class die; enter the result with Edit sheet.")
				_primary("Spend Omen", not _draft.active and _owner() and int(data.get("omens", 0)) > 0)
	elif _detail.begins_with("ability:"):
		var key := _detail.trim_prefix("ability:")
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = key
		if _detail_tab == 1:
			_character_field(key, key + " modifier · −3…+6")
		else:
			_text("Roll d20 %+d. Compare with the difficulty agreed at the table." % int(_projection.fields(data).get(key, 0)))
			_primary("Test " + key, _can_act())
	elif _detail.begins_with("trait:") or _detail.begins_with("companion:") or _detail.begins_with("injury:"):
		var parts := _detail.split(":")
		var entries: Array = data.get("traits" if parts[0] == "trait" else "companion_sheets" if parts[0] == "companion" else "broken_injuries", [])
		var index := int(parts[1])
		if index >= entries.size():
			_back()
			return
		var entry: Dictionary = entries[index]
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = str(entry.get("name", "Entry"))
		if _detail_tab == 1 and parts[0] != "injury":
			for key in ["name", "rules", "uses"]:
				if key == "uses" and not entry.has("uses"):
					continue
				_character_field(_detail + ":" + str(key), str(key).capitalize())
		else:
			_text(str(entry.get("rules", "")))
			if entry.has("uses"):
				_text("Uses: %d" % int(entry.uses))
			if parts[0] == "trait" and not RULES.new().definition(str(entry.get("id", ""))).is_empty():
				_primary("Use feature", not _draft.active and _owner())
	elif _detail.begins_with("actor:"):
		var actor := sdk.actors.read(SDK.ActorId.new(_detail.trim_prefix("actor:")))
		if actor.ok:
			var companion_data: Dictionary = actor.actor.data
			get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = str(companion_data.get("name", "Companion"))
			_text("This companion has its own Actor sheet and inventory.")
			_primary("Open companion", true)
			_secondary("Place Rook", actor.actor.access_level == "Owner")
	elif _detail.begins_with("item:"):
		_item_detail(_item(_detail.trim_prefix("item:")))
	elif _detail == "catalogue":
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "EQUIPMENT CATALOGUE"
		for item in EQUIPMENT.new().entries():
			_option(str(item.get("name", "Equipment")) + " · " + str(item.get("price", "")), _catalogue_add.bind(str(item.get("source_item_id", ""))))
	elif _detail == "custom":
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "CUSTOM ITEM"
		for key in ["name", "kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			_item_field(str(key), str(_new_item.get(str(key), "Equipment" if key == "kind" else "1" if key == "quantity" else "0" if key in ["uses", "range_feet", "armor_tier"] else "")), false)
		_primary("Add custom item", _owner())
	elif _detail == "ready_weapon":
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "Ready weapon"
		for index in range(_weapons.size()):
			var weapon: Dictionary = _weapons[index]
			_option(("Selected · " if str(weapon.inventory_id) == str(_nav.get("weapon", "")) else "") + str(weapon.get("name", "Weapon")) + " · " + str(weapon.get("damage", "")), _choose_ready_weapon.bind(index))
		_primary("Attack", _can_act() and not _weapons.is_empty())
		_secondary("Damage", _owner() and not _draft.active and not _weapons.is_empty())
	elif _detail == "protection":
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "Protection & reactions"
		for raw in _items:
			var item: Dictionary = raw
			if item.get("equipped", false) and str(item.get("kind", "")) in ["Armor", "Shield"]:
				_option(str(item.get("name", "Protection")) + " · " + str(item.get("reduction", "")), _open_detail.bind("item:" + str(item.inventory_id)))
		_text("Defence is d20 + Agility. Resolve incoming damage, protection and reactions with the existing combat workflow or at the table.")
		_primary("Dodge · test Agility", _can_act())
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages").refresh()

func _text(text: String) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.text = _locale.text(text)
	label.autowrap_mode = 3 # TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = 3 # Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14 if _phone else 18)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").add_child(label)

func _option(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = _locale.text(text)
	button.custom_minimum_size = Vector2(0, 44)
	button.theme_type_variation = "TaskButton"
	button.text_overrun_behavior = 3 # TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(callback)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").add_child(button)

func _character_field(field: String, title: String) -> void:
	if not _draft.active:
		_text(title + "\n" + str(_projection.fields(_actor.data).get(field, "")))
		return
	var control = FIELD.instantiate()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").add_child(control)
	control.configure(field, title, _draft.value(field), field in ["description", "origin", "class_rules", "pack"] or field.ends_with(":rules"))
	control.changed.connect(_draft.change)
	_fields.append(control)

func _item_field(field: String, value: String, independent: bool) -> void:
	var control = FIELD.instantiate()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").add_child(control)
	control.configure(field, field.replace("_", " ").capitalize(), value, field == "rules", independent)
	control.submitted.connect(_item_field_saved)
	control.changed.connect(_custom_typed)
	_fields.append(control)

func _custom_typed(field: String, value: String) -> void:
	if _detail == "custom":
		_new_item[field] = value

func _item(id: String) -> Dictionary:
	for raw in _items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == id:
			return item
	return {}

func _item_detail(item: Dictionary) -> void:
	if item.is_empty():
		get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "Item unavailable"
		_text("This item was removed. Return to Inventory for the current items.")
		return
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = str(item.get("name", "Item"))
	if _detail_tab == 1:
		for key in ["name", "quantity", "uses", "kind", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			if key == "uses" and item.has("dose_pool") or key not in ["name", "quantity", "uses"] and not item.get("custom", false):
				continue
			if _item_edit and _owner():
				_item_field(str(key), str(item.get(str(key), "")), true)
			else:
				_text(str(key).replace("_", " ").capitalize() + ": " + str(item.get(str(key), "")))
		_secondary("Finish item editing" if _item_edit else "Edit item", _owner())
		if _owner():
			_option("Remove item", _remove_item)
	else:
		_text(str(item.get("rules", "")))
		_text("Quantity: %d · %s" % [int(item.get("quantity", 0)), "Ready" if item.get("equipped", false) else "Carried"])
		for key in ["damage", "range_feet", "reduction", "armor_tier"]:
			if item.has(str(key)):
				_text(str(key).replace("_", " ").capitalize() + ": " + str(item.get(str(key))))
		if item.has("dose_pool"):
			_text("Shared laboratory doses: %d" % _projection.remaining_uses(_actor.data, item))
		var power := POWERS.new().definition(str(item.get("source_item_id", "")))
		var rule := RULES.new().definition(str(item.get("source_item_id", "")))
		if not power.is_empty():
			_primary("Cast Power", _can_act() and int(item.get("quantity", 0)) > 0)
		elif not rule.is_empty():
			_primary("Brew decoctions" if rule.get("brew", false) else "Use item", not _draft.active and _owner())
		if str(item.get("kind", "")) in ["Weapon", "Armor", "Shield"] or str(item.get("source_item_id", "")) == "stolen-mitre":
			_secondary("Carry" if item.get("equipped", false) else "Ready / equip", _owner())

func _refresh_detail() -> void:
	# Accepted inventory changes refresh untouched independent item fields.
	# Draft character fields remain in the shared draft, including across Back.
	if _detail.begins_with("item:") and _item_edit:
		var item := _item(_detail.trim_prefix("item:"))
		if item.is_empty():
			_request_detail()
		else:
			for field in _fields:
				field.refresh_value(str(item.get(str(field._field), "")))
	elif _draft.active and not _fields.is_empty():
		for field in _fields:
			field.refresh_value(_draft.value(str(field._field)))
	else:
		_request_detail()

func _primary(text: String, enabled: bool) -> void:
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").text = _locale.text(text)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").visible = true
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/PrimaryAction").disabled = not enabled or _busy

func _secondary(text: String, enabled: bool = true) -> void:
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/SecondaryAction").text = _locale.text(text)
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/SecondaryAction").visible = true
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailActions/SecondaryAction").disabled = not enabled or _busy

func _can_act() -> bool:
	return _owner() and not _draft.active and BROKEN.new().can_act(_actor.data)

func _back() -> void:
	var parent := _return_detail if _detail.begins_with("workflow:") else ""
	_leave_workflow()
	_detail = parent
	_return_detail = ""
	_show_route()
	if not parent.is_empty():
		_focus_detail_action = true
		_request_detail()
	elif is_instance_valid(_opener) and _opener.is_visible_in_tree():
		_opener.grab_focus()
	else:
		var focused: bool = get_node(^"Margin/Layout/Body/Chapter/Collections/Primary").focus_entry(_opened_entry)
		if not focused:
			focused = get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Resources").focus_entry(_opened_entry)
		if not focused:
			focused = get_node(^"Margin/Layout/Body/Chapter/Collections/Secondary/Companions").focus_entry(_opened_entry)
		if not focused:
			_chapters[int(_nav.get("chapter", 0))].grab_focus()

func _remember_opener(id: String) -> void:
	_opened_entry = id
	_return_detail = ""
	_opener = _core_opener()

func _core_opener():
	for button in [get_node(^"Margin/Layout/Header/Name"), get_node(^"Margin/Layout/Header/Rest"), get_node(^"Margin/Layout/Header/Improve"), get_node(^"Margin/Layout/Body/Core/Origin"), get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/HitPoints"), get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/PowerUses"), get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/Omens"), get_node(^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength"), get_node(^"Margin/Layout/Body/Core/Abilities/AgilityRow/Agility"), get_node(^"Margin/Layout/Body/Core/Abilities/PresenceRow/Presence"), get_node(^"Margin/Layout/Body/Core/Abilities/ToughnessRow/Toughness"), get_node(^"Margin/Layout/Body/Core/Protection"), get_node(^"Margin/Layout/Body/Core/Dodge"), get_node(^"Margin/Layout/Body/Core/WeaponActions/Attack"), get_node(^"Margin/Layout/Body/Core/WeaponActions/Damage"), get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickOmens"), get_node(^"Margin/Layout/Body/Chapter/QuickResources/QuickSilver")]:
		if button.has_focus():
			return button
	return null

func _catalogue_add(id: String) -> void:
	if _busy:
		return
	_busy = true
	var result := await ACTIONS.new(sdk, _actor.id).add_equipment(id)
	_mutation_result(result)

func _item_field_saved(field: String, value: String) -> void:
	if _busy:
		return
	_busy = true
	var result := await ACTIONS.new(sdk, _actor.id).change_item(_detail.trim_prefix("item:"), field, value)
	_mutation_result(result)

func _remove_item() -> void:
	if _busy:
		return
	_busy = true
	var result := await ACTIONS.new(sdk, _actor.id).remove_item(_detail.trim_prefix("item:"))
	_mutation_result(result)
	if result.ok:
		_back()

func _mutation_result(result: SDK.ActorResult) -> void:
	_busy = false
	if result.ok:
		_actor = result.actor
		_refresh()
		_status("Saved.")
	else:
		_status(result.message)

func _workflow(kind: String, entry: String) -> void:
	if not _owner() or _draft.active or _action_live():
		return
	_return_detail = _detail
	if _return_detail.is_empty():
		_opener = _core_opener()
	_action_kind = kind
	_action_input = {"source": _actor.id.value, "sheet": true}
	_selection = ""
	_rerolls = []
	if kind in ["attack", "damage"]:
		_action_input["item"] = str(_nav.get("weapon", ""))
		_action_input["part"] = kind
		_action_input["difficulty"] = 0
		_action_input["modifier"] = 0
		_action_input["fumble"] = "break"
	elif kind in ["cast", "use"]:
		_action_input["item"] = entry
		_action_input["adjustment"] = 0
		_action_input["modifier"] = 0
		_action_input["ability"] = "Toughness"
		_action_input["morale"] = 7
		_action_input["presence_sign"] = 1
	elif kind == "ability":
		_action_input["ability"] = entry
	else:
		_action_input["kind"] = kind
	_detail = "workflow:" + kind
	_detail_tab = 0
	_end_action()
	_request_detail()
	_show_route()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/Back").grab_focus()

func _render_workflow() -> void:
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailHeader/DetailTitle").text = "Getting better—or worse" if _action_kind == "improve" else {"improve": "Getting better—or worse", "rest": "Rest", "attack": "Attack", "damage": "Damage", "ability": "Ability test", "cast": "Cast Power", "use": "Use item"}.get(_action_kind, "Action")
	if _action != null:
		_text(_action.message)
		if _action.state == "scroll":
			var family := str(_action.snapshot.get("family", ""))
			var entries: Array = SCROLLS.TABLES.get(family, [])
			for raw in entries:
				var entry: Dictionary = raw
				_option(str(entry.name), _reward_scroll.bind(str(entry.source_item_id)))
		elif _action.state == "specialties":
			_text("Keep both specialties, or choose the current specialties to reroll.")
			var entries: Array = _action.snapshot.get("specialties", [])
			for index in range(entries.size()):
				var entry: Dictionary = entries[index]
				_option(("Selected · " if index in _rerolls else "Reroll · ") + str(entry.get("name", "Specialty")), _reroll_specialty.bind(index))
			_primary("Confirm specialties", true)
		elif _action.state == "scrolls":
			_text("Choose the table-agreed scrolls within the supported families.")
			for family in ["unclean", "sacred"]:
				var entries: Array = SCROLLS.TABLES.get(str(family), [])
				for raw in entries:
					var entry: Dictionary = raw
					_option(str(entry.name), _special_scroll.bind(str(entry.source_item_id)))
		elif _action.state == "witnesses":
			_primary("Confirm witnesses", true)
		elif _action.state == "shield":
			_option("Take damage · keep shield", _shield_choice.bind("take"))
			_option("Break shield · take no damage", _shield_choice.bind("break"))
		elif _action.state in ["resolved", "ended", "error"]:
			_primary("Done", true)
		else:
			_primary("Rolling…", false)
		return
	if _ability != null:
		_text(_ability.message)
		_primary("Rolling…" if _ability.pending else "Done", not _ability.pending)
		return
	if _action_kind == "rest":
		_text("Current HP %d / %d. Recovery applies once, up to maximum HP. Power uses and Omens remain unchanged." % [int(_data().get("hit_points", 0)), int(_data().get("maximum_hit_points", 1))])
		_option(("Selected · " if _rest == "breath" else "") + "Catch your breath + drink · d4 HP", _rest_selected.bind("breath"))
		_option(("Selected · " if _rest == "sleep" else "") + "Full night's sleep · d6 HP", _rest_selected.bind("sleep"))
		_text("Without food/drink or while infected, no recovery. After two days without food, lose d4 HP per day; infection costs d6 HP per day. Resolve these at the table; Rest does not advance a day. When Omens are depleted, at least six hours' rest allows the class die; enter the result with Edit sheet.")
		_primary("Roll recovery", true)
	elif _action_kind == "improve":
		_text("When the GM calls for improvement: 6d10 equal to or above maximum HP grants +d6 maximum HP. Current HP stays unchanged. Then roll debris, choose any awarded scroll, and resolve each ability and the current class's steps in order.")
		_text("Accepted rolls cannot be rerolled. Leaving explicitly ends the procedure, keeps accepted changes, and leaves the remaining steps for manual resolution.")
		_primary("Roll 6d10", true)
	elif _action_kind in ["attack", "damage"]:
		var item := _item(str(_action_input.get("item", "")))
		_text(str(item.get("name", "Bite")) + " · " + str(item.get("damage", "d6")))
		_text("Damage is a separate roll. It uses the preceding matching Attack's critical context once. Resolve target protection and consequences at the table.")
		if _action_kind == "attack":
			_workflow_field("difficulty", "DR override · 0 uses the weapon's rules")
			_workflow_field("modifier", "Situational modifier")
			_option("Fumble: break weapon" if str(_action_input.get("fumble", "break")) == "break" else "Fumble: lose weapon", _fumble_choice)
			var traits: Array = _data().get("traits", [])
			for raw in traits:
				var trait_entry: Dictionary = raw
				if str(trait_entry.get("id", "")) == "cowards-jab":
					_option("Coward's jab" if str(_action_input.get("mode", "")) != "jab" else "Coward's jab selected · use ordinary attack", _jab_choice)
		_primary("Roll " + _action_kind, _can_act() if _action_kind == "attack" else _owner())
	elif _action_kind == "ability":
		_text("Test " + str(_action_input.get("ability", "")) + " with the current modifier. Compare with the DR agreed at the table.")
		_primary("Roll test", _can_act())
	elif _action_kind == "cast":
		var item := _item(str(_action_input.get("item", "")))
		_text(str(item.get("name", "Power")) + "\n" + str(item.get("rules", "")))
		_text("Casting uses current Presence. A success spends the existing daily/single-scroll resource; failure costs d2 HP. Resolve target effects and printed table outcomes manually.")
		_workflow_field("modifier", "Situational modifier")
		_primary("Roll casting test", _can_act())
	elif _action_kind == "use":
		var item := RULES.new().owned(_actor.data, str(_action_input.get("item", "")))
		var rule := RULES.new().definition(str(item.get("source_item_id", "")))
		_text(str(item.get("name", "Item")) + "\n" + str(item.get("rules", "")))
		if rule.get("ability_choice", false):
			for ability in PROJECTION.ABILITIES:
				_option(str(ability) + (" · selected" if str(_action_input.get("ability", "")) == str(ability) else ""), _use_ability.bind(str(ability)))
		if rule.has("ability"):
			_workflow_field("adjustment", "DR adjustment")
		if rule.get("morale", false):
			_workflow_field("morale", "Morale")
			_option("Presence sign: %+d" % int(_action_input.get("presence_sign", 1)), _morale_sign)
		if rule.get("gob", false):
			_option("New fight" + (" · selected" if _action_input.get("new_fight", false) else ""), _new_fight)
		_primary("Brew decoctions" if rule.get("brew", false) else "Use item", _owner())

func _workflow_field(field: String, title: String) -> void:
	var control = FIELD.instantiate()
	get_node(^"Margin/Layout/Body/Chapter/Detail/DetailPages/Area/DetailContent").add_child(control)
	control.configure(field, title, str(_action_input.get(field, 0)))
	control.changed.connect(_workflow_typed)

func _workflow_typed(field: String, value: String) -> void:
	_action_input[field] = value

func _rest_selected(kind: String) -> void:
	_rest = kind
	_request_detail()

func _fumble_choice() -> void:
	_action_input["fumble"] = "lose" if str(_action_input.get("fumble", "break")) == "break" else "break"
	_request_detail()

func _jab_choice() -> void:
	_action_input["mode"] = "" if str(_action_input.get("mode", "")) == "jab" else "jab"
	_request_detail()

func _use_ability(ability: String) -> void:
	_action_input["ability"] = ability
	_request_detail()

func _morale_sign() -> void:
	_action_input["presence_sign"] = -int(_action_input.get("presence_sign", 1))
	_request_detail()

func _new_fight() -> void:
	_action_input["new_fight"] = not _action_input.get("new_fight", false)
	_request_detail()

func _primary_action() -> void:
	if _busy:
		return
	if _detail.begins_with("workflow:"):
		if _action != null:
			if _action.state == "specialties" and _action_kind == "improve":
				await (_action as HEALTH).choose({"reroll": _rerolls})
			elif _action.state == "witnesses" and _action_kind == "use":
				await (_action as SPECIAL).confirm_witnesses()
			elif not _action.pending:
				_back()
			return
		if _ability != null:
			if not _ability.pending:
				_back()
			return
		await _start_workflow()
	elif _detail == "ready_weapon":
		await _roll_combat("attack")
	elif _detail == "resource:power_uses":
		await _start_daily()
	elif _detail == "resource:omens":
		_busy = true
		_mutation_result(await ACTIONS.new(sdk, _actor.id).spend_omen())
	elif _detail.begins_with("ability:") or _detail == "protection":
		_workflow("ability", _detail.trim_prefix("ability:") if _detail.begins_with("ability:") else "Agility")
	elif _detail.begins_with("trait:"):
		var traits: Array = _data().get("traits", [])
		var trait_entry: Dictionary = traits[int(_detail.split(":")[1])]
		_workflow("use", "feature:" + str(trait_entry.get("id", "")))
	elif _detail.begins_with("item:"):
		var item := _item(_detail.trim_prefix("item:"))
		_workflow("cast" if not POWERS.new().definition(str(item.get("source_item_id", ""))).is_empty() else "use", _detail.trim_prefix("item:"))
	elif _detail == "custom":
		_busy = true
		var result := await ACTIONS.new(sdk, _actor.id).add_custom(_new_item)
		_mutation_result(result)
		if result.ok:
			_back()
	elif _detail.begins_with("actor:"):
		sdk.windows.open_actor(preload(ROOT + "ui/window_button.tres").window, SDK.ActorId.new(_detail.trim_prefix("actor:")))

func _start_workflow() -> void:
	var input: Dictionary = _action_input.duplicate(true)
	for key in ["difficulty", "modifier", "adjustment", "morale", "presence_sign"]:
		if input.has(str(key)):
			if not str(input.get(str(key))).is_valid_int():
				_status("Enter whole-number modifiers and difficulty.")
				return
			input[str(key)] = int(input.get(str(key)))
	if _action_kind == "ability":
		_ability = ABILITY.new(sdk, _actor.id)
		_ability.changed.connect(_action_changed)
		await _ability.start(str(input.get("ability", "")), true)
		return
	var action := _new_action(_action_kind)
	input["rest"] = _rest
	add_child(action)
	_action = action
	action.changed.connect(_action_changed)
	await action.start(input)

func _new_action(kind: String) -> ACTION:
	if kind in ["rest", "improve", "broken"]:
		return HEALTH.new(sdk)
	if kind == "cast":
		return POWER.new(sdk)
	if kind == "use":
		return SPECIAL.new(sdk)
	var action := ACTION.new(sdk)
	action._operation = "sheet-combat"
	return action

func _start_daily() -> void:
	if not _owner() or _draft.active or _action_live():
		return
	_end_action()
	var action := POWER.new(sdk)
	action.daily = true
	_action = action
	add_child(action)
	action.changed.connect(_action_changed)
	await action.start({"source": _actor.id.value, "sheet": true})

func _reward_scroll(id: String) -> void:
	var health := _action as HEALTH
	if health != null:
		await health.choose({"scroll": id})

func _reroll_specialty(index: int) -> void:
	var selected: Array[int] = []
	for entry in _rerolls:
		if entry != index:
			selected.append(entry)
	if index not in _rerolls:
		selected.append(index)
	_rerolls = selected
	_request_detail()

func _special_scroll(id: String) -> void:
	var count := int(_action.snapshot.get("count", 1))
	var chosen: Array[String] = []
	if not _selection.is_empty():
		chosen.append(_selection)
	chosen.append(id)
	var special := _action as SPECIAL
	if chosen.size() >= count and special != null:
		await special.choose_scrolls(chosen)
	else:
		_selection = id
		_status("First scroll selected. Choose the second scroll.")

func _shield_choice(choice: String) -> void:
	var special := _action as SPECIAL
	if special != null:
		await special.choose_shield(choice)

func _secondary_action() -> void:
	if _detail == "ready_weapon":
		await _roll_combat("damage")
	elif _detail in ["class", "profile"]:
		for raw in _items:
			var item: Dictionary = raw
			if str(item.get("source_item_id", "")) == "portable-laboratory":
				_open_detail("item:" + str(item.inventory_id))
	elif _detail.begins_with("item:"):
		if _detail_tab == 1:
			_item_edit = not _item_edit
			_request_detail()
		else:
			_busy = true
			var item := _item(_detail.trim_prefix("item:"))
			_mutation_result(await ACTIONS.new(sdk, _actor.id).change_item(_detail.trim_prefix("item:"), "equipped", "false" if item.get("equipped", false) else "true"))
	elif _detail.begins_with("actor:"):
		var result := await MINIATURES.new(sdk).place(SDK.ActorId.new(_detail.trim_prefix("actor:")))
		_status("Companion placed." if result.ok else result.message)

func _action_changed() -> void:
	_action_pending = true
	_refresh_pending = true

func _present_roll() -> void:
	var request := str(_action.snapshot.get("request", "")) if _action != null and _action.state == "pending" else _ability.request_id if _ability != null and _ability.pending else ""
	if not request.is_empty():
		var presented := sdk.dice.roll_requested(request, self)
		if not presented.ok and presented.code != "not_ready":
			_status(presented.message)

func _action_live() -> bool:
	return _action != null and _action.pending or _ability != null and _ability.pending

func _leave_workflow() -> void:
	if _detail.begins_with("workflow:"):
		var unfinished := _action_live()
		_end_action()
		if unfinished:
			_status(ACTION.ENDED)

func _end_action() -> void:
	_end_after_roll = false
	if _action != null:
		_action.retire()
	_action = null
	if _ability != null:
		_ability.cancel()
	_ability = null

func _render_condition(data: Dictionary) -> void:
	var condition := _projection.condition(data)
	get_node(^"Margin/Layout/Body/Core/ConditionReminder").visible = not condition.is_empty()
	get_node(^"Margin/Layout/Body/Core/ConditionReminder").text = str(condition.get("title", "")) + " › Character"
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionTitle").text = str(condition.get("title", ""))
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionCopy").text = str(condition.get("copy", ""))
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionCopy").add_theme_font_size_override("font_size", 12 if _phone else 16)
	var incident: Dictionary = data.get("broken_incident", {})
	var outcome := int(incident.get("outcome", 0))
	var elapsed := int(incident.get("elapsed", 0))
	var duration := int(incident.get("duration", 0))
	var rounds: bool = outcome in [1, 2] and not incident.get("recovered", false) and not incident.get("dead", false)
	var hemorrhage: bool = outcome == 3 and not incident.get("treated", false) and not incident.get("negative_hp", false)
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Broken").visible = int(data.get("hit_points", 0)) == 0 and outcome == 0
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/NextRound").visible = rounds and elapsed < duration
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/UndoRound").visible = rounds and elapsed > 0
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Recover").visible = rounds and duration > 0 and elapsed >= duration
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Recover").text = "Awaken" if outcome == 1 else "Recover"
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/AdvanceHour").visible = hemorrhage and elapsed < duration
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/UndoHour").visible = hemorrhage and elapsed > 0
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Treat").visible = hemorrhage and not incident.get("dead", false)
	get_node(^"Margin/Layout/Body/Chapter/Condition/ConditionActions/Broken").disabled = not _owner() or _draft.active or _busy or _action_live()
	for key in ["NextRound", "UndoRound", "Recover", "AdvanceHour", "UndoHour", "Treat"]:
		get_node(_incident_paths.get(str(key), ^"Margin/Layout/Body/Chapter/Condition/ConditionActions/NextRound")).disabled = not _owner() or _draft.active or _busy or _action_live()

func _start_broken() -> void:
	if not _owner() or _draft.active or _action_live():
		return
	_end_action()
	var action := HEALTH.new(sdk)
	add_child(action)
	_action = action
	_action_kind = "broken"
	action.changed.connect(_action_changed)
	await action.start({"source": _actor.id.value, "kind": "broken", "sheet": true})

func _incident(operation: String) -> void:
	if _busy or _draft.active or not _owner():
		return
	_busy = true
	var incident: Dictionary = _data().get("broken_incident", {})
	var result := await sdk.system_actions.submit("health.incident", {"source": _actor.id.value, "incident": int(incident.get("id", 0)), "elapsed": int(incident.get("elapsed", 0)), "event": operation})
	_busy = false
	_status(str(result.value.get("message", "Recorded.")) if result.ok else result.message)
	_refresh_pending = true

func _appearance() -> void:
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureButtons/ChangeMiniature").disabled = not _owner()
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureButtons/ClearMiniature").disabled = not _owner()
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitButtons/ChangePortrait").disabled = not _owner()
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitButtons/ClearPortrait").disabled = not _owner()
	var reference: Dictionary = _data().get("preferred_miniature", {})
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniaturePreview").visible = not reference.is_empty()
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureCaption").text = "No miniature selected"
	if not reference.is_empty():
		var entry := SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", "")))
		var content := sdk.content.read(entry)
		get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureCaption").text = content.content_entry.localized_title if content.ok else "Miniature unavailable"
		var preview := sdk.content.preview_miniature(entry, get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniaturePreview"))
		if not preview.ok:
			_status(preview.message)
	_render_portrait(_actor.data)

func _choose_miniature() -> void:
	get_node(^"Margin/Layout/Body").visible = false
	get_node(^"Margin/Layout/Picker").visible = true
	get_node(^"Margin/Layout/Picker").open(sdk, _locale, _actor.id, "", _data().get("preferred_miniature", {}))

func _picker_closed(_saved: bool) -> void:
	get_node(^"Margin/Layout/Picker").visible = false
	get_node(^"Margin/Layout/Body").visible = true
	_refresh_pending = true
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/MiniaturePanel/MiniatureButtons/ChangeMiniature").grab_focus()

func _clear_miniature() -> void:
	_busy = true
	_mutation_result(await MINIATURES.new(sdk).set_actor(_actor.id, {}))

func _render_portrait(data: Dictionary) -> void:
	var texture: Texture2D = preload("res://rookframe/ui/icons/character/character.svg")
	var caption := "No portrait selected"
	if data.has("portrait"):
		var image: PackedByteArray = data.get("portrait")
		var decoded := sdk.portraits.decode(image)
		if decoded.ok:
			texture = decoded.texture
			caption = "Character portrait"
		else:
			caption = decoded.message
	get_node(^"Margin/Layout/Body/Core/Likeness/Portrait").texture = texture
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitPreview").texture = texture
	get_node(^"Margin/Layout/Body/Chapter/AppearancePanel/PortraitPanel/PortraitCaption").text = caption

func _choose_portrait() -> void:
	if _busy or not _owner():
		return
	var actor_id := _actor.id
	_busy = true
	var selected := await sdk.portraits.choose()
	if not selected.ok:
		_busy = false
		if selected.code != "cancelled":
			_status(selected.message)
		return
	if _actor == null or _actor.id.value != actor_id.value:
		_busy = false
		return
	_mutation_result(await ACTIONS.new(sdk, actor_id).set_portrait(selected.image))

func _clear_portrait() -> void:
	if _busy or not _owner():
		return
	_busy = true
	_mutation_result(await ACTIONS.new(sdk, _actor.id).set_portrait(PackedByteArray()))

func _closed() -> void:
	_end_after_roll = _action != null and _action.pending
	_capture_pages()
	_remember()
	_draft.discard()
	if _action != null and _action.pending and _action.state != "pending":
		_end_action()
		_status(ACTION.ENDED)
	# Closing preserves the live Window Dice interaction and its accepted results.
	# Back/abandonment explicitly ends unfinished workflow state instead.

func _close() -> void:
	_closed()
	sdk.windows.close(load(ROOT + "ui/character_surface.tres"))

func _status(message: String) -> void:
	get_node(^"Margin/Layout/Status").text = _locale.text(message)
	get_node(^"Margin/Layout/Status").visible = not message.is_empty()

func _density() -> void:
	_phone = size.y <= 560
	var tablet := size.x <= 1150 and not _phone
	get_node(^"Margin").add_theme_constant_override("margin_left", 10 if _phone else 16 if tablet else 44)
	get_node(^"Margin").add_theme_constant_override("margin_right", 10 if _phone else 16 if tablet else 44)
	get_node(^"Margin").add_theme_constant_override("margin_top", 8 if _phone else 16)
	get_node(^"Margin").add_theme_constant_override("margin_bottom", 8 if _phone else 16)
	get_node(^"Margin/Layout").add_theme_constant_override("separation", 8 if _phone else 16)
	get_node(^"Margin/Layout/Body").add_theme_constant_override("separation", 16 if _phone else 24 if tablet else 44)
	get_node(^"Margin/Layout/Body/Core").custom_minimum_size = Vector2(228 if _phone else 280 if tablet else 550, 0)
	get_node(^"Margin/Layout/Body/Core").add_theme_constant_override("separation", 4 if _phone else 8 if tablet else 12)
	get_node(^"Margin/Layout/Body/Core/Likeness/Portrait").custom_minimum_size = Vector2(72, 90) if _phone else Vector2(100, 125) if tablet else Vector2(152, 190)
	get_node(^"Margin/Layout/Body/Core/ReadyWeapon").visible = _phone
	get_node(^"Margin/Layout/Body/Core/Weapon").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/WeaponActions").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/ManageEquipment").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/Dodge").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/Origin").visible = not _phone
	get_node(^"Margin/Layout/Header/System").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/WeaponHeading").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/ProtectionHeading").visible = not _phone
	get_node(^"Margin/Layout/Body/Core/Likeness/Vitals/Omens").visible = not _phone and not _draft.active
	get_node(^"Margin/Layout/Body/Core/Class").add_theme_font_size_override("font_size", 11 if _phone else 18 if tablet else 22)
	get_node(^"Margin/Layout/Body/Chapter").add_theme_constant_override("separation", 4 if _phone else 12)
	for button in [get_node(^"Margin/Layout/Header/Name"), get_node(^"Margin/Layout/Header/Edit"), get_node(^"Margin/Layout/Header/Rest"), get_node(^"Margin/Layout/Header/Improve"), get_node(^"Margin/Layout/Header/SaveSheet"), get_node(^"Margin/Layout/Header/CancelSheet"), get_node(^"Margin/Layout/Header/Close")]:
		button.add_theme_font_size_override("font_size", 12 if _phone else 16)
	get_node(^"Margin/Layout/Header/Name").add_theme_font_size_override("font_size", 16 if _phone else 22 if tablet else 28)
	for key in CHAPTERS:
		_chapters[CHAPTERS.find(key)].add_theme_font_size_override("font_size", 11 if _phone else 14 if tablet else 18)
	for key in PROJECTION.ABILITIES:
		get_node(_ability_paths.get(str(key), ^"Margin/Layout/Body/Core/Abilities/StrengthRow/Strength")).add_theme_font_size_override("font_size", 11 if _phone else 14 if tablet else 18)
	if _actor != null:
		_core(_actor.data)
		_show_route()

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		if _draft.active:
			_cancel_edit()
		elif get_node(^"Margin/Layout/Picker").visible:
			_picker_closed(false)
		elif not _detail.is_empty():
			_back()
		else:
			_close()
		accept_event()
	elif _detail.is_empty():
		var key := event as InputEventKey
		if key == null or not key.pressed or key.echo:
			return
		if key.keycode in [KEY_Q, KEY_E]:
			_chapter((int(_nav.get("chapter", 0)) + (CHAPTERS.size() - 1 if key.keycode == KEY_Q else 1)) % CHAPTERS.size())
			accept_event()

func _roll_combat(part: String) -> void:
	_workflow(part, "")
	if _detail == "workflow:" + part:
		await _start_workflow()

func _data() -> Dictionary:
	if _actor == null:
		return {}
	var data: Dictionary = _actor.data
	return data

func _choose_ready_weapon(index: int) -> void:
	_weapon_selected(index)
	_refresh_pending = true
	_request_detail()
