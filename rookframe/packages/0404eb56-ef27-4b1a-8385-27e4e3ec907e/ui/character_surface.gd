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
@onready var _core_ui = get_node(^"Margin/Layout/Body/Core")
@onready var _chapter_ui = get_node(^"Margin/Layout/Body/Chapter")
@onready var _detail_ui = get_node(^"Margin/Layout/Body/Chapter/Detail")
@onready var _appearance_ui = get_node(^"Margin/Layout/Body/Chapter/AppearancePanel")
@onready var _header = get_node(^"Margin/Layout/Header")
@onready var _quick_quick_omens = _chapter_ui.get_node(^"QuickResources/QuickOmens")
@onready var _quick_quick_omens_edit = _chapter_ui.get_node(^"QuickResources/QuickOmensEditField/Editor")
@onready var _quick_quick_silver = _chapter_ui.get_node(^"QuickResources/QuickSilver")
@onready var _quick_quick_silver_edit = _chapter_ui.get_node(^"QuickResources/QuickSilverEditField/Editor")
@onready var _core_condition_reminder = _core_ui.get_node(^"ConditionReminder")
@onready var _core_dodge = _core_ui.get_node(^"Dodge")
@onready var _core_portrait = _core_ui.get_node(^"Likeness/Portrait")
@onready var _core_condition_badge = _core_ui.get_node(^"Likeness/Portrait/ConditionBadge")
@onready var _core_condition_frame = _core_ui.get_node(^"Likeness/Portrait/ConditionFrame")
@onready var _core_hit_points = _core_ui.get_node(^"Likeness/Vitals/HitPoints")
@onready var _core_omens = _core_ui.get_node(^"Likeness/Vitals/Omens")
@onready var _core_power_uses = _core_ui.get_node(^"Likeness/Vitals/PowerUses")
@onready var _core_manage_equipment = _core_ui.get_node(^"ManageEquipment")
@onready var _core_origin = _core_ui.get_node(^"Origin")
@onready var _core_phone_edit = _core_ui.get_node(^"PhoneHeader/PhoneEdit")
@onready var _core_phone_name = _core_ui.get_node(^"PhoneHeader/PhoneName")
@onready var _core_protection = _core_ui.get_node(^"Protection")
@onready var _core_ready_weapon = _core_ui.get_node(^"ReadyWeapon")
@onready var _core_weapon = _core_ui.get_node(^"Weapon")
@onready var _core_attack = _core_ui.get_node(^"WeaponActions/Attack")
@onready var _core_damage = _core_ui.get_node(^"WeaponActions/Damage")
@onready var _chapter_chapter_caption = _chapter_ui.get_node(^"ChapterCaption")
@onready var _chapter_personal_notes = _chapter_ui.get_node(^"ChapterCaption/PersonalNotes")
@onready var _chapter_collections = _chapter_ui.get_node(^"Collections")
@onready var _chapter_primary = _chapter_ui.get_node(^"Collections/Primary")
@onready var _chapter_secondary = _chapter_ui.get_node(^"Collections/Secondary")
@onready var _chapter_companions = _chapter_ui.get_node(^"Collections/Secondary/Companions")
@onready var _chapter_resources = _chapter_ui.get_node(^"Collections/Secondary/Resources")
@onready var _condition_ui = _chapter_ui.get_node(^"Condition")
@onready var _chapter_journal_panel = _chapter_ui.get_node(^"JournalPanel")
@onready var _chapter_notes = _chapter_ui.get_node(^"JournalPanel/Notes")
@onready var _chapter_story = _chapter_ui.get_node(^"JournalPanel/Story")
@onready var _section = _chapter_ui.get_node(^"Section")
@onready var _chapter_tabs = _chapter_ui.get_node(^"Tabs")
@onready var _chapter_tab_appearance = _chapter_ui.get_node(^"Tabs/TabAppearance")
@onready var _chapter_tab_character = _chapter_ui.get_node(^"Tabs/TabCharacter")
@onready var _chapter_tab_inventory = _chapter_ui.get_node(^"Tabs/TabInventory")
@onready var _chapter_tab_journal = _chapter_ui.get_node(^"Tabs/TabJournal")
@onready var _chapter_tab_powers = _chapter_ui.get_node(^"Tabs/TabPowers")
@onready var _actions_ui = _detail_ui.get_node(^"FooterInset/DetailActions")
@onready var _primary_button = _detail_ui.get_node(^"FooterInset/DetailActions/PrimaryAction")
@onready var _secondary_button = _detail_ui.get_node(^"FooterInset/DetailActions/Utility/SecondaryAction")
@onready var _detail_back = _detail_ui.get_node(^"HeaderFrame/Inset/DetailHeader/Back")
@onready var _detail_title = _detail_ui.get_node(^"HeaderFrame/Inset/DetailHeader/DetailTitle")
@onready var _detail_content = _detail_ui.get_node(^"Body/DetailPages/Area/DetailContent")
@onready var _detail_detail_tabs = _detail_ui.get_node(^"TabsFrame/Inset/DetailTabs")
@onready var _detail_details = _detail_ui.get_node(^"TabsFrame/Inset/DetailTabs/Details")
@onready var _detail_overview = _detail_ui.get_node(^"TabsFrame/Inset/DetailTabs/Overview")
@onready var _workflow_slot = get_node(^"Margin/Layout/Workflow/Body/Main/Content/Procedure/Inset/Slot")
@onready var _workflow_footer = get_node(^"Margin/Layout/Workflow/Footer")
@onready var _header_cancel_sheet = _header.get_node(^"CancelSheet")
@onready var _header_close = _header.get_node(^"Close")
@onready var _header_edit = _header.get_node(^"Edit")
@onready var _header_editing_status = _header.get_node(^"EditingStatus")
@onready var _header_improve = _header.get_node(^"Improve")
@onready var _header_name = _header.get_node(^"Name")
@onready var _header_name_edit = _header.get_node(^"NameEditField/Editor")
@onready var _header_name_edit__caption = _header.get_node(^"NameEditField/Editor/Caption")
@onready var _header_rest = _header.get_node(^"Rest")
@onready var _header_save_sheet = _header.get_node(^"SaveSheet")
@onready var _header_spacer = _header.get_node(^"Spacer")
@onready var _header_system = _header.get_node(^"System")
@onready var _quick = _chapter_ui.get_node(^"QuickResources")
@onready var _appearance_change_miniature = _appearance_ui.get_node(^"MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature")
@onready var _quick_parent = _chapter_ui
@onready var _workflow_ui = get_node(^"Margin/Layout/Workflow")
@onready var _detail_parent = _chapter_ui
@onready var _actions_parent = _detail_ui.get_node(^"FooterInset")
var _combat_options: Dictionary = {"difficulty": 0, "modifier": 0, "fumble": "break"}
var _scroll_choices: Array[String] = []
var _portrait_texture: Texture2D
const CHAPTERS := ["Character", "Powers", "Inventory", "Journal", "Appearance"]
@onready var _detail_header = _detail_ui.get_node(^"HeaderFrame/Inset/DetailHeader")
@export var navigation: Resource
@onready var _chapters = [_chapter_tab_character, _chapter_tab_powers, _chapter_tab_inventory, _chapter_tab_journal, _chapter_tab_appearance]
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
var _validation_error: Dictionary = {}
var _opener
var _opened_entry := ""
var _return_detail := ""
var _history: Array[Dictionary] = []
var _ending_improvement := false
var _condition_reference := false
var _cast_modifier := "0"
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
	get_node(^"EntryDialog").close_requested_by_user.connect(_dismiss_detail)
	get_node(^"EntryDialog").escape_requested.connect(_escape)
	_detail_ui.close_requested.connect(_dismiss_detail)
	_detail_ui.save_requested.connect(_save_sheet)
	_detail_ui.cancel_requested.connect(_cancel_edit)
	_detail_ui.back_requested.connect(_back)
	_workflow_ui.back_requested.connect(_back)
	_workflow_ui.rest_selected.connect(_rest_selected)
	_workflow_ui.section_changed.connect(_request_detail)
	for index in range(CHAPTERS.size()):
		_chapters[index].pressed.connect(_chapter.bind(index))
	_header_edit.pressed.connect(_edit)
	_core_phone_edit.pressed.connect(_edit)
	_core_phone_name.pressed.connect(_name_pressed)
	_quick_quick_silver_edit.text_changed.connect(_core_typed.bind("silver"))
	_chapter_personal_notes.pressed.connect(_open_detail.bind("journal:notes"))
	_chapter_ui.resource_requested.connect(_open_detail)
	_chapter_ui.resource_changed.connect(_draft.change)
	_chapter_ui.get_node(^"ReferenceBack").pressed.connect(_return_condition)
	_chapter_ui.get_node(^"Collections/Secondary/ResourceEditors").changed.connect(_draft.change)
	for index in range(4):
		var path: NodePath = [^"ChapterCaption/InventoryFilters/All", ^"ChapterCaption/InventoryFilters/Arms", ^"ChapterCaption/InventoryFilters/Supplies", ^"ChapterCaption/InventoryFilters/Ready"][index]
		_chapter_ui.get_node(path).pressed.connect(_inventory_filter.bind(index))
	_header_save_sheet.pressed.connect(_save_sheet)
	_header_cancel_sheet.pressed.connect(_cancel_edit)
	_header_close.pressed.connect(_close)
	_header_rest.pressed.connect(_workflow.bind("rest", ""))
	_header_improve.pressed.connect(_workflow.bind("improve", ""))
	_header_name.pressed.connect(_name_pressed)
	_header_name_edit.text_changed.connect(_core_typed.bind("name"))
	_core_origin.pressed.connect(_open_detail.bind("profile"))
	_core_ui.entry_requested.connect(_open_detail)
	_core_ui.field_changed.connect(_core_typed)
	_core_hit_points.pressed.connect(_open_detail.bind("resource:hit_points"))
	_core_power_uses.pressed.connect(_open_detail.bind("resource:power_uses"))
	_core_omens.pressed.connect(_open_detail.bind("resource:omens"))
	_quick_quick_omens_edit.text_changed.connect(_core_typed.bind("omens"))
	_quick_quick_omens.pressed.connect(_open_detail.bind("resource:omens"))
	_quick_quick_silver.pressed.connect(_open_detail.bind("resource:silver"))
	_core_ready_weapon.pressed.connect(_open_detail.bind("ready_weapon"))
	_core_weapon.item_selected.connect(_weapon_selected)
	_core_attack.pressed.connect(_roll_combat.bind("attack"))
	_core_damage.pressed.connect(_roll_combat.bind("damage"))
	_core_manage_equipment.pressed.connect(_chapter.bind(2))
	_core_protection.pressed.connect(_open_detail.bind("protection"))
	_core_dodge.pressed.connect(_direct_ability.bind("Agility"))
	_chapter_primary.selected.connect(_open_detail)
	_chapter_resources.selected.connect(_open_detail)
	_chapter_companions.selected.connect(_open_detail)
	_section.item_selected.connect(_section_selected)
	_chapter_story.selected.connect(_open_detail)
	_chapter_notes.selected.connect(_open_detail)
	_detail_back.pressed.connect(_back)
	_detail_overview.pressed.connect(_detail_tab_selected.bind(0))
	_detail_details.pressed.connect(_detail_tab_selected.bind(1))
	_primary_button.pressed.connect(_primary_action)
	_secondary_button.pressed.connect(_secondary_action)
	_core_condition_reminder.pressed.connect(_chapter.bind(0))
	_condition_ui.broken_requested.connect(_start_broken)
	_condition_ui.event_requested.connect(_incident)
	_condition_ui.edit_hp_requested.connect(_edit_hit_points)
	get_node(^"Margin/Layout/Picker").closed.connect(_picker_closed)
	_appearance_ui.miniature_requested.connect(_choose_miniature)
	_appearance_ui.changed.connect(_world_changed)
	_appearance_ui.message.connect(_status)
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
	get_node(^"Margin/Layout/Picker").visible = false
	get_node(^"Margin/Layout/Body").visible = true
	_refresh()

func capture_reconnect_state() -> Dictionary:
	_capture_pages()
	return _nav.duplicate(true)

func restore_reconnect_state(state: Dictionary) -> void:
	_nav = state.duplicate(true)
	_rendered_chapter = -1
	_remember()
	_refresh_pending = true

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
			_accept_actor(latest.actor)
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
		if str(_validation_error.get("entry", "")) == _detail:
			_field_error(str(_validation_error.get("field", "")), str(_validation_error.get("message", "")))
		_validation_error = {}
		if _focus_detail_action:
			_focus_detail_action = false
			_primary_button.grab_focus()

func _request_detail() -> void:
	_detail_pending = true

func _refresh() -> void:
	if _actor == null:
		return
	var data: Dictionary = _actor.data
	if not _owner() and (_draft.active or _item_edit):
		_draft.discard()
		_item_edit = false
		_request_detail()
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
	_header_name.visible = not _draft.active
	_header_name_edit.visible = _draft.active
	_header_name_edit.text = _draft.value("name") if _draft.active else str(data.get("name", ""))
	_header.visible = not _phone or _draft.active
	_header_name.text = str(data.get("name", "Character"))
	_header_editing_status.visible = _draft.active
	_header_spacer.visible = _draft.active
	_header_system.visible = not _phone and not _draft.active
	get_node(^"Margin").add_theme_constant_override("margin_top", (4 if _draft.active else 10) if _phone else 16)
	_quick_quick_omens_edit.visible = _phone and _draft.active
	_quick_quick_omens_edit.text = _draft.value("omens") if _draft.active else str(data.get("omens", 0))
	_quick_quick_omens.visible = not _draft.active
	_quick_quick_omens.text = "%d Omens" % int(data.get("omens", 0))
	_quick_quick_silver.text = "%d Silver" % int(data.get("silver", 0))
	_quick_quick_silver.visible = not _draft.active
	_quick_quick_silver_edit.visible = _draft.active
	_quick_quick_silver_edit.text = _draft.value("silver") if _draft.active else str(data.get("silver", 0))
	_header_edit.disabled = not _owner() or _action_live()
	_header_rest.disabled = not _owner() or _draft.active or _action_live() or BROKEN.new().is_dead(data)
	_header_improve.disabled = not _owner() or _draft.active or _action_live()
	_header_edit.visible = not _draft.active
	_header_save_sheet.visible = _draft.active
	_header_cancel_sheet.visible = _draft.active
	var state: Dictionary = _core_ui.configure(data, _projection.fields(data), _draft.values() if _draft.active else {}, _items, str(_nav.get("weapon", "")), _owner(), _action_live())
	_weapons = state.weapons
	_nav["weapon"] = state.weapon
	_render_portrait(data)
	_setting = false

func _collections(data: Dictionary) -> void:
	_capture_pages()
	var chapter := int(_nav.get("chapter", 0))
	var rows := _projection.collections(data, _items, chapter, _actor.id.value, sdk, int(_nav.get("inventory_filter", 0)), _owner())
	var primary: Array[Dictionary] = rows.primary
	var resources: Array[Dictionary] = rows.resources
	var companions: Array[Dictionary] = rows.companions
	var heading := str(rows.heading)
	_chapter_primary.configure(primary, "", heading, str(primary.size()))
	_chapter_resources.configure(resources, "", "RESOURCES" if chapter == 0 else "DECOCTIONS & RESOURCES", str(resources.size()))
	_chapter_companions.configure(companions, "", "COMPANIONS", str(companions.size()))
	var story: Array[Dictionary] = []
	var notes: Array[Dictionary] = []
	if chapter == 3:
		story = primary
		notes = resources
	_chapter_ui.configure_journal(story, notes)
	_rendered_chapter = chapter
	_restore_pages()

func _capture_pages() -> void:
	if not _nav.is_empty() and _rendered_chapter >= 0:
		var pages: Dictionary = _nav.get("pages", {})
		_nav["pages"] = _chapter_ui.capture_pages(pages, _rendered_chapter)

func _restore_pages() -> void:
	var pages: Dictionary = _nav.get("pages", {})
	_chapter_ui.restore_pages(pages, int(_nav.get("chapter", 0)))

func _show_route() -> void:
	var chapter := int(_nav.get("chapter", 0))
	var details := not _detail.is_empty()
	var task := _detail in ["workflow:rest", "workflow:improve"]
	var modal := details and not _phone and not task
	var detail_parent = _workflow_slot if task else get_node(^"EntryDialog/Surface/Inset") if modal else _chapter_ui
	var actions_parent = _workflow_footer if task else _detail_ui.get_node(^"FooterInset")
	if _actions_parent != actions_parent:
		_actions_parent.remove_child(_actions_ui)
		actions_parent.add_child(_actions_ui)
		_actions_parent = actions_parent
	if _detail_parent != detail_parent:
		_detail_parent.remove_child(_detail_ui)
		detail_parent.add_child(_detail_ui)
		_detail_parent = detail_parent
	_workflow_ui.visible = task
	var tablet := get_viewport_rect().size.x <= 1150 and not _phone
	_detail_ui.configure_layout(_phone, tablet, task, _draft.active, _detail_tab == 1)
	for edge in ["left", "right"]:
		get_node(^"Margin").add_theme_constant_override("margin_" + edge, (12 if _phone else 20 if tablet else 30) if task else (17 if _phone else 16 if tablet else 44))
	get_node(^"Margin").add_theme_constant_override("margin_top", (4 if _phone else 12 if tablet else 20) if task else ((4 if _draft.active else 10) if _phone else 16))
	get_node(^"Margin").add_theme_constant_override("margin_bottom", (6 if _phone else 12 if tablet else 20) if task else (10 if _phone else 16))
	get_node(^"Margin/Layout/Body").visible = not task and not get_node(^"Margin/Layout/Picker").visible
	_header.visible = not task and (not _phone or _draft.active or details)
	_detail_header.visible = not task
	if _phone and details and not _draft.active:
		_header_name.add_theme_font_size_override("font_size", 18)
		_header_name.custom_minimum_size = Vector2(140, _header_name.custom_minimum_size.y)
	_header_rest.visible = not _phone and not _draft.active
	_header_improve.visible = not _phone and not _draft.active
	var obscured := details and not modal
	_chapter_tabs.visible = not obscured
	_core_ui.visible = not (_phone and (details or chapter == 4))
	_chapter_collections.visible = not obscured and chapter in [0, 1, 2]
	_chapter_journal_panel.visible = not obscured and chapter == 3
	_appearance_ui.visible = not obscured and chapter == 4
	_chapter_ui.get_node(^"AppearanceIntro").visible = not obscured and chapter == 4 and not _phone
	_chapter_ui.get_node(^"AppearanceStatus").visible = not obscured and chapter == 4
	_detail_ui.visible = details and _detail != "workflow:rest"
	_condition_ui.visible = not obscured and chapter == 0 and not _condition_reference and not _projection.condition(_actor.data).is_empty()
	_section.visible = _phone and not details and chapter in [0, 1, 2, 3]
	_quick.visible = _phone and not details and chapter != 4 and not _condition_ui.visible
	_section.clear()
	for title in (["Features & traits", "Resources", "Companions"] if chapter == 0 else ["Powers", "Decoctions & resources"] if chapter == 1 else ["All belongings", "Arms", "Supplies", "Ready"] if chapter == 2 else ["All", "Story", "Notes"]):
		_section.add_item(str(title))
	_section.select(mini(int(_nav.get("inventory_filter", 0) if chapter == 2 else _nav.get("section", 0)), _section.item_count - 1))
	_chapter_primary.visible = chapter == 2 or not _phone or _section.selected == 0
	_chapter_secondary.visible = chapter == 0 and (not _phone or _section.selected != 0) or chapter == 1 and _phone and _section.selected == 1
	_chapter_resources.visible = not _phone or _section.selected == 1
	_chapter_companions.visible = chapter == 0 and (_condition_reference or _projection.condition(_actor.data).is_empty()) and (not _phone or _section.selected == 2)
	if _phone and _condition_ui.visible:
		_chapter_collections.visible = false
		_section.visible = false
	_chapter_ui.get_node(^"ReferenceBack").visible = _phone and _condition_reference and not details and chapter == 0
	var resource_editor = _chapter_ui.get_node(^"Collections/Secondary/ResourceEditors")
	resource_editor.visible = _draft.active and chapter == 0 and (not _phone or _section.selected == 1)
	resource_editor.configure(_draft.values(), _phone, tablet)
	_chapter_resources.visible = _chapter_resources.visible and not (chapter == 0 and _draft.active)
	_chapter_ui.configure_caption(chapter, _phone, int(_nav.get("inventory_filter", 0)), _actor.data, _draft.values() if _draft.active else {}, int(_nav.get("section", 0)))
	_chapter_chapter_caption.visible = not obscured and not _phone and chapter in [1, 2, 3]
	_chapter_story.visible = not _phone or _section.selected < 2
	_chapter_notes.visible = not _phone or _section.selected == 2
	var footer = _chapter_ui
	if _phone and not details and chapter in [0, 1, 2] and not _condition_ui.visible:
		footer = _chapter_primary.get_footer_slot() if chapter == 2 or _section.selected == 0 else resource_editor.get_footer_slot() if _section.selected == 1 and chapter == 0 and _draft.active else _chapter_resources.get_footer_slot() if _section.selected == 1 else _chapter_companions.get_footer_slot()
	elif _phone and not details and chapter == 3:
		footer = _chapter_story.get_footer_slot() if _section.selected < 2 else _chapter_notes.get_footer_slot()
	if footer != _quick_parent:
		_quick_parent.remove_child(_quick)
		footer.add_child(_quick)
		_quick_parent = footer
	for index in range(CHAPTERS.size()):
		_chapters[index].set_pressed_no_signal(index == chapter)
	if chapter == 4:
		_appearance()
	get_node(^"EntryScrim").visible = modal
	get_node(^"EntryDialog").present(modal and not (_action != null and _action.state == "pending") and not (_ability != null and _ability.pending), get_viewport_rect().size, "note" if _detail == "journal:notes" else "entry")

func _chapter(index: int) -> void:
	_condition_reference = false
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
	if int(_nav.get("chapter", 0)) == 2:
		_inventory_filter(index)
		return
	_nav["section"] = index
	_show_route()
	_remember()

func _inventory_filter(index: int) -> void:
	_nav["inventory_filter"] = index
	_collections(_actor.data)
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
	get_node(^"Margin/Layout").clear_errors()
	_draft.begin(_projection.fields(_actor.data), _projection.identities(_actor.data))
	_refresh()
	_header_name_edit.grab_focus()

func _core_typed(text: String, field: String) -> void:
	if _draft.active and not _setting:
		_draft.change(field, text)

func _save_sheet() -> void:
	if _busy or not _draft.active or not _owner():
		return
	_busy = true
	_header_save_sheet.disabled = true
	var corrections := ACTIONS.new(sdk, _actor.id)
	var result := await corrections.correct_many(_draft.changes(), _draft.identities())
	_busy = false
	_header_save_sheet.disabled = false
	if result.ok:
		_draft.discard()
		_detail = ""
		_history.clear()
		_accept_actor(result.actor)
		_refresh()
		_request_detail()
		_status("Sheet saved.")
		_edit_focus()
	else:
		_status(result.message)
		get_node(^"Margin/Layout").show_error(corrections.invalid_field, result.message)
		if not corrections.invalid_field.is_empty():
			_detail = _detail_ui.correction_route(corrections.invalid_field)
			_detail_tab = 1
			_show_route()
			_validation_error = {"entry": _detail, "field": corrections.invalid_field, "message": result.message}
			_request_detail()

func _cancel_edit() -> void:
	_detail = ""
	_history.clear()
	get_node(^"Margin/Layout").clear_errors()
	_draft.discard()
	_refresh_pending = true
	_refresh()
	_request_detail()
	_edit_focus()

func _edit_focus() -> void:
	if _core_phone_edit.is_visible_in_tree():
		_core_phone_edit.grab_focus()
	elif _header_edit.is_visible_in_tree():
		_header_edit.grab_focus()
	else:
		_chapters[int(_nav.get("chapter", 0))].grab_focus()

func _reference_section(index: int) -> void:
	_condition_reference = true
	_nav["chapter"] = 0
	_nav["section"] = index
	_detail = ""
	_history.clear()
	_refresh()
	_section.grab_focus()

func _return_condition() -> void:
	_condition_reference = false
	_refresh()
	_core_phone_name.grab_focus()

func _name_pressed() -> void:
	_open_detail("profile")

func _open_detail(id: String) -> void:
	if id == "empty":
		return
	_leave_workflow()
	_capture_pages()
	if not _detail.is_empty() and not _detail.begins_with("workflow:"):
		_history.append({"entry": _detail, "tab": _detail_tab, "page": _detail_ui.paging_state()})
	else:
		_history.clear()
		_remember_opener(id)
	_detail_ui.reset_navigation()
	_detail = id
	_detail_tab = 0
	_item_edit = false
	_new_item = {}
	_request_detail()
	_show_route()
	_detail_back.grab_focus()

func _detail_tab_selected(index: int) -> void:
	_detail_tab = index
	_show_route()
	_request_detail()

func _clear_detail() -> void:
	_fields = []
	_detail_ui.begin_content(_detail + ":" + str(_detail_tab))
	_primary_button.visible = false
	_secondary_button.visible = false
	_detail_detail_tabs.visible = not _detail.begins_with("workflow:") and _detail not in ["catalogue", "custom"]
	_detail_overview.set_pressed_no_signal(_detail_tab == 0)
	_detail_details.set_pressed_no_signal(_detail_tab == 1)

func _render_detail() -> void:
	if _detail.is_empty() or _actor == null:
		return
	_clear_detail()
	var data: Dictionary = _actor.data
	if _detail.begins_with("workflow:"):
		_render_workflow()
		_detail_ui.finish_content("")
		return
	if _detail in ["profile", "class"]:
		_detail_title.text = str(data.get("name", "Character")) if _detail == "profile" else str(data.get("class_title", "Class"))
		if _detail_tab == 0:
			_text(str(data.get("description", "")))
			_text(str(data.get("origin", "")))
			_text(_projection.text(data.get("class_rules", [])))
			_detail_ui.append_facts([["Improvements", str(data.get("improvements", 0))], ["Pack", str(data.get("pack", ""))]])
		else:
			if _phone and _detail == "class":
				_detail_ui.group_fields(["class_title", "class_rules"], [1, 2])
			for field in (["name", "description", "origin", "pack", "improvements"] if _detail == "profile" else ["class_title", "class_rules"]):
				_character_field(str(field), str(field).replace("_", " ").capitalize())
			if _detail == "class" and str(data.get("class_id", "")) == "gutterborn-scum":
				_character_field("scum_specialty:0", "First specialty · 1–6")
				_character_field("scum_specialty:1", "Second specialty · 0–6")
		if _phone and _detail == "profile" and _detail_tab == 0:
			_option("Rest", _workflow.bind("rest", ""), _owner() and not _draft.active and not _action_live() and not BROKEN.new().is_dead(data))
			_option("Level up", _workflow.bind("improve", ""), _owner() and not _draft.active and not _action_live())
		if _phone and _detail == "profile" and not _projection.condition(data).is_empty():
			for index in range(3):
				_option(["Features & traits", "Resources", "Companions"][index], _reference_section.bind(index))
		if str(data.get("class_id", "")) == "occult-herbmaster":
			_secondary("Inspect laboratory")
	elif _detail.begins_with("resource:"):
		var key := _detail.trim_prefix("resource:")
		_detail_title.text = key.replace("_", " ").capitalize()
		if _detail_tab == 1:
			_character_field(key, _detail_title.text)
			if key == "hit_points":
				_character_field("maximum_hit_points", "Maximum HP")
		else:
			_detail_ui.append_facts([[_detail_title.text, str(data.get(key, 0))], ["Maximum HP", str(data.get("maximum_hit_points", 1))]] if key == "hit_points" else [[_detail_title.text, str(data.get(key, 0))]])
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
		_detail_title.text = key
		if _detail_tab == 1:
			_character_field(key, key + " modifier · −3…+6")
		else:
			_detail_ui.append_facts([["Roll", "d20"], ["Modifier", "%+d" % int(_projection.fields(data).get(key, 0))]])
			_text("Compare with the difficulty agreed at the table.")
			_primary("Test " + key, _can_act())
	elif _detail.begins_with("trait:") or _detail.begins_with("companion:") or _detail.begins_with("injury:"):
		var parts := _detail.split(":")
		var entries: Array = data.get("traits" if parts[0] == "trait" else "companion_sheets" if parts[0] == "companion" else "broken_injuries", [])
		var index := int(parts[1])
		if index >= entries.size():
			_back()
			return
		var entry: Dictionary = entries[index]
		_detail_title.text = str(entry.get("name", "Entry"))
		if _detail_tab == 1 and parts[0] != "injury":
			if _phone:
				_detail_ui.group_fields([_detail + ":name", _detail + ":rules"], [1, 2])
			for key in ["name", "rules", "uses"]:
				if key == "uses" and not entry.has("uses"):
					continue
				_character_field(_detail + ":" + str(key), str(key).capitalize())
		else:
			_text(str(entry.get("rules", "")))
			if entry.has("uses"):
				_detail_ui.append_facts([["Uses", str(entry.uses)]])
			if parts[0] == "trait" and not RULES.new().definition(str(entry.get("id", ""))).is_empty():
				_primary("Use feature", not _draft.active and _owner() and _use_allowed(RULES.new().definition(str(entry.get("id", "")))))
	elif _detail.begins_with("actor:"):
		var actor := sdk.actors.read(SDK.ActorId.new(_detail.trim_prefix("actor:")))
		if actor.ok:
			var companion_data: Dictionary = actor.actor.data
			_detail_title.text = str(companion_data.get("name", "Companion"))
			_text("This companion has its own Actor sheet and inventory.")
			_primary("Open companion", true)
			_secondary("Place Rook", actor.actor.access_level == "Owner")
	elif _detail.begins_with("item:"):
		_item_detail(_item(_detail.trim_prefix("item:")))
	elif _detail.begins_with("journal:"):
		_detail_title.text = "Personal notes" if _detail == "journal:notes" else "The road ahead"
		_text("Local placeholder. This chapter does not save World data.")
		if _detail == "journal:notes":
			var notes = preload("res://rookframe/ui/components/forms/task_text_area.tscn").instantiate()
			_detail_content.add_child(notes)
			notes.label_text = "Personal notes · placeholder"
			notes.compact = _phone
			notes.value = ""
		else:
			_text("The places and words you carry. Add your table's story here when Journal storage is supported.")
	elif _detail == "catalogue":
		_detail_title.text = "EQUIPMENT CATALOGUE"
		for item in EQUIPMENT.new().entries():
			_option(str(item.get("name", "Equipment")) + " · " + str(item.get("price", "")), _catalogue_add.bind(str(item.get("source_item_id", ""))), _owner())
	elif _detail == "custom":
		_detail_title.text = "CUSTOM ITEM"
		_detail_ui.group_fields(["name", "quantity", "uses"] if _phone else ["name", "quantity"], [2, 1, 1] if _phone else [1, 1])
		for key in ["name", "kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			_item_field(str(key), str(_new_item.get(str(key), "Equipment" if key == "kind" else "1" if key == "quantity" else "0" if key in ["uses", "range_feet", "armor_tier"] else "")), false)
		_primary("Add custom item", _owner())
	elif _detail == "ready_weapon":
		_detail_title.text = "Ready weapon"
		for index in range(_weapons.size()):
			var weapon: Dictionary = _weapons[index]
			_option(("Selected · " if str(weapon.inventory_id) == str(_nav.get("weapon", "")) else "") + str(weapon.get("name", "Weapon")) + " · " + str(weapon.get("damage", "")), _choose_ready_weapon.bind(index))
		if _detail_tab == 0:
			_action_input = _combat_options.duplicate(true)
			_combat_preparation()
		_primary("Attack", _can_act() and not _weapons.is_empty())
		_secondary("Damage", _owner() and not _draft.active and not _weapons.is_empty())
	elif _detail == "protection":
		_detail_title.text = "Protection & reactions"
		for raw in _items:
			var item: Dictionary = raw
			if item.get("equipped", false) and str(item.get("kind", "")) in ["Armor", "Shield"]:
				_option(str(item.get("name", "Protection")) + " · " + str(item.get("reduction", "")), _open_detail.bind("item:" + str(item.inventory_id)))
		_text("Defence is d20 + Agility. Resolve incoming damage, protection and reactions with the existing combat workflow or at the table.")
		_primary("Dodge · test Agility", _can_act())
	_detail_ui.finish_content(_detail_title.text if _detail_tab == 0 else "")

func _text(text: String) -> void:
	_detail_ui.append_text(_locale.text(text), _phone)

func _option(text: String, callback: Callable, enabled: bool = true) -> void:
	var button = _detail_ui.append_option(_locale.text(text), enabled and not _busy)
	button.pressed.connect(callback)

func _character_field(field: String, title: String) -> void:
	if not _draft.active:
		_text(title + "\n" + str(_projection.fields(_actor.data).get(field, "")))
		return
	var control = FIELD.instantiate()
	_detail_ui.field_host(field).add_child(control)
	control.configure_layout(_phone, _detail == "profile")
	_detail_ui.register_field(control)
	control.configure(field, title, _draft.value(field), field in ["description", "origin", "class_rules", "pack"] or field.ends_with(":rules"))
	control.changed.connect(_draft.change)
	_fields.append(control)

func _item_field(field: String, value: String, independent: bool) -> void:
	var control = FIELD.instantiate()
	_detail_ui.field_host(field).add_child(control)
	control.configure_layout(_phone, _detail == "profile")
	_detail_ui.register_field(control)
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
		_detail_title.text = "Item unavailable"
		_text("This item was removed. Return to Inventory for the current items.")
		return
	_detail_title.text = str(item.get("name", "Item"))
	if _detail_tab == 1:
		if _item_edit and _owner():
			_detail_ui.group_fields(["name", "quantity", "uses"] if _phone and not item.has("dose_pool") else ["name", "quantity"], [2, 1, 1] if _phone else [1, 1])
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
		var facts: Array = [["Quantity", str(item.get("quantity", 0))], ["State", "Ready" if item.get("equipped", false) else "Carried"]]
		for key in ["damage", "range_feet", "reduction", "armor_tier"]:
			if item.has(str(key)):
				facts.append([str(key).replace("_", " ").capitalize(), str(item.get(str(key)))])
		if item.has("dose_pool"):
			facts.append(["Shared laboratory doses", str(_projection.remaining_uses(_actor.data, item))])
		_detail_ui.append_facts(facts)
		var power := POWERS.new().definition(str(item.get("source_item_id", "")))
		var rule := RULES.new().definition(str(item.get("source_item_id", "")))
		if not power.is_empty():
			_action_input["modifier"] = _cast_modifier
			_workflow_field("modifier", "Situational modifier")
			_primary("Cast Power", _can_act() and int(item.get("quantity", 0)) > 0)
		elif not rule.is_empty():
			_primary("Brew decoctions" if rule.get("brew", false) else "Use item", not _draft.active and _owner() and _use_allowed(rule))
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
	elif _detail == "custom":
		for field in _fields:
			field.refresh_value(str(_new_item.get(str(field._field), "Equipment" if field._field == "kind" else "1" if field._field == "quantity" else "0" if field._field in ["uses", "range_feet", "armor_tier"] else "")))
	elif _draft.active and not _fields.is_empty():
		for field in _fields:
			field.refresh_value(_draft.value(str(field._field)))
	else:
		_request_detail()

func _primary(text: String, enabled: bool) -> void:
	if not enabled and text in ["Attack", "Test Strength", "Test Agility", "Test Presence", "Test Toughness", "Dodge · test Agility", "Cast Power", "Use feature", "Use item"] and not BROKEN.new().can_act(_data()):
		text = "Dead — cannot act" if BROKEN.new().is_dead(_data()) else "Cannot act yet"
	_primary_button.text = _locale.text(text)
	_primary_button.visible = true
	_primary_button.disabled = not enabled or _busy

func _secondary(text: String, enabled: bool = true) -> void:
	_secondary_button.text = _locale.text(text)
	_secondary_button.visible = true
	_secondary_button.disabled = not enabled or _busy

func _can_act() -> bool:
	return _owner() and not _draft.active and BROKEN.new().can_act(_actor.data)

func _back() -> void:
	if _detail == "workflow:improve" and _action_live() and not _ending_improvement:
		_ending_improvement = true
		_request_detail()
		return
	if not _history.is_empty() and not _detail.begins_with("workflow:"):
		var previous: Dictionary = _history.pop_back()
		_detail = str(previous.entry)
		_detail_tab = int(previous.tab)
		_render_detail()
		_detail_ui.restore_paging(previous.page)
		_show_route()
		return
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
		var focused: bool = _chapter_primary.focus_entry(_opened_entry)
		if not focused:
			focused = _chapter_resources.focus_entry(_opened_entry)
		if not focused:
			focused = _chapter_companions.focus_entry(_opened_entry)
		if not focused:
			focused = _chapter_story.focus_entry(_opened_entry)
		if not focused:
			focused = _chapter_notes.focus_entry(_opened_entry)
		if not focused:
			_chapters[int(_nav.get("chapter", 0))].grab_focus()

func _remember_opener(id: String) -> void:
	_opened_entry = id
	_return_detail = ""
	_opener = _core_opener()

func _core_opener():
	var ability = _core_ui.focused_entry()
	if ability != null:
		return ability
	for button in [_chapter_ui.get_node(^"ChapterCaption/Resource"), _chapter_personal_notes, _core_phone_name, _core_ready_weapon, _header_name, _header_rest, _header_improve, _core_origin, _core_hit_points, _core_power_uses, _core_omens, _core_protection, _core_dodge, _core_attack, _core_damage, _quick_quick_omens, _quick_quick_silver]:
		if button.has_focus():
			return button
	return null

func _catalogue_add(id: String) -> void:
	if _busy or not _owner():
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
	if not result.ok:
		_field_error(field, result.message)

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
		_accept_actor(result.actor)
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
	_scroll_choices.clear()
	_rerolls = []
	if kind in ["attack", "damage"]:
		_action_input["item"] = str(_nav.get("weapon", ""))
		_action_input["part"] = kind
		_action_input["difficulty"] = 0
		_action_input["modifier"] = 0
		for key in ["difficulty", "modifier", "fumble", "mode"]:
			_action_input[key] = _combat_options.get(key, "" if key == "mode" else 0)
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
	_ending_improvement = false
	_workflow_ui.begin()
	_detail = "workflow:" + kind
	_detail_tab = 0
	_end_action()
	_request_detail()
	_show_route()
	if kind in ["rest", "improve"]:
		_workflow_ui.focus_back()
	else:
		_detail_back.grab_focus()

func _render_workflow() -> void:
	if _action_kind in ["rest", "improve"]:
		_workflow_ui.configure(_data(), _action_kind, _rest, _action.snapshot if _action != null else {}, _portrait_texture)
	if _action_kind == "rest":
		_primary("Edit resolved resources" if _workflow_ui.is_daily() else "Done" if _action != null and _action.state in ["resolved", "ended", "error"] else "Roll recovery", _owner() and not _busy and not _action_live())
		return
	_detail_title.text = "Getting better—or worse" if _action_kind == "improve" else {"improve": "Getting better—or worse", "rest": "Rest", "attack": "Attack", "damage": "Damage", "ability": "Ability test", "cast": "Cast Power", "use": "Use item"}.get(_action_kind, "Action")
	if _action_kind == "improve":
		var panel = preload(ROOT + "ui/sheet_improvement_panel.tscn").instantiate()
		_detail_content.add_child(panel)
		panel.configure(_data(), _action.snapshot if _action != null else {}, _phone, _workflow_ui.prepared, _ending_improvement)
		if _ending_improvement:
			_primary("End procedure", true)
			_secondary("Continue procedure")
			return
	if _action != null:
		if _action_kind != "improve":
			_text(_action.message)
		if _action.state == "continue":
			var next := str(_action.snapshot.get("next_phase", ""))
			_primary({"hp_increase": "Roll d6 increase", "debris": "Continue to debris ›", "silver": "Roll 3d10 Silver", "abilities": "Continue to abilities ›", "class": "Continue to class ›", "specialty_roll": "Roll specialties", "finish": "Finish improvement"}.get(next, "Continue"), true)
			return
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
			_text("Selected scrolls: " + str(_scroll_choices))
			_option("Clear selected scrolls", _clear_scroll_choices)
			for family in [str(_action.snapshot.get("family", "unclean"))]:
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
	if _action_kind == "improve":
		_primary("Roll 6d10" if _workflow_ui.prepared else "Begin improvement", true)
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
		_primary("Brew decoctions" if rule.get("brew", false) else "Use item", _owner() and _use_allowed(rule))

func _combat_preparation() -> void:
	_detail_ui.group_fields(["difficulty", "modifier"], [1, 1])
	_workflow_field("difficulty", "DR override · 0 uses weapon rules")
	_workflow_field("modifier", "Situational modifier")
	_option("Fumble: " + str(_combat_options.get("fumble", "break")), _fumble_choice, _can_act())
	var traits: Array = _data().get("traits", [])
	for raw in traits:
		var combat_trait: Dictionary = raw
		if str(combat_trait.get("id", "")) == "cowards-jab":
			_option("Coward's jab" + (" · selected" if str(_combat_options.get("mode", "")) == "jab" else ""), _jab_choice, _can_act())

func _use_allowed(rule: Dictionary) -> bool:
	return BROKEN.new().can_act(_data()) or not (rule.has("ability") or rule.get("gob", false) or rule.get("blade", false))

func _workflow_field(field: String, title: String) -> void:
	var control = FIELD.instantiate()
	_detail_ui.field_host(field).add_child(control)
	control.configure_layout(_phone, _detail == "profile")
	_detail_ui.register_field(control)
	control.configure(field, title, str(_action_input.get(field, 0)))
	control.changed.connect(_workflow_typed)
	_fields.append(control)

func _workflow_typed(field: String, value: String) -> void:
	_action_input[field] = value
	if _detail.begins_with("item:") and field == "modifier":
		_cast_modifier = value
		return
	if field in ["difficulty", "modifier"]:
		_combat_options[field] = value

func _rest_selected(kind: String) -> void:
	if _action != null or _busy:
		return
	_rest = kind
	_request_detail()

func _fumble_choice() -> void:
	_combat_options["fumble"] = "lose" if str(_combat_options.get("fumble", "break")) == "break" else "break"
	_action_input["fumble"] = _combat_options["fumble"]
	_request_detail()

func _jab_choice() -> void:
	_combat_options["mode"] = "" if str(_combat_options.get("mode", "")) == "jab" else "jab"
	_action_input["mode"] = _combat_options["mode"]
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
	if _detail == "workflow:improve":
		if _ending_improvement:
			_back()
			_ending_improvement = false
			return
		if _action == null and not _workflow_ui.prepared:
			_workflow_ui.prepared = true
			_request_detail()
			return
		if _action != null and _action.state == "continue":
			await (_action as HEALTH).choose({"continue": true})
			return
	if _busy:
		return
	if _detail == "workflow:rest" and _workflow_ui.is_daily():
		if _action_live():
			return
		_leave_workflow()
		_detail = ""
		_edit()
		_open_detail("resource:power_uses")
		_detail_tab_selected(1)
	elif _detail.begins_with("workflow:"):
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
		await _direct_ability(_detail.trim_prefix("ability:") if _detail.begins_with("ability:") else "Agility")
	elif _detail.begins_with("trait:"):
		var traits: Array = _data().get("traits", [])
		var trait_entry: Dictionary = traits[int(_detail.split(":")[1])]
		_workflow("use", "feature:" + str(trait_entry.get("id", "")))
	elif _detail.begins_with("item:"):
		var item := _item(_detail.trim_prefix("item:"))
		if not POWERS.new().definition(str(item.get("source_item_id", ""))).is_empty():
			if not _cast_modifier.is_valid_int() or int(_cast_modifier) < -20 or int(_cast_modifier) > 20:
				_field_error("modifier", "Enter a whole number from −20 to +20.")
				return
			var id := _detail.trim_prefix("item:")
			_workflow("cast", id)
			_action_input["modifier"] = int(_cast_modifier)
			await _start_workflow()
		else:
			_workflow("use", _detail.trim_prefix("item:"))
	elif _detail == "custom":
		_busy = true
		var corrections := ACTIONS.new(sdk, _actor.id)
		var result := await corrections.add_custom(_new_item)
		_mutation_result(result)
		if result.ok:
			_back()
		else:
			_field_error(corrections.invalid_field, result.message)
	elif _detail.begins_with("actor:"):
		sdk.windows.open_actor(preload(ROOT + "ui/window_button.tres").window, SDK.ActorId.new(_detail.trim_prefix("actor:")))

func _direct_ability(ability: String) -> void:
	if not _can_act() or _action_live():
		return
	_workflow("ability", ability)
	await _start_workflow()

func _start_workflow() -> void:
	if not _owner() or _draft.active or _action_live():
		return
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
	if _scroll_choices.size() >= count:
		_scroll_choices.clear()
	_scroll_choices.append(id)
	var special := _action as SPECIAL
	if _scroll_choices.size() >= count and special != null:
		await special.choose_scrolls(_scroll_choices)
	_request_detail()

func _clear_scroll_choices() -> void:
	_scroll_choices.clear()
	_request_detail()

func _shield_choice(choice: String) -> void:
	var special := _action as SPECIAL
	if special != null:
		await special.choose_shield(choice)

func _secondary_action() -> void:
	if _detail == "workflow:improve" and _ending_improvement:
		_ending_improvement = false
		_request_detail()
		return
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
	_core_ui.configure_condition(data, condition, _phone)
	_condition_ui.configure(data, condition, _owner() and not _draft.active and not _busy and not _action_live())

func _edit_hit_points() -> void:
	_edit()
	if _draft.active:
		_open_detail("resource:hit_points")
		_detail_tab_selected(1)

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
	_appearance_ui.configure(sdk, _actor)
	_render_portrait(_actor.data)

func _choose_miniature() -> void:
	get_node(^"Margin/Layout/Body").visible = false
	get_node(^"Margin/Layout/Picker").visible = true
	get_node(^"Margin/Layout/Picker").open(sdk, _locale, _actor.id, "", _data().get("preferred_miniature", {}), false, "Character")

func _picker_closed(_saved: bool) -> void:
	get_node(^"Margin/Layout/Picker").visible = false
	get_node(^"Margin/Layout/Body").visible = true
	_refresh_pending = true
	_appearance_change_miniature.grab_focus()

func _render_portrait(data: Dictionary) -> void:
	_appearance_ui.configure(sdk, _actor)
	_portrait_texture = _appearance_ui.portrait(data)
	_core_condition_frame.visible = not _projection.condition(data).is_empty()
	_core_condition_badge.visible = not _projection.condition(data).is_empty()
	_core_portrait.texture = _portrait_texture

func _closed() -> void:
	get_node(^"EntryDialog").hide()
	get_node(^"EntryScrim").visible = false
	get_node(^"Margin/Layout/Picker").visible = false
	get_node(^"Margin/Layout/Body").visible = true
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
	if int(_nav.get("chapter", 0)) == 4:
		_chapter_ui.get_node(^"AppearanceStatus").text = _locale.text(message)
	get_node(^"Margin/Layout/Status").visible = not message.is_empty()
	get_node(^"Margin/Layout/Status").tooltip_text = _locale.text(message)
	get_node(^"Margin/Layout/Status").accessibility_description = _locale.text(message)

func _density() -> void:
	var canvas := get_viewport_rect().size
	_phone = canvas.y <= 560
	var tablet := canvas.x <= 1150 and not _phone
	get_node(^"Margin/Layout").add_theme_constant_override("separation", 8 if _phone else 16)
	get_node(^"Margin/Layout/Body").add_theme_constant_override("separation", 26 if _phone else 24 if tablet else 44)
	_core_ui.configure_layout(_phone, tablet)
	_chapter_ui.configure_layout(_phone, tablet)
	_header_name_edit.custom_minimum_size = Vector2(220 if _phone else 230 if tablet else 320, 44)
	_header_name_edit.add_theme_font_size_override("font_size", 18 if _phone or tablet else 20)
	_header_name_edit__caption.add_theme_font_size_override("font_size", 9 if _phone or tablet else 11)
	for button in [_header_name, _header_edit, _header_rest, _header_improve, _header_save_sheet, _header_cancel_sheet]:
		button.add_theme_font_size_override("font_size", 12 if _phone else 16)
	_header_name.add_theme_font_size_override("font_size", 22 if tablet else 28)
	if _actor != null:
		_core(_actor.data)
		_render_condition(_actor.data)
		_show_route()

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		_escape()
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

func _accept_actor(actor: SDK.Actor) -> void:
	var before := int(_data().get("hit_points", 0))
	_actor = actor
	if before > 0 and int(_data().get("hit_points", 0)) <= 0:
		_leave_workflow()
		_nav["chapter"] = 0
		_detail = ""

func _data() -> Dictionary:
	if _actor == null:
		return {}
	var data: Dictionary = _actor.data
	return data

func _choose_ready_weapon(index: int) -> void:
	_weapon_selected(index)
	_refresh_pending = true
	_request_detail()

func _field_error(field: String, message: String) -> void:
	for control in _fields:
		if control._field == field:
			control.show_error(message)
			_detail_ui.refresh_pages()
			return

func _escape() -> void:
	if _draft.active:
		_cancel_edit()
	elif get_node(^"Margin/Layout/Picker").visible:
		_picker_closed(false)
	elif not _detail.is_empty():
		_back()
	else:
		_close()

func _dismiss_detail() -> void:
	_history.clear()
	if _draft.active:
		_detail = ""
		_show_route()
		_edit_focus()
	else:
		_back()
