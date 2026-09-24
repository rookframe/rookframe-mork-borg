extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"


const CREATION_PROGRESS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_progress.gd")
@onready var _creation_progress: CREATION_PROGRESS = get_node(^"Layout/CreationProgress")

var _pending_companion: SDK.Actor
var _character_actor: SDK.Actor
var _character_content: VBoxContainer
const CHARACTER_CREATOR = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creator.gd")
var _character_creator: CHARACTER_CREATOR
var _last_sheet_route := ""
var _sheet_workflow_title := ""
var _restore_shield_focus := false
var _window_title_pending := false
var _requested_window_title := "MÖRK BORG"
const CHARACTER_SHEET = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet.gd")
var _character_sheet: CHARACTER_SHEET
var _character_transition_pending := false
var _creation_was_closed := false
var _character_tab := "character"
var _character_tabs: Control
var _character_tab_character: Button
var _character_tab_inventory: Button
var _character_tab_appearance: Button


var _route := "creatures"
var _compact := false
var _definitions: Array[SDK.ContentEntry] = []
var _actors: Array[SDK.Actor] = []
var _selected_definition: SDK.ContentEntry
var _selected_actor: SDK.Actor
var _busy := false
var _preserve_error := false
var _character_definition: SDK.ContentEntry
var _character_miniatures: Array[SDK.ContentEntry] = []
var _character_miniature_choices: Array[Dictionary] = []


func _process(_delta: float) -> void:
	if _window_title_pending and sdk != null and not _surface_is_hidden():
		var result: SDK.OperationResult = sdk.windows.set_title(_requested_window_title if _compact else "MÖRK BORG")
		_window_title_pending = not result.ok
	if _restore_shield_focus:
		_restore_shield_focus = false
		if _last_sheet_route == "defence":
			get_node(^"Layout/SheetActions/Back").grab_focus()
		else:
			_character_tab_character.grab_focus()
	if _pending_companion != null:
		var companion := _pending_companion
		_pending_companion = null
		_navigate_companion(companion)
	_update_character_density()
	if _character_sheet != null:
		_character_sheet.set_available_height(size.y)
	if _surface_is_hidden() and _character_creator != null and _character_creator.is_active():
		# The managed host closes this surface by hiding it. Treat that boundary
		# exactly like a scene exit so pending creation can never resume hidden.
		_character_creator.discard()
		_creation_was_closed = true
	if _creation_was_closed and not _surface_is_hidden():
		_creation_was_closed = false
		character_show_route("create-class")
		_character_creator.begin()
	if _character_transition_pending:
		_character_transition_pending = false
		character_show_route("character")


func _surface_is_hidden() -> bool:
	var node: Node = self
	while node != null:
		var control := node as Control
		if control != null and not control.visible:
			return true
		node = node.get_parent()
	return false


func opened(actor_id: SDK.ActorId) -> void:
	if sdk == null:
		return
	var result: SDK.ActorResult = sdk.actors.read(actor_id)
	if not result.ok or result.actor == null:
		_set_status(result.message if not result.ok else "Actor data is unavailable.", true)
		return
	var data: Dictionary = result.actor.data
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return
	_character_actor = result.actor
	character_show_route("character")
	var inbox: SDK.DataResult = await sdk.system_actions.submit("defence.inbox", {})
	if inbox.ok and typeof(inbox.value) == TYPE_ARRAY:
		var actions: Array = inbox.value
		for raw in actions:
			var action: Dictionary = raw
			if str(action.target) == actor_id.value and action.state in ["ready", "pending", "shield"]:
				_character_sheet.offer_defence(action)
				break

@onready var _layout := get_node(^"Layout") as VBoxContainer
@onready var _header := get_node(^"Layout/Header") as VBoxContainer
@onready var _brand := get_node(^"Layout/Header/Brand") as Label
@onready var _header_title := get_node(^"Layout/Header/Title") as Label
@onready var _header_subtitle := get_node(^"Layout/Header/Subtitle") as Label
@onready var _routes := get_node(^"Layout/Header/Routes") as Control
@onready var _routes_desktop := get_node(^"Layout/Header/Routes/Desktop") as Control
@onready var _routes_compact := get_node(^"Layout/Header/Routes/Compact") as Control
var _route_creatures: Button
var _route_creature: Button
var _route_edit: Button
var _route_inventory: Button
@onready var _body := get_node(^"Layout/Body") as ScrollContainer
@onready var _content := get_node(^"Layout/Body/Content") as VBoxContainer
@onready var _search = get_node(^"Layout/Body/Content/Search")
@onready var _definition_heading := get_node(^"Layout/Body/Content/DefinitionHeading") as Label
@onready var _definition_list := get_node(^"Layout/Body/Content/DefinitionList") as VBoxContainer
@onready var _live_heading := get_node(^"Layout/Body/Content/LiveHeading") as Label
@onready var _live_list := get_node(^"Layout/Body/Content/LiveList") as VBoxContainer
@onready var _public_heading := get_node(^"Layout/Body/Content/PublicHeading") as Label
@onready var _public_list := get_node(^"Layout/Body/Content/PublicList") as VBoxContainer
@onready var _detail := get_node(^"Layout/Body/Content/Detail") as VBoxContainer
@onready var _stats := get_node(^"Layout/Body/Content/Detail/Stats") as Control
@onready var _hit_points_metric := get_node(^"Layout/Body/Content/Detail/Stats/HitPoints/Content/Value") as Label
@onready var _morale_metric := get_node(^"Layout/Body/Content/Detail/Stats/Morale/Content/Value") as Label
@onready var _protection_metric := get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Value") as Label
@onready var _protection_label := get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Label") as Label
@onready var _sheet_grid := get_node(^"Layout/Body/Content/Detail/SheetGrid") as BoxContainer
@onready var _identity_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection") as Control
@onready var _public_identity := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/BodySlot/PublicIdentity") as Label
@onready var _equipment_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection") as Control
@onready var _equipment_list := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/BodySlot/EquipmentList") as VBoxContainer
@onready var _rules_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection") as Control
@onready var _rules := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection/Content/BodySlot/Rules") as Label
@onready var _access_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection") as Control
@onready var _edit_fields := get_node(^"Layout/Body/Content/Detail/EditFields") as VBoxContainer
@onready var _private_name = get_node(^"Layout/Body/Content/Detail/EditFields/PrivateName")
@onready var _public_label = get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel")
@onready var _hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/HitPoints")
@onready var _maximum_hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/MaximumHitPoints")
@onready var _morale = get_node(^"Layout/Body/Content/Detail/EditFields/Morale")
@onready var _inventory := get_node(^"Layout/Body/Content/Detail/Inventory") as Control
@onready var _inventory_items := get_node(^"Layout/Body/Content/Detail/Inventory/Content/BodySlot/Items") as VBoxContainer
@onready var _inventory_carried := get_node(^"Layout/Body/Content/Detail/Inventory/Content/BodySlot/CarriedItems") as VBoxContainer
@onready var _inventory_add := get_node(^"Layout/Body/Content/Detail/Inventory/Content/Header/AddItem") as Button
@onready var _action_bar := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar") as Control
@onready var _catalogue_bar := get_node(^"Layout/CatalogueBar") as Control
@onready var _status := get_node(^"Layout/Status") as Label
var _create_button: Button
var _edit_button: Button
var _inventory_button: Button
var _duplicate_button: Button
var _place_button: Button
var _save_button: Button
var _add_item_button: Button
var _back_button: Button
var _catalogue_create: Button
var _catalogue_character: Button
var _catalogue_back: Button




func character_setup() -> void:
	closed.connect(_window_closed)
	_header_title = get_node(^"Layout/Header/Title") as Label
	_header_subtitle = get_node(^"Layout/Header/Subtitle") as Label
	_content = get_node(^"Layout/Body/Content") as VBoxContainer
	_routes = get_node(^"Layout/Header/Routes") as Control
	_search = get_node(^"Layout/Body/Content/Search")
	_definition_heading = get_node(^"Layout/Body/Content/DefinitionHeading") as Label
	_definition_list = get_node(^"Layout/Body/Content/DefinitionList") as VBoxContainer
	_live_heading = get_node(^"Layout/Body/Content/LiveHeading") as Label
	_live_list = get_node(^"Layout/Body/Content/LiveList") as VBoxContainer
	_public_heading = get_node(^"Layout/Body/Content/PublicHeading") as Label
	_public_list = get_node(^"Layout/Body/Content/PublicList") as VBoxContainer
	_detail = get_node(^"Layout/Body/Content/Detail") as VBoxContainer
	_action_bar = get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar") as Control
	_catalogue_bar = get_node(^"Layout/CatalogueBar") as Control
	_status = get_node(^"Layout/Status") as Label
	_character_tabs = get_node(^"Layout/CharacterTabs") as Control
	_character_tab_character = get_node(^"Layout/CharacterTabs/Character") as Button
	_character_tab_inventory = get_node(^"Layout/CharacterTabs/Inventory") as Button
	_character_tab_appearance = get_node(^"Layout/CharacterTabs/Appearance") as Button
	_catalogue_character = get_node(^"Layout/CatalogueBar/TrailingSlot/CreateCharacter") as Button
	_catalogue_back = get_node(^"Layout/CatalogueBar/LeadingSlot/Back") as Button
	_character_tab_character.pressed.connect(_on_tab_character)
	_character_tab_inventory.pressed.connect(_on_tab_inventory)
	_character_tab_appearance.pressed.connect(_on_tab_appearance)
	_setup_character_content()


func character_set_content(definitions: Array[SDK.ContentEntry], character_definition: SDK.ContentEntry, miniatures: Array[SDK.ContentEntry], miniature_choices: Array[Dictionary] = []) -> void:
	_definitions = definitions
	_character_definition = character_definition
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	if _character_creator != null:
		_character_creator.configure(_definitions, _character_definition, _character_miniatures, _compact, sdk, _character_miniature_choices)


func character_select_actor(actor: SDK.Actor) -> void:
	_character_actor = actor


func character_hide_surface() -> void:
	_header.visible = true
	_creation_progress.visible = false
	_catalogue_create.visible = true
	if _character_creator != null:
		_character_creator.discard()
		_character_creator.visible = false
	if _character_sheet != null:
		_character_sheet.visible = false
	_character_tabs.visible = false
	_catalogue_bar.visible = false


func character_primary_button_pressed() -> void:
	if _character_creator.is_active():
		_character_creator.primary()
	else:
		character_show_route("create-class")
		_character_creator.begin()


func character_back_button_pressed() -> void:
	if _character_creator.is_active():
		_character_creator.start_over()
	else:
		_character_actor = null
		character_hide_surface()


func _on_tab_character() -> void:
	_select_character_tab("character")


func _on_tab_inventory() -> void:
	_select_character_tab("inventory")


func _on_tab_appearance() -> void:
	_select_character_tab("appearance")


func _exit_tree() -> void:
	if _character_creator != null:
		_character_creator.discard()


func _set_status(message: String, error: bool = false) -> void:
	_status.text = message
	_status.tooltip_text = message
	_status.visible = error or _busy


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)
	_catalogue_character.disabled = value or _character_definition == null


func _set_window_title(title: String) -> void:
	# Closing can produce a terminal report while the managed surface is absent.
	# Publish its current title after the ordinary surface becomes visible again.
	_requested_window_title = title
	_window_title_pending = true


func _setup_character_content() -> void:
	_character_creator = get_node(^"Layout/Body/Content/CharacterCreator")
	_character_sheet = get_node(^"Layout/Body/Content/CharacterSheet")
	_character_creator.stage_changed.connect(_on_creation_stage_changed)
	_character_creator.status_changed.connect(_on_creator_status)
	_character_creator.busy_changed.connect(_on_creator_busy)
	_character_creator.primary_changed.connect(_on_creator_primary)
	_character_creator.character_created.connect(_on_creator_created)
	_character_creator.scroll_choice_requested.connect(_on_scroll_choice_requested)
	_character_sheet.sheet_changed.connect(_on_sheet_changed)
	_character_sheet.actor_unavailable.connect(_on_character_unavailable)
	_character_sheet.workflow_changed.connect(_on_sheet_workflow_changed)
	_character_sheet.shield_decision_closed.connect(_on_shield_decision_closed)
	get_node(^"Layout/SheetActions/Back").pressed.connect(_cancel_sheet_workflow)
	get_node(^"Layout/SheetActions/Spend").pressed.connect(_spend_sheet_omen)
	get_node(^"Layout/SheetActions/Attack").pressed.connect(_roll_sheet_attack)
	_character_sheet.companion_selected.connect(_open_companion)


func _on_creation_stage_changed(step: int, title: String) -> void:
	_header_subtitle.text = title
	_creation_progress.present_progress(step, _compact)


func _on_creator_status(message: String, error: bool) -> void:
	_set_status(message, error)


func _on_creator_busy(value: bool) -> void:
	_busy = value
	_catalogue_character.disabled = value or _character_definition == null
	_set_status(_status.text, false)


func _on_creator_primary(text: String, disabled: bool) -> void:
	_catalogue_character.text = text
	_catalogue_character.disabled = disabled or _busy or _character_definition == null


func _on_creator_created(actor: SDK.Actor) -> void:
	_character_actor = actor
	_character_creator.visible = false
	_character_transition_pending = true


func _clear_character_content() -> void:
	_character_creator.clear_creation()
	get_node(^"Layout/SheetActions").visible = false
	_character_sheet.clear_character_sheet()
	_character_creator.visible = false
	_character_sheet.visible = false


func _set_search_visible(value: bool) -> void:
	var search_control: Control = _search as Control
	search_control.visible = value


func character_show_route(route: String) -> void:
	if sdk == null:
		return
	_route = route
	_clear_character_content()
	var creation := route.begins_with("create-")
	_set_search_visible(false)
	_definition_heading.visible = false
	_definition_list.visible = false
	_live_heading.visible = false
	_live_list.visible = false
	_public_heading.visible = false
	_public_list.visible = false
	_detail.visible = false
	_action_bar.visible = false
	_routes.visible = false
	_character_tabs.visible = not creation
	_catalogue_bar.visible = creation
	_catalogue_create.visible = false
	_creation_progress.visible = creation
	_brand.visible = false
	_header.visible = not _compact
	_catalogue_character.visible = creation
	_catalogue_back.visible = creation
	if creation:
		_character_creator.visible = true
		_character_sheet.visible = false
		_character_content = _character_creator
		_catalogue_back.text = "Start over"
		_catalogue_character.disabled = _busy or _character_definition == null
		_header_title.visible = not _compact
		_header_subtitle.visible = not _compact
		_header_title.text = "CREATE CHARACTER"
		_header_title.set("theme_override_font_sizes/font_size", 32)
		_set_window_title("CREATE CHARACTER")
		_character_creator.show_creation_route(route)
	else:
		_character_creator.visible = false
		_character_sheet.visible = true
		_character_content = _character_sheet
		_catalogue_back.visible = false
		_catalogue_character.visible = false
		_header_title.visible = not _compact
		_header_subtitle.visible = not _compact
		_build_character_sheet_route(route)
	_content.custom_minimum_size = Vector2(0, 0) if _compact else Vector2(0, 520)

func _build_character_sheet_route(route: String) -> void:
	if _character_actor == null:
		_set_status("Character data is unavailable.", true)
		return
	var latest: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if latest.ok and latest.actor != null:
		_character_actor = latest.actor
	var data: Dictionary = _character_actor.data
	var name: String = data.get("name", "Unnamed Character")
	_header_title.text = name.to_upper()
	_header_subtitle.text = str(data.get("class_title", "No Class")) + " Character · private sheet"
	_set_window_title(name)
	_character_tabs.visible = true
	_character_tab_character.button_pressed = _character_tab == "character"
	_character_tab_inventory.button_pressed = _character_tab == "inventory"
	_character_tab_appearance.button_pressed = _character_tab == "appearance"
	_character_sheet.set_character(_character_actor, _character_tab, route, _character_miniatures, _character_miniature_choices, sdk)


func _refresh_character_body(route: String) -> void:
	_clear_character_content()
	_character_sheet.visible = true
	_character_tabs.visible = true
	_build_character_sheet_route(route)


func _select_character_tab(tab: String) -> void:
	_character_tab = tab
	call_deferred("_refresh_character_body", "character")


func _on_sheet_changed() -> void:
	if _character_actor == null:
		return
	var latest: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if latest.ok and latest.actor != null:
		_character_actor = latest.actor
		var data: Dictionary = _character_actor.data
		var name: String = data.get("name", "Unnamed Character")
		if _last_sheet_route in ["character", "inventory", "appearance"]:
			_header_title.text = name.to_upper()
			_set_window_title(name)


func _update_character_density() -> void:
	if _character_creator == null or not (_route.begins_with("create-") or _route == "character"):
		return
	var compact := size.x < 600 or size.y < 500
	if compact == _compact:
		return
	_compact = compact
	_header.visible = not compact
	_header_title.visible = not compact
	_header_subtitle.visible = not compact and not _last_sheet_route in ["attack", "defence", "cast"]
	_content.custom_minimum_size = Vector2(0, 0) if compact else Vector2(0, 520)
	_layout.add_theme_constant_override("separation", 6 if compact else 10)
	_character_creator.set_compact(compact)
	if _route.begins_with("create-"):
		_set_window_title("CREATE CHARACTER")
	elif _character_actor != null:
		var data: Dictionary = _character_actor.data
		_set_window_title(_sheet_workflow_title if not _sheet_workflow_title.is_empty() else str(data.get("name", "Unnamed Character")))


func _open_companion(actor: SDK.Actor) -> void:
	_pending_companion = actor


func _navigate_companion(_actor: SDK.Actor) -> void:
	pass


func _on_scroll_choice_requested(_slot: String) -> void:
	_body.scroll_vertical = 0

func _on_character_unavailable() -> void:
	get_node(^"Layout/SheetActions").visible = false
	_character_actor = null
	_header_title.text = "CHARACTER UNAVAILABLE"
	_header_subtitle.text = ""
	_set_window_title("Character unavailable")
	_character_tabs.visible = false

func _on_sheet_workflow_changed(route: String, title: String, can_submit: bool, busy: bool) -> void:
	_sheet_workflow_title = title
	_header_title.theme_type_variation = "RookframeTitle" if route in ["attack", "defence", "cast"] else "RookframeHeading"
	if route in ["attack", "defence", "cast"]:
		_header_title.text = title.to_upper()
	elif _character_actor != null:
		var data: Dictionary = _character_actor.data
		_header_title.text = str(data.get("name", "Unnamed Character")).to_upper()
	_header_subtitle.visible = not _compact and not route in ["attack", "defence", "cast"]
	if route != _last_sheet_route:
		get_node(^"Layout/Body").scroll_vertical = 0
		_last_sheet_route = route
	_character_tabs.visible = route in ["character", "inventory", "appearance"]
	get_node(^"Layout/SheetActions").visible = route in ["omens", "attack", "defence", "cast"]
	get_node(^"Layout/SheetActions/Spend").visible = route == "omens"
	get_node(^"Layout/SheetActions/Attack").visible = route in ["attack", "defence", "cast"]
	get_node(^"Layout/SheetActions/Attack").disabled = not can_submit or busy
	get_node(^"Layout/SheetActions/Attack").text = "Waiting…" if busy else (("Roll damage" if title == "Roll damage" else "Roll defence") if route == "defence" else "Roll attack")
	if route == "cast" and not busy:
		get_node(^"Layout/SheetActions/Attack").text = _character_sheet.power_primary_text()
	get_node(^"Layout/SheetActions/Back").text = "Back to sheet" if route in ["attack", "defence", "cast"] and not can_submit and not busy else "Cancel"
	if route == "cast" and _character_sheet.power_primary_text() == "Done":
		get_node(^"Layout/SheetActions/Back").text = "Character"
	get_node(^"Layout/SheetActions/Spend").disabled = not can_submit or busy
	get_node(^"Layout/SheetActions/Back").disabled = busy and not route in ["attack", "defence", "cast"]
	_set_window_title(title)

func _cancel_sheet_workflow() -> void:
	_character_sheet.cancel_workflow()

func _spend_sheet_omen() -> void:
	_character_sheet.spend_omen()

func _window_closed() -> void:
	if _character_sheet != null:
		_character_sheet.close_action()
	if _character_creator != null and _character_creator.is_active():
		_creation_was_closed = true
		_character_creator.discard()

func _roll_sheet_attack() -> void:
	_character_sheet.roll_attack()

func _on_shield_decision_closed() -> void:
	_restore_shield_focus = true
