extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const CHARACTER_SHEET_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet.tscn")
const CHARACTER_CREATOR_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creator.tscn")

var _character_actor: SDK.Actor
var _character_content: VBoxContainer
var _character_creator: Variant
var _character_sheet: Variant
var _character_transition_pending := false
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
	if _surface_is_hidden() and _character_creator != null and _character_creator.is_active():
		# The managed host closes this surface by hiding it. Treat that boundary
		# exactly like a scene exit so pending creation can never resume hidden.
		_character_creator.discard()
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
	if str(result.actor.data.get("schema", "")) != "mork-borg-character/v1":
		return
	_character_actor = result.actor
	character_show_route("character")

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
	_character_tabs = get_node(^"Layout/Body/Content/CharacterTabs") as Control
	_character_tab_character = get_node(^"Layout/Body/Content/CharacterTabs/Character") as Button
	_character_tab_inventory = get_node(^"Layout/Body/Content/CharacterTabs/Inventory") as Button
	_character_tab_appearance = get_node(^"Layout/Body/Content/CharacterTabs/Appearance") as Button
	_catalogue_character = get_node(^"Layout/CatalogueBar/TrailingSlot/CreateCharacter") as Button
	_catalogue_back = get_node(^"Layout/CatalogueBar/LeadingSlot/Back") as Button
	_character_tab_character.pressed.connect(_on_tab_character)
	_character_tab_inventory.pressed.connect(_on_tab_inventory)
	_character_tab_appearance.pressed.connect(_on_tab_appearance)


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
	if _character_creator != null:
		_character_creator.discard()
		_character_creator.visible = false
	if _character_sheet != null:
		_character_sheet.visible = false
	_character_tabs.visible = false
	_catalogue_bar.visible = false


func character_primary_button_pressed() -> void:
	_ensure_character_content()
	if _character_creator.is_active():
		_character_creator.primary()
	else:
		character_show_route("create-class")
		_character_creator.begin()


func character_back_button_pressed() -> void:
	_ensure_character_content()
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
	if sdk == null:
		return
	var result: SDK.OperationResult = sdk.windows.set_title(title if _compact else "MÖRK BORG")
	if not result.ok:
		_set_status(result.message, true)


func _ensure_character_content() -> void:
	if _character_creator != null:
		return
	var creator = CHARACTER_CREATOR_SCENE.instantiate()
	creator.name = "CharacterCreator"
	creator.size_flags_horizontal = 3
	creator.configure(_definitions, _character_definition, _character_miniatures, _compact, sdk, _character_miniature_choices)
	creator.status_changed.connect(_on_creator_status)
	creator.busy_changed.connect(_on_creator_busy)
	creator.primary_changed.connect(_on_creator_primary)
	creator.character_created.connect(_on_creator_created)
	_content.add_child(creator)
	_character_creator = creator
	var sheet = CHARACTER_SHEET_SCENE.instantiate()
	sheet.name = "CharacterSheet"
	sheet.size_flags_horizontal = 3
	_content.add_child(sheet)
	_character_sheet = sheet
	creator.visible = false
	sheet.visible = false


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
	_ensure_character_content()
	_character_creator.clear_creation()
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
	_ensure_character_content()
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
	_header_subtitle.text = "No Class Character · private sheet"
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
