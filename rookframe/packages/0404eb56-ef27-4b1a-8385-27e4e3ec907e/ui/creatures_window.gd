extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_workflow.gd"
const TARGETS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/attack_targets.gd")
const LIVE_ACTOR_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/live_actor_row.tscn")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")

const CREATURE_KIND := "actor_definition"
var _pending_route := ""
const CREATURE_ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_actions.gd")
const INVENTORY_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_inventory.tscn")
const CATALOGUE_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/equipment_catalogue.tscn")
const ITEM_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.tscn")
const ITEM_EDITOR = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.gd")
var _creature_item_view: ITEM_EDITOR
var _creature_item_refresh_pending := false
var _creature_item_id := ""
const DEFENCE_ACTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_action.gd")
const CREATURE_MELEE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd")
const CREATURE_DEFENCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_defence_flow.gd")
@onready var _creature_defence: CREATURE_DEFENCE = get_node(^"Layout/Body/Content/CreatureDefence")
var _creature_melee: CREATURE_MELEE
var _creature_melee_update := false
var _creature_roll_mode := ""
var _initiated_defence: DEFENCE_ACTION
var _responsible_owner := ""
var _defence_update_pending := false
var _creature_attack: Dictionary = {}
var _creature_rook: SDK.RookId
var _checking_range := false
var _creature_preparation := 0
var _creature_targets_pending := false
var _creature_targets_reading := false
var _pending_creature_attack := ""
var _inventory_refresh_pending := false
var _world_refresh_pending := false

func ready() -> void:
	i18n.bind(sdk)
	localize(i18n)
	if sdk == null:
		_set_status("Install the published MÖRK BORG System to load Creature definitions.", true)
		return
	character_setup()
	resized.connect(_configure_surface_spacing)
	_creature_defence.changed.connect(_creature_defence_changed)
	_creature_defence.resolved.connect(_creature_defence_resolved)
	_creature_defence.decision_closed.connect(_creature_decision_closed)
	_creature_defence.access_lost.connect(_refresh_world)
	sdk.targeting.changed.connect(_creature_targets_changed)
	get_node(^"Layout/Body/Content/CreatureAttack").targets_requested.connect(_choose_creature_targets)
	_compact = not sdk.presentation_experience().is_desktop
	_routes_desktop.visible = not _compact
	_routes_compact.visible = _compact
	var route_group: Node = _routes_compact if _compact else _routes_desktop
	_route_creatures = route_group.get_node(^"Creatures") as Button
	_route_creature = route_group.get_node(^"Creature") as Button
	_route_edit = route_group.get_node(^"EditCreature") as Button
	_route_inventory = route_group.get_node(^"CreatureInventory") as Button

	_create_button = _action_bar.get_node(^"LeadingSlot/CreateCreature") as Button
	_edit_button = _action_bar.get_node(^"LeadingSlot/EditCreature") as Button
	_inventory_button = _action_bar.get_node(^"LeadingSlot/CreatureInventory") as Button
	_duplicate_button = _action_bar.get_node(^"LeadingSlot/Duplicate") as Button
	_place_button = _action_bar.get_node(^"LeadingSlot/PlaceRook") as Button
	_save_button = _action_bar.get_node(^"LeadingSlot/SaveChanges") as Button
	_add_item_button = _action_bar.get_node(^"LeadingSlot/AddItem") as Button
	_back_button = _action_bar.get_node(^"LeadingSlot/Back") as Button
	_catalogue_create = _catalogue_bar.get_node(^"TrailingSlot/CreateCreature") as Button
	_catalogue_character = _catalogue_bar.get_node(^"TrailingSlot/CreateCharacter") as Button
	_catalogue_back = _catalogue_bar.get_node(^"LeadingSlot/Back") as Button

	for button in [
		_route_creatures,
		_route_creature,
		_route_edit,
		_route_inventory,
		_search,
		_create_button,
		_edit_button,
		_inventory_button,
		_duplicate_button,
		_place_button,
		_save_button,
		_add_item_button,
		_back_button,
		_catalogue_create,
		_catalogue_character,
		_catalogue_back,
	]:
		button.focus_mode = 2

	_search.value_changed.connect(_filter_definitions)
	_catalogue.selected.connect(_select_definition)
	_route_creatures.pressed.connect(_on_creatures_route)
	_route_creature.pressed.connect(_on_creature_route)
	_route_edit.pressed.connect(_on_edit_route)
	_route_inventory.pressed.connect(_on_inventory_route)
	_edit_button.pressed.connect(_on_edit_route)
	_inventory_button.pressed.connect(_on_inventory_route)
	_create_button.pressed.connect(_create_creature)
	_catalogue_create.pressed.connect(_create_creature)
	_catalogue_character.pressed.connect(_character_primary_button_pressed)
	get_node(^"Layout/Body/Content/CreateCharacter").pressed.connect(_character_primary_button_pressed)
	_duplicate_button.pressed.connect(_duplicate_creature)
	_save_button.pressed.connect(_save_creature)
	_place_button.pressed.connect(_place_rook)
	_add_item_button.pressed.connect(_add_item)
	_back_button.pressed.connect(_on_back)
	_catalogue_back.pressed.connect(_character_back_button_pressed)
	if sdk.world_changed.is_connected(_refresh_world) == false:
		sdk.world_changed.connect(_refresh_world)
	_apply_density()
	_show_route("creatures")
	_refresh_world()


func _apply_density() -> void:
	_layout.add_theme_constant_override("separation", 6 if _compact else 10)
	_header.add_theme_constant_override("separation", 2 if _compact else 4)
	_content.add_theme_constant_override("separation", 8 if _compact else 12)
	_detail.add_theme_constant_override("separation", 8 if _compact else 12)
	_sheet_grid.vertical = _compact
	_sheet_grid.add_theme_constant_override("separation", 12 if _compact else 20)
	_content.custom_minimum_size = Vector2(0, 0) if _compact else Vector2(0, 520)
	# The managed host chrome already identifies the Package. Keep the body
	# focused on the active route so desktop does not repeat that identity above
	# the actor title.
	_brand.visible = false
	_header_subtitle.visible = not _compact
	_header_title.visible = true
	_status.visible = not _compact
	_body.add_theme_constant_override("scrollbar_width", 8 if _compact else 12)
	_stats.add_theme_constant_override("separation", 2 if _compact else 4)
	if _compact:
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/Header/Description").visible = false
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/Header/Description").visible = false
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection/Content/Header/Description").visible = false
		_protection_label.text = _t("ARMOR")


func _refresh_world() -> void:
	_creature_targets_pending = true
	if _creature_melee != null:
		_creature_melee.refresh()
	_world_refresh_pending = true


func _reload_world() -> void:
	if sdk == null:
		return
	var content: SDK.ContentEntryListResult = sdk.content.list(SDK.ContentKind.Value.ACTOR_DEFINITION)
	if not content.ok:
		_set_status(content.message, true)
		return
	_definitions = []
	for entry in content.items:
		if entry.kind == SDK.ContentKind.Value.ACTOR_DEFINITION:
			_definitions.append(entry)
			if entry.reference.local_id == "classless-character":
				_character_definition = entry
	_render_definitions()
	var miniatures: SDK.ContentEntryListResult = sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	_character_miniatures = miniatures.items if miniatures.ok else []
	var miniature_choices: Array[Dictionary] = []
	for entry in _character_miniatures:
		miniature_choices.append({
			"package_id": entry.reference.package_id,
			"local_id": entry.reference.local_id,
			"title": entry.title,
		})
	character_set_content(_definitions, _character_definition, _character_miniatures, miniature_choices)
	var actors: SDK.ActorListResult = sdk.actors.list()
	if not actors.ok:
		_set_status(actors.message, true)
		return
	_actors = actors.items
	if _selected_actor != null and _route in ["creature", "edit-creature", "creature-inventory", "creature-attack", "creature-catalogue", "creature-item", "creature-custom", "creature-defence"]:
		var latest := sdk.actors.read(_selected_actor.id)
		if not latest.ok or latest.actor == null or latest.actor.access_level == "None":
			_close_creature_actions()
			_selected_actor = null
			_show_route("creatures")
		elif _selected_actor.data != latest.actor.data or _selected_actor.access_level != latest.actor.access_level:
			_selected_actor = latest.actor
			if _route in ["creature", "creature-inventory"]:
				_render_actor()
			elif latest.actor.access_level != "Owner":
				_close_creature_actions()
				_show_route("creature")
			elif _route == "creature-item" and _creature_item_view != null:
				_creature_item_refresh_pending = true
	_render_live_actors()
	_render_public_names()


func _render_definitions() -> void:
	_catalogue.configure(_definitions, _selected_definition.reference.local_id if _selected_definition != null else "")
	_selected_definition = _catalogue.selection()
	_create_button.disabled = _selected_definition == null
	_catalogue_create.disabled = _selected_definition == null
	_filter_definitions(str(_search.get("value")))


func _render_live_actors() -> void:
	for child in _live_list.get_children():
		child.queue_free()
	for actor in _actors:
		var button = LIVE_ACTOR_ROW.instantiate()
		button.localize(i18n)
		var actor_data: Dictionary = actor.data
		var private_name: String = actor_data.get("name", "Private Creature")
		var public_name := actor.public_label if not actor.public_label.is_empty() else "Public name pending"
		button.title = _t("%s  ·  Public: %s") % [private_name, public_name]
		button.tooltip_text = button.title
		button.accessibility_name = button.title
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = 2
		button.alignment = 0
		button.theme_type_variation = "RookframeSecondaryButton"
		button.pressed.connect(_select_actor.bind(actor))
		_live_list.add_child(button)


func _render_public_names() -> void:
	for child in _public_list.get_children():
		child.queue_free()
	if sdk == null:
		return
	var identities: SDK.PublicIdentityListResult = sdk.public_identities.list()
	if not identities.ok:
		_set_status(identities.message, true)
		return
	for identity in identities.items:
		var label := Label.new()
		label.text = identity.label
		label.autowrap_mode = 2
		_public_list.add_child(label)


func _select_definition(entry: SDK.ContentEntry) -> void:
	_selected_definition = entry
	_create_button.disabled = false
	_catalogue_create.disabled = false
	_set_status(_t("Selected %s. Create a private Actor to edit its encounter sheet.") % entry.title)
	_show_route("creatures")


func _select_actor(actor: SDK.Actor) -> void:
	_close_creature_actions()
	_selected_actor = actor
	var actor_data: Dictionary = actor.data
	if actor_data.get("schema", "") == "mork-borg-character/v1":
		character_select_actor(actor)
		_show_route("character")
	else:
		_show_route("creature")
		_render_actor()


func _render_actor() -> void:
	if _selected_actor == null:
		return
	var actor_data: Dictionary = _selected_actor.data
	var private_name: String = actor_data.get("name", "Creature")
	var hit_points: int = actor_data.get("hit_points", 0)
	var maximum_hit_points: int = actor_data.get("maximum_hit_points", hit_points)
	var morale_data: Dictionary = actor_data.get("morale", {})
	var morale_kind: String = morale_data.get("kind", "none")
	var morale_number: int = morale_data.get("value", 0)
	var morale_value: String = "—" if morale_kind == "none" else "Special"
	if morale_kind == "fixed":
		morale_value = "%d" % morale_number
	var armor: Dictionary = actor_data.get("armor", {})
	var armor_name: String = armor.get("name", "No armor")
	var armor_reduction: String = armor.get("reduction", "")
	var attacks: Array = CREATURES.new().attack_options(actor_data)

	_header_title.text = private_name.to_upper()
	_header_subtitle.text = _t("Creature sheet · ") + _t(_selected_actor.access_level)
	_set_window_title(private_name)
	if _compact:
		_header_subtitle.visible = false
	_detail_title_if_present(private_name)
	_public_identity.text = _selected_actor.public_label if not _selected_actor.public_label.is_empty() else _t("Public name pending")
	_hit_points_metric.text = "%d / %d" % [hit_points, maximum_hit_points]
	_morale_metric.text = _t(morale_value)
	_protection_label.text = _t(armor_name).to_upper()
	_protection_metric.text = armor_reduction if not armor_reduction.is_empty() else "—"
	_rules.text = _t(str(actor_data.get("rules", "")))
	if actor_data.has("defence_dr"):
		var defence_dr: int = actor_data["defence_dr"]
		_rules.text = _t("Defence DR%d. %s") % [defence_dr, _t(str(actor_data.get("rules", "")))]
	_private_name.set("value", private_name)
	_public_label.set("value", _selected_actor.public_label)
	_public_label.visible = sdk.context().is_gm
	_hit_points.set("value", str(hit_points))
	_maximum_hit_points.set("value", str(maximum_hit_points))
	_morale.set("value", str(morale_number))
	_render_equipment(attacks)
	if _route in ["creature-inventory", "creature-catalogue", "creature-item", "creature-custom"]:
		_inventory_refresh_pending = true
	_save_button.disabled = _selected_actor.access_level != "Owner"
	_duplicate_button.disabled = not sdk.context().is_gm
	_place_button.disabled = _selected_actor.access_level != "Owner"
	_edit_button.disabled = _selected_actor.access_level != "Owner"
	_inventory_button.disabled = false


func _detail_title_if_present(private_name: String) -> void:
	var title := get_node(^"Layout/Body/Content/Detail/Title") as Label
	var summary := get_node(^"Layout/Body/Content/Detail/Summary") as Label
	title.text = private_name.to_upper()
	summary.text = _t("Private Creature sheet · GM")
	# The host/header already owns the route title. Keep the sheet body focused
	# on its stats and sections at every profile, including desktop.
	title.visible = false
	summary.visible = false



func _render_equipment(attacks: Array) -> void:
	for child in _equipment_list.get_children():
		child.queue_free()
	if attacks.is_empty():
		var empty := Label.new()
		empty.text = _t("No private attacks recorded.")
		empty.theme_type_variation = "RookframeMeta"
		_equipment_list.add_child(empty)
		return
	for index in range(attacks.size()):
		var attack: Dictionary = attacks[index]
		var row := Label.new()
		row.custom_minimum_size = Vector2(0, 54)
		row.autowrap_mode = 2
		row.theme_type_variation = "RookframeBody"
		var attack_name: String = _t(str(attack.get("name", "Attack")))
		var attack_dice: String = attack.get("dice", "—")
		var detail: String = _t("%s · %s ft") % [attack_dice, str(attack.get("range_feet", "—"))]
		if attack.has("attack_dr"):
			var attack_dr: int = attack["attack_dr"]
			detail += _t(" · Attack DR%d") % attack_dr
		row.text = "%s\n%s" % [attack_name, detail]
		_equipment_list.add_child(row)


func _render_inventory() -> void:
	_creature_item_view = null
	for child in _inventory.get_children():
		_inventory.remove_child(child)
		child.queue_free()
	var current: Dictionary = _selected_actor.data
	var data: Dictionary = current.duplicate(true)
	data["inventory"] = CREATURE_ITEMS.new(sdk, _selected_actor.id).inventory(data)
	data["read_only"] = _selected_actor.access_level != "Owner"
	if _route in ["creature-item", "creature-custom"]:
		var item_view = ITEM_VIEW.instantiate()
		item_view.localize(i18n)
		_creature_item_view = item_view
		_connect_creature_inventory(item_view)
		if _route == "creature-custom":
			item_view.configure({}, [])
			return
		var items: Array = data.inventory
		for raw in items:
			var item: Dictionary = raw
			if str(item.inventory_id) == _creature_item_id:
				item_view.configure(item, [])
				return
		item_view.show_missing()
		return
	if _route == "creature-catalogue":
		var catalogue = CATALOGUE_VIEW.instantiate()
		catalogue.localize(i18n)
		_connect_creature_inventory(catalogue)
		catalogue.configure(data, [])
		return
	var view = INVENTORY_VIEW.instantiate()
	view.localize(i18n)
	_connect_creature_inventory(view)
	view.configure(data, [])

func _connect_creature_inventory(view: Control) -> void:
	_inventory.add_child(view)
	view.mutation_requested.connect(_change_creature_item)
	view.navigate_requested.connect(_navigate_creature_inventory)

func _navigate_creature_inventory(route: String, id: String) -> void:
	if _busy or _selected_actor == null:
		return
	if route == "attack":
		var data: Dictionary = _selected_actor.data
		var items := CREATURE_ITEMS.new(sdk, _selected_actor.id).inventory(data)
		for raw in items:
			var item: Dictionary = raw
			if str(item.inventory_id) == id:
				_open_creature_attack(str(item.get("source_attack_id", id)))
		return
	if route in ["catalogue", "item", "custom"] and _selected_actor.access_level != "Owner":
		return
	_creature_item_id = id
	_show_route("creature-" + route)

func _change_creature_item(operation: String, arguments: Array) -> void:
	if _busy or _selected_actor == null:
		if _creature_item_view != null and operation == "item":
			_creature_field_result(str(arguments[1]), "Wait for the current save, then retry.", true)
		return
	var actions := CREATURE_ITEMS.new(sdk, _selected_actor.id)
	_set_busy(true, "Saving Inventory…")
	var result: SDK.ActorResult = await _perform_creature_item(actions, operation, arguments)
	_set_busy(false, "Inventory saved." if result.ok else result.message, not result.ok)
	if _creature_item_view != null and operation == "item":
		_creature_field_result(str(arguments[1]), "Saved." if result.ok else result.message, not result.ok)
	if result.ok:
		_selected_actor = result.actor
		if operation in ["add", "custom", "remove"]:
			_show_route("creature-inventory")
		elif _route != "creature-item":
			_inventory_refresh_pending = true


func _creature_field_result(field: String, message: String, error: bool) -> void:
	_creature_item_view.field_result(field, message, error)


func _perform_creature_item(actions: CREATURE_ITEMS, operation: String, arguments: Array) -> SDK.ActorResult:
	if operation == "add":
		return await actions.add_equipment(str(arguments[0]))
	if operation == "custom":
		return await actions.add_custom(arguments[0])
	if operation == "item":
		return await actions.change_item(str(arguments[0]), str(arguments[1]), str(arguments[2]))
	if operation == "remove":
		return await actions.remove_item(str(arguments[0]))
	return SDK.ActorResult.new({"ok": false, "message": "Unknown Inventory edit."})


func _show_route(route: String) -> void:
	_pending_route = route


func _process(delta: float) -> void:
	if _creature_melee_update:
		_creature_melee_update = false
		_present_creature_melee()
	if _creature_item_refresh_pending and not _busy:
		_creature_item_refresh_pending = false
		if _creature_item_view != null and _selected_actor != null:
			_creature_item_view.refresh_data(_selected_actor.data)
	if _world_refresh_pending and not _busy:
		_world_refresh_pending = false
		_reload_world()
	if _inventory_refresh_pending and not _busy:
		_inventory_refresh_pending = false
		if _selected_actor != null and _route in ["creature-inventory", "creature-catalogue", "creature-item", "creature-custom"]:
			_render_inventory()
	if _defence_update_pending:
		_defence_update_pending = false
		_present_initiated_defence()
	super._process(delta)
	if _creature_targets_pending and not _creature_targets_reading and _route == "creature-attack":
		_creature_targets_pending = false
		_refresh_creature_targets()
	if not _pending_creature_attack.is_empty():
		var id := _pending_creature_attack
		_pending_creature_attack = ""
		_present_creature_attack(id)
	if not _pending_route.is_empty():
		var route := _pending_route
		_pending_route = ""
		_apply_route(route)


func _apply_route(route: String) -> void:
	_creature_defence.visible = false
	get_node(^"Layout/Body/Content/CreatureAttack").visible = false
	get_node(^"Layout/SheetActions").visible = false
	if route.begins_with("create-") or route in ["character", "edit", "appearance"]:
		_show_character_route(route)
		return
	character_hide_surface()
	_preserve_error = false
	_route = route
	var catalogue := route == "creatures"
	_configure_surface_spacing()
	_header_title.theme_type_variation = "RookframeTitle" if catalogue else "RookframeHeading"
	var sheet := route == "creature"
	var edit := route == "edit-creature"
	var inventory := route in ["creature-inventory", "creature-catalogue", "creature-item", "creature-custom"]
	_sheet_grid.vertical = _compact or edit
	var inventory_edit := route in ["creature-catalogue", "creature-item", "creature-custom"]
	_routes.visible = not catalogue and not edit and not inventory_edit
	_route_creatures.visible = false
	_route_creature.visible = not catalogue
	_route_edit.visible = false
	_route_inventory.visible = not catalogue
	_route_creatures.button_pressed = catalogue
	_route_creature.button_pressed = sheet
	_route_edit.button_pressed = edit
	_route_inventory.button_pressed = inventory
	_header_title.visible = not _compact
	_header_subtitle.visible = not _compact
	_configure_catalogue_actions(catalogue)
	get_node(^"Layout/Body/Content/CreateCharacter").visible = catalogue and _character_definition != null
	_detail.visible = sheet or edit or inventory
	_set_search_visible(catalogue)
	_catalogue.visible = catalogue
	_live_heading.visible = catalogue and not _actors.is_empty()
	_live_list.visible = catalogue and not _actors.is_empty()
	_public_heading.visible = false
	_public_list.visible = false
	_stats.visible = sheet
	_identity_section.visible = sheet and sdk.context().is_gm
	_equipment_section.visible = sheet
	_rules_section.visible = sheet
	_access_section.visible = false
	_edit_fields.visible = edit
	_inventory.visible = inventory
	_action_bar.visible = sheet or edit
	_create_button.visible = false
	_edit_button.visible = sheet and _selected_actor != null and _selected_actor.access_level == "Owner"
	_inventory_button.visible = sheet
	_duplicate_button.visible = sheet and sdk.context().is_gm
	_place_button.visible = sheet and _selected_actor != null and _selected_actor.access_level == "Owner"
	_save_button.visible = edit and _selected_actor != null and _selected_actor.access_level == "Owner"
	_add_item_button.visible = false
	_back_button.visible = edit
	_back_button.text = _t("Cancel")
	if catalogue:
		_header_title.text = _t("CREATURES")
		_header_subtitle.text = _t("MÖRK BORG · 12 definitions")
		_set_window_title(_t("CREATURES"))
		_header_title.visible = not _compact
		_header_subtitle.visible = not _compact
		_set_status("Ready — immutable definitions are available to the GM.")
	elif _selected_actor != null:
		_render_actor()
	if edit:
		_header_title.text = _t("EDIT CREATURE")
		_header_subtitle.text = _t("Private values · public name")
		_set_window_title(_t("EDIT CREATURE"))
	elif inventory:
		var selected_data: Dictionary = _selected_actor.data
		var inventory_name: String = selected_data.get("name", "CREATURE")
		_header_title.text = inventory_name.to_upper()
		_header_subtitle.text = _t("Creature inventory · ") + _t(_selected_actor.access_level)
		_set_window_title(inventory_name)
	_set_status(_status.text)


func _show_character_route(route: String) -> void:
	if sdk == null:
		return
	_configure_surface_spacing()
	_header_title.theme_type_variation = "RookframeHeading"
	_route = route
	_preserve_error = false
	_routes.visible = false
	_set_search_visible(false)
	_catalogue.visible = false
	_live_heading.visible = false
	_live_list.visible = false
	_public_heading.visible = false
	_public_list.visible = false
	_detail.visible = false
	_action_bar.visible = false
	character_show_route(route)


func _on_creatures_route() -> void:
	_show_route("creatures")


func _on_creature_route() -> void:
	_show_route("creature")


func _on_edit_route() -> void:
	_show_route("edit-creature")


func _on_inventory_route() -> void:
	_show_route("creature-inventory")


func _filter_definitions(query: String) -> void:
	_catalogue.filter(query)


func _create_creature() -> void:
	if _busy or _selected_definition == null or sdk == null:
		return
	_set_busy(true, "Creating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(_selected_definition.reference, {})
	_set_busy(false, result.message if not result.ok else "Creature created.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_render_live_actors()
		_show_route("creature")


func _duplicate_creature() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_selected_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Private Creature data is unavailable.", true)
		return
	var source_data: Dictionary = source.actor.data
	var definition_id: String = source_data["definition_id"]
	var definition: SDK.ContentEntry
	for entry in _definitions:
		if entry.reference.local_id == definition_id:
			definition = entry
			break
	if definition == null:
		_set_status("The saved Creature definition is unavailable; duplicate was not created.", true)
		return
	var data: Dictionary = source_data.duplicate(true)
	# A separate duplicate is not another grant from the original creation.
	data.erase("creation_id")
	data.erase("creation_roll_sequence")
	data.erase("summoner_actor")
	data.erase("summon_action")
	data.erase("grant_source")
	_set_busy(true, "Duplicating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(definition.reference, data)
	_set_busy(false, result.message if not result.ok else "Creature duplicated.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_render_live_actors()
		_show_route("creature")


func _save_creature() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_selected_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Private Creature data is unavailable.", true)
		return
	var original_data: Dictionary = source.actor.data
	var data: Dictionary = original_data.duplicate(true)
	var original_label: String = source.actor.public_label
	data["name"] = str(_private_name.get("value")).strip_edges()
	data["hit_points"] = int(_hit_points.get("value"))
	data["maximum_hit_points"] = int(_maximum_hit_points.get("value"))
	var original_morale: Dictionary = original_data.get("morale", {})
	if str(original_morale.get("kind", "none")) == "fixed":
		data["morale"] = {"kind": "fixed", "value": int(_morale.get("value"))}
	_set_busy(true, "Saving private Creature sheet…")
	# Keep the pending state observable for one rendered frame before the
	# authority update completes.
	await get_tree().process_frame
	await get_tree().process_frame
	var updated: SDK.ActorResult = await sdk.actors.update(_selected_actor.id, data)
	if updated.ok and sdk.context().is_gm:
		var label := str(_public_label.get("value")).strip_edges()
		var identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, label)
		if not identity.ok:
			var rollback: SDK.ActorResult = await sdk.actors.update(_selected_actor.id, original_data)
			var rollback_message := ""
			if rollback.ok:
				var restored_identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, original_label)
				if not restored_identity.ok:
					rollback_message = _t(" Identity rollback failed: %s") % restored_identity.message
			else:
				rollback_message = _t(" Actor rollback failed: %s") % rollback.message
			updated.ok = false
			updated.message = identity.message + rollback_message
		else:
			updated.actor.public_label = label
	_set_busy(false, updated.message if not updated.ok else "Creature changes saved.", not updated.ok)
	if updated.ok:
		_selected_actor = updated.actor
		_render_live_actors()
		_show_route("creature")


func _place_rook() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var miniatures: SDK.ContentEntryListResult = sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	if not miniatures.ok or miniatures.items.is_empty():
		_set_status("Choose a published Miniature Package before placing this Rook.", true)
		return
	var label := _selected_actor.public_label.strip_edges()
	_set_busy(true, "Placing Creature Rook…")
	var created: SDK.RookResult = await sdk.rooks.create(miniatures.items[0].reference, SDK.SceneId.new("main"), Vector2(0, 0))
	if not created.ok:
		_set_busy(false, created.message, true)
		return
	var linked: SDK.OperationResult = await sdk.rooks.link(created.rook.id, _selected_actor.id)
	if not linked.ok:
		var deleted: SDK.OperationResult = await sdk.rooks.delete(created.rook.id)
		var link_message := linked.message
		if not deleted.ok:
			link_message += _t(" Cleanup failed: %s") % deleted.message
		_set_busy(false, link_message, true)
		return
	_selected_actor.public_label = label
	_refresh_world()
	_set_busy(false, "Creature Rook placed. Select it on the tabletop to act.")


func _add_item() -> void:
	_navigate_creature_inventory("catalogue", "")


func _on_back() -> void:
	if _route == "creature-inventory":
		_show_route("creature")
	else:
		_show_route("creatures")


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_preserve_error = not value and error
	_set_status(message, error)
	_create_button.disabled = value or _selected_definition == null
	_catalogue_create.disabled = value or _selected_definition == null
	_catalogue_character.disabled = value or _character_definition == null
	get_node(^"Layout/Body/Content/CreateCharacter").disabled = value or _character_definition == null
	_duplicate_button.disabled = value
	_save_button.disabled = value
	_place_button.disabled = value
	_add_item_button.disabled = value


func _set_status(message: String, error: bool = false) -> void:
	_status.text = _t(message)
	_status.tooltip_text = _t(message)
	_status.visible = error or _busy


func _character_primary_button_pressed() -> void:
	character_primary_button_pressed()


func _configure_catalogue_actions(catalogue: bool) -> void:
	var bar := get_node(^"Layout/CatalogueBar") as Control
	var back := bar.get_node(^"LeadingSlot/Back") as Button
	bar.visible = catalogue
	back.visible = catalogue
	back.disabled = false
	back.text = _t("Back")
	(bar.get_node(^"TrailingSlot/CreateCharacter") as Button).visible = false

func _character_back_button_pressed() -> void:
	if _route == "creatures":
		var surface := SDK.ExtensionSurface.new()
		surface.scene = load("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window.tscn")
		sdk.windows.close(surface)
	else:
		character_back_button_pressed()


func opened(actor_id: SDK.ActorId) -> void:
	var result: SDK.ActorResult = sdk.actors.read(actor_id)
	if result.ok and result.actor != null:
		_select_actor(result.actor)
		var inbox := await sdk.system_actions.submit("defence.inbox", {})
		if inbox.ok and typeof(inbox.value) == TYPE_ARRAY:
			var actions: Array = inbox.value
			for raw in actions:
				var action: Dictionary = raw
				if str(action.target) == actor_id.value and action.state in ["ready", "pending", "shield"]:
					_offer_actor_defence(result.actor, action)
					break
	else:
		_set_status(result.message, true)


func _navigate_companion(actor: SDK.Actor) -> void:
	_select_actor(actor)
	if _placing_companion:
		_placing_companion = false
		_place_rook()

func _creature_attack_requested(_next_route: String, id: String) -> void:
	_open_creature_attack(id)

func _open_creature_attack(id: String) -> void:
	_pending_creature_attack = id

func _present_creature_attack(id: String) -> void:
	if _selected_actor == null or _selected_actor.access_level != "Owner":
		return
	var data: Dictionary = _selected_actor.data
	var attacks: Array = CREATURES.new().attack_options(data)
	_creature_attack = {}
	for raw in attacks:
		var attack: Dictionary = raw
		if str(attack.get("id", "")) == id:
			_creature_attack = attack
	if _creature_attack.is_empty():
		return
	_close_creature_actions()
	_creature_roll_mode = ""
	_apply_route("creature-attack")
	_creature_rook = sdk.rooks.selected()
	_responsible_owner = ""
	get_node(^"Layout/Body/Content/CreatureAttack/Owners").visible = false
	var title := _t("%s attack") % _t(str(_creature_attack.get("name", "Attack")))
	_header_title.text = title.to_upper()
	_header_subtitle.visible = false
	_set_window_title(title)
	_routes.visible = false
	var view = get_node(^"Layout/Body/Content/CreatureAttack")
	view.visible = true
	var combat_data := data.duplicate(true)
	combat_data["inventory"] = CREATURE_ITEMS.new(sdk, _selected_actor.id).inventory(data)
	view.configure(combat_data, {"name": _creature_attack.name, "damage": _creature_attack.dice, "range_feet": _creature_attack.range_feet, "ammunition": _creature_attack.get("ammunition", ""), "natural": _creature_attack.get("natural", false)}, {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}, "ready", "")
	view.get_node(^"Metrics/Strength").visible = true
	view.get_node(^"Context").text = str(data.get("name", "Creature")) + _t(" · Selected attack")
	_creature_targets_pending = true
	var source_rules := _t(str(_creature_attack.get("rules", "")))
	if _creature_attack.has("defence_dr"):
		source_rules = _t("Defence DR%s. %s") % [str(_creature_attack.defence_dr), source_rules]
	if _creature_attack.has("attack_dr"):
		source_rules = _t("Attack DR%s. %s") % [str(_creature_attack.attack_dr), source_rules]
	if _creature_attack.get("natural", false):
		source_rules += _t(" Natural-weapon fumbles are adjudicated by the GM.")
	view.get_node(^"SourceRules").text = source_rules.strip_edges()
	view.get_node(^"SourceRules").visible = not source_rules.is_empty()
	get_node(^"Layout/SheetActions").visible = true
	get_node(^"Layout/SheetActions/Spend").visible = false
	get_node(^"Layout/SheetActions/Back").text = _t("Back to Inventory")
	get_node(^"Layout/SheetActions/Back").disabled = false
	get_node(^"Layout/SheetActions/Attack").visible = true
	get_node(^"Layout/SheetActions/Attack").text = _t("Use attack")
	get_node(^"Layout/SheetActions/Attack").disabled = false
	_body.scroll_vertical = 0

func _choose_creature_targets() -> void:
	get_node(^"Layout/Body/Content/CreatureAttack/Outcome").visible = false
	var result := sdk.targeting.choose()
	if not result.ok:
		_set_status(result.message, true)

func _roll_sheet_attack() -> void:
	if _route == "creature-defence":
		_creature_defence.roll()
		return
	if _route != "creature-attack":
		super._roll_sheet_attack()
		return
	if _checking_range:
		return
	if _creature_rook == null:
		_set_status("Select this Creature’s source Rook before opening its attack.", true)
		return
	if (_initiated_defence != null and _initiated_defence.pending) or (_creature_melee != null and _creature_melee.pending):
		return
	var view = get_node(^"Layout/Body/Content/CreatureAttack")
	var options: Dictionary = view.options()
	if options.is_empty():
		_creature_attack_error("Enter whole numbers for difficulty and modifier.")
		return
	var input := {"source": _selected_actor.id.value, "rook": _creature_rook.value, "attack": str(_creature_attack.id), "owner": _responsible_owner}
	for key in ["difficulty", "modifier", "fumble", "piercing", "ammunition"]:
		input[key] = options[key]
	_checking_range = true
	var preparation := _creature_preparation
	var prepared := await sdk.system_actions.submit("attack.validate", input)
	_checking_range = false
	if preparation != _creature_preparation or _route != "creature-attack" or _surface_is_hidden():
		return
	if not prepared.ok:
		_creature_attack_error(prepared.message)
		return
	var outcome: Dictionary = prepared.value
	if outcome.state != "ready":
		_creature_attack_error(str(outcome.message))
		return
	_creature_roll_mode = str(outcome.resolution)
	if _creature_roll_mode == "attack":
		if _creature_melee != null:
			_creature_melee.retire()
		var melee := CREATURE_MELEE.new(sdk)
		add_child(melee)
		_creature_melee = melee
		_creature_melee.changed.connect(_creature_melee_changed)
		input["item"] = str(_creature_attack.get("inventory_id", "creature:" + str(_creature_attack.id)))
		await _creature_melee.start(input)
	else:
		if _initiated_defence != null:
			_initiated_defence.retire()
		var action := DEFENCE_ACTION.new(sdk)
		add_child(action)
		_initiated_defence = action
		_initiated_defence.changed.connect(_initiated_defence_changed)
		await _initiated_defence.start(input)

func _creature_attack_error(message: String) -> void:
	var outcome: Label = get_node(^"Layout/Body/Content/CreatureAttack/Outcome")
	outcome.visible = true
	outcome.text = _t(message)
	outcome.theme_type_variation = "RookframeError"

func _creature_melee_changed() -> void:
	_creature_melee_update = true

func _present_creature_melee() -> void:
	if _route != "creature-attack" or _creature_melee == null:
		return
	var action := _creature_melee
	get_node(^"Layout/SheetActions/Attack").disabled = action.pending or action.state in ["resolved", "ended"]
	get_node(^"Layout/SheetActions/Attack").text = _t("Waiting…") if action.pending else _t("Roll attack")
	var view = get_node(^"Layout/Body/Content/CreatureAttack")
	view.get_node(^"Target/Change").disabled = action.pending
	view.get_node(^"Rules").visible = action.state == "error"
	view.get_node(^"Outcome").visible = true
	view.get_node(^"Outcome").text = _t(action.message)
	view.get_node(^"Outcome").theme_type_variation = "RookframeError" if action.state == "error" else "RookframeMeta"

func _initiated_defence_changed() -> void:
	_defence_update_pending = true

func _present_initiated_defence() -> void:
	if _initiated_defence.state == "ready" and str(_initiated_defence.snapshot.get("defender", "")) == sdk.context().participant_id:
		var target := sdk.actors.read(SDK.ActorId.new(str(_initiated_defence.snapshot.target)))
		if target.ok:
			_offer_actor_defence(target.actor, _initiated_defence.snapshot)
		return
	if _route != "creature-attack":
		return
	var action := _initiated_defence
	get_node(^"Layout/SheetActions/Attack").disabled = action.pending or action.state in ["resolved", "ended"]
	get_node(^"Layout/SheetActions/Attack").text = _t("Waiting…") if action.pending else _t("Request defence")
	var view = get_node(^"Layout/Body/Content/CreatureAttack")
	view.get_node(^"Target/Change").disabled = action.pending
	view.get_node(^"Outcome").visible = action.state != "resolved"
	view.get_node(^"Outcome").text = _t("Waiting for the defending Player.") if action.state in ["ready", "shield"] else action.message
	view.get_node(^"Outcome").theme_type_variation = "RookframeError" if action.state == "error" else "RookframeMeta"
	var choices: Array = action.snapshot.get("owners", [])
	var owners: VBoxContainer = view.get_node(^"Owners")
	for child in owners.get_children():
		owners.remove_child(child)
		child.queue_free()
	owners.visible = not choices.is_empty()
	for raw in choices:
		var choice: Dictionary = raw
		var button := Button.new()
		button.text = str(choice.name)
		button.custom_minimum_size = Vector2(0, 44)
		button.theme_type_variation = "RookframeSecondaryButton"
		button.pressed.connect(_select_defender.bind(str(choice.id)))
		owners.add_child(button)

func _select_defender(id: String) -> void:
	_responsible_owner = id
	_roll_sheet_attack()

func _window_closed() -> void:
	super._window_closed()
	_close_creature_actions()

func _close_creature_actions() -> void:
	_creature_preparation += 1
	if _creature_melee != null:
		_creature_melee.cancel()
	if _initiated_defence != null:
		_initiated_defence.cancel()
	if _creature_defence != null:
		_creature_defence.close()

func _cancel_sheet_workflow() -> void:
	if _route in ["creature-attack", "creature-defence"]:
		_close_creature_actions()
		_show_route("creature-inventory")
	else:
		super._cancel_sheet_workflow()

func _creature_targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_creature_targets_pending = true

func _refresh_creature_targets() -> void:
	_creature_targets_reading = true
	var reach: float = _creature_attack.get("range_feet", 0)
	var summary: String = await TARGETS.new().describe(sdk, _creature_rook, reach)
	_creature_targets_reading = false
	if _route == "creature-attack":
		get_node(^"Layout/Body/Content/CreatureAttack").set_targets(summary)

func _offer_actor_defence(actor: SDK.Actor, outcome: Dictionary) -> void:
	var data: Dictionary = actor.data
	_pending_route = ""
	if str(data.get("schema", "")) == "mork-borg-character/v1":
		_character_actor = actor
		character_show_route("character")
		get_node(^"Layout/Body/Content/CreatureAttack").visible = false
		_character_sheet.offer_defence(outcome)
		return
	_selected_actor = actor
	_apply_route("creature-defence")
	_routes.visible = false
	_header_title.text = str(data.get("name", "Creature")).to_upper() + _t(" · DEFENCE")
	_header_subtitle.visible = false
	_set_window_title(str(data.get("name", "Creature")) + _t(" · Defence"))
	_creature_defence.visible = true
	_creature_defence.present(sdk, outcome)
	_body.scroll_vertical = 0
	get_node(^"Layout/SheetActions").visible = true
	get_node(^"Layout/SheetActions/Spend").visible = false
	get_node(^"Layout/SheetActions/Back").text = _t("Cancel")
	get_node(^"Layout/SheetActions/Back").disabled = false

func _creature_defence_changed(state: String, can_roll: bool, automatic_hit: bool) -> void:
	if _route != "creature-defence":
		return
	var button: Button = get_node(^"Layout/SheetActions/Attack")
	button.visible = true
	button.disabled = not can_roll
	button.text = (_t("Roll damage") if automatic_hit else _t("Roll defence")) if state == "ready" else _t("Waiting…")
	get_node(^"Layout/SheetActions/Back").text = _t("Back to Inventory") if state in ["ended", "resolved"] else _t("Cancel")

func _creature_defence_resolved() -> void:
	if _route == "creature-defence":
		_show_route("creature-inventory")
		_inventory_refresh_pending = true

func _creature_decision_closed() -> void:
	get_node(^"Layout/SheetActions/Back").grab_focus()


func _configure_surface_spacing() -> void:
	var compact := size.x < 600
	_layout.offset_left = 12.0 if compact else 24.0
	_layout.offset_right = -_layout.offset_left
	_layout.offset_top = 0.0 if compact else 16.0
	_layout.offset_bottom = -6.0 if compact else -8.0
	_layout.add_theme_constant_override("separation", 8 if compact else 20)


func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Layout/Body/Content/CharacterDescriptionField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CharacterHitPointsField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CharacterItemField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CharacterNameField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CharacterOmensField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CharacterSilverField").label_text = _t("Field label")
	get_node(^"Layout/Body/Content/CreateCharacter").text = _t("Create Character")
	get_node(^"Layout/Body/Content/CreateCharacter").tooltip_text = _t("Start a new Character")
	get_node(^"Layout/Body/Content/Detail/EditFields/HitPoints").label_text = _t("HIT POINTS")
	get_node(^"Layout/Body/Content/Detail/EditFields/HitPoints").placeholder = _t("Private hit points")
	get_node(^"Layout/Body/Content/Detail/EditFields/IdentityHeading").text = _t("IDENTITY")
	get_node(^"Layout/Body/Content/Detail/EditFields/MaximumHitPoints").label_text = _t("MAXIMUM HIT POINTS")
	get_node(^"Layout/Body/Content/Detail/EditFields/MaximumHitPoints").placeholder = _t("Private maximum hit points")
	get_node(^"Layout/Body/Content/Detail/EditFields/Morale").label_text = _t("MORALE")
	get_node(^"Layout/Body/Content/Detail/EditFields/Morale").placeholder = _t("Private morale")
	get_node(^"Layout/Body/Content/Detail/EditFields/PrivateName").label_text = _t("PRIVATE NAME")
	get_node(^"Layout/Body/Content/Detail/EditFields/PrivateName").placeholder = _t("Private name")
	get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel").help_text = _t("Only the public name appears to Players.")
	get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel").label_text = _t("PUBLIC NAME")
	get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel").placeholder = _t("Public name shown to Players")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/Header/Description").text = _t("Private encounter equipment and attacks.")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/Header/Title").text = _t("EQUIPMENT")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/BodySlot/PrivateNotice").text = _t("Shown on the tabletop and in public reports.")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/BodySlot/PublicIdentity").text = _t("Hooded stranger")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/BodySlot/PublicNameLabel").text = _t("PUBLIC NAME")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/Header/Description").text = _t("Players see the chosen public name on the tabletop.")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/Header/Title").text = _t("PUBLIC IDENTITY")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection/Content/BodySlot/Access").text = _t("Players see the public name, not this sheet.")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection/Content/Header/Description").text = _t("GM only")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection/Content/Header/Title").text = _t("ACCESS")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/AddItem").text = _t("Add item")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/Back").text = _t("Back")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/CreateCreature").text = _t("Create Creature")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/CreatureInventory").text = _t("Inventory")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/Duplicate").text = _t("Duplicate")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/EditCreature").text = _t("Edit values")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/PlaceRook").text = _t("Place Rook")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar/LeadingSlot/SaveChanges").text = _t("Save changes")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection/Content/BodySlot/Rules").text = _t("Quick, attacks and defence are DR14.")
	get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection/Content/Header/Title").text = _t("SPECIAL RULES")
	get_node(^"Layout/Body/Content/Detail/Stats/HitPoints/Content/Label").text = _t("HP")
	get_node(^"Layout/Body/Content/Detail/Stats/Morale/Content/Label").text = _t("MORALE")
	get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Label").text = _t("PROTECTION")
	get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Value").text = _t("−d2")
	get_node(^"Layout/Body/Content/Detail/Summary").text = _t("Private Creature sheet · GM")
	get_node(^"Layout/Body/Content/Detail/Title").text = _t("Seth, Goblin")
	get_node(^"Layout/Body/Content/LiveHeading").text = _t("LIVE CREATURES")
	get_node(^"Layout/Body/Content/PublicHeading").text = _t("PUBLIC NAMES")
	get_node(^"Layout/Body/Content/Search").label_text = _t("SEARCH CREATURES")
	get_node(^"Layout/Body/Content/Search").placeholder = _t("Search creatures…")
	get_node(^"Layout/CatalogueBar/LeadingSlot/Back").text = _t("Back")
	get_node(^"Layout/CatalogueBar/TrailingSlot/CreateCharacter").text = _t("Create Character")
	get_node(^"Layout/CatalogueBar/TrailingSlot/CreateCreature").text = _t("Create Creature")
	get_node(^"Layout/CharacterTabs/Appearance").text = _t("Appearance")
	get_node(^"Layout/CharacterTabs/Character").text = _t("Character")
	get_node(^"Layout/CharacterTabs/Inventory").text = _t("Inventory")
	get_node(^"Layout/Header/Brand").text = _t("MÖRK BORG")
	get_node(^"Layout/Header/Routes/Compact/Creature").text = _t("Creature")
	get_node(^"Layout/Header/Routes/Compact/CreatureInventory").text = _t("Inventory")
	get_node(^"Layout/Header/Routes/Compact/Creatures").text = _t("Creatures")
	get_node(^"Layout/Header/Routes/Compact/EditCreature").text = _t("Edit")
	get_node(^"Layout/Header/Routes/Desktop/Creature").text = _t("Creature")
	get_node(^"Layout/Header/Routes/Desktop/CreatureInventory").text = _t("Inventory")
	get_node(^"Layout/Header/Routes/Desktop/Creatures").text = _t("Creatures")
	get_node(^"Layout/Header/Routes/Desktop/EditCreature").text = _t("Edit")
	get_node(^"Layout/Header/Subtitle").text = _t("Immutable definitions · private Actors")
	get_node(^"Layout/Header/Title").text = _t("CREATURES")
	get_node(^"Layout/SheetActions/Attack").text = _t("Roll attack")
	get_node(^"Layout/SheetActions/Back").text = _t("Cancel")
	get_node(^"Layout/SheetActions/Spend").text = _t("Spend 1 Omen")
	get_node(^"Layout/Body/Content/Catalogue").localize(locale)
	get_node(^"Layout/Body/Content/CharacterCreator").localize(locale)
	get_node(^"Layout/Body/Content/CharacterSheet").localize(locale)
	get_node(^"Layout/Body/Content/CreatureAttack").localize(locale)
	get_node(^"Layout/Body/Content/CreatureDefence").localize(locale)
	get_node(^"Layout/CreationProgress").localize(locale)
