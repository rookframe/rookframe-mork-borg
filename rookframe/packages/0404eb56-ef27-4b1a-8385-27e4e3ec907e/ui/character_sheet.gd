extends VBoxContainer

const TARGETS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/attack_targets.gd")
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const COMPANIONS_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_companions.tscn")
const CHARACTER_SHEET_VIEW_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_view.tscn")

signal companion_selected(actor: SDK.Actor)
signal companion_placement_requested(actor: SDK.Actor)
signal sheet_changed
signal workflow_changed(route: String, title: String, can_submit: bool, busy: bool)
signal shield_decision_closed
signal actor_unavailable
const ABILITY_THROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/ability_throw.gd")
const MELEE_ACTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/melee_action.gd")
const MELEE_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/melee_attack.gd")
const MELEE_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/melee_attack.tscn")
const DEFENCE_ACTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_action.gd")
const DEFENCE_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/defence_view.tscn")
const DEFENCE_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/defence_view.gd")
const SHIELD_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/shield_dialog.tscn")
const SHIELD_DIALOG = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/shield_dialog.gd")
const POWERS_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/powers_panel.tscn")
const POWERS_PANEL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/powers_panel.gd")
const SPECIAL_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/special_panel.tscn")
const SPECIAL_PANEL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/special_panel.gd")
const HEALTH_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/health_panel.tscn")
const HEALTH_PANEL = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/health_panel.gd")
var _health_panel: HEALTH_PANEL
var _health_action: MELEE_ACTION
var _special_panel: SPECIAL_PANEL
var _special_action: MELEE_ACTION
var _powers_panel: POWERS_PANEL
var _powers_action: MELEE_ACTION
var _defence_update_pending := false
var _defence: DEFENCE_ACTION
var _defence_view: DEFENCE_VIEW
const SHIELD_BACKDROP = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/shield_backdrop.tscn")
var _shield_backdrop: CanvasLayer
var _shield: SHIELD_DIALOG
var _melee: MELEE_ACTION
var _melee_view: MELEE_VIEW
var _melee_options := {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}
var _target_refresh_pending := false
var _target_reading := false
var _attack_item: Dictionary = {}
var _ability_throw: ABILITY_THROW
var _throw_refresh_pending := false
var _refresh_pending := false
var _observed_selection := ""

var sdk: SDK
var _character_actor: SDK.Actor
var _character_miniatures: Array[SDK.ContentEntry] = []
var _character_miniature_choices: Array[Dictionary] = []
var _character_tab := "character"
var _character_route := "character"
const SHEET_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_view.gd")
var _character_view: SHEET_VIEW
var _status: Label
var _busy := false
var _render_pending := false
var _short_window := false
var _item_id := ""
var _selected_rook: SDK.RookId
const ACTIONS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/character_actions.gd")
@onready var _content := get_node(^"Content") as VBoxContainer


func set_character(actor: SDK.Actor, tab: String, route: String, miniatures: Array[SDK.ContentEntry], miniature_choices: Array[Dictionary], facade: SDK) -> void:
	if _character_actor != null and _character_actor.id.value != actor.id.value:
		close_action()
		_ability_throw = null
		if _melee != null:
			_melee.retire()
		_melee = null
		if _defence != null:
			_defence.retire()
		_defence = null
		_defence_update_pending = false
	if _ability_throw != null and not _ability_throw.pending:
		_ability_throw = null
	_character_actor = actor
	_character_tab = tab
	_character_route = route
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	sdk = facade
	if not sdk.world_changed.is_connected(_world_changed):
		sdk.world_changed.connect(_world_changed)
	if not sdk.targeting.changed.is_connected(_targets_changed):
		sdk.targeting.changed.connect(_targets_changed)
	_render_pending = true


func _process(_delta: float) -> void:
	if _defence_update_pending:
		_defence_update_pending = false
		_present_defence_update()
	if _throw_refresh_pending:
		_throw_refresh_pending = false
		if _ability_throw != null:
			_ability_throw.refresh()
		if _melee != null:
			_melee.refresh()
	if not visible:
		return
	if _target_refresh_pending and not _target_reading:
		_target_refresh_pending = false
		_refresh_attack_targets()
	if _refresh_pending and not _busy:
		_refresh_pending = false
		refresh_from_world()
	if sdk != null and _character_tab == "appearance" and not _busy:
		var selected: SDK.RookId = sdk.rooks.selected()
		var identity: String = selected.value if selected != null else ""
		if identity != _observed_selection:
			_observed_selection = identity
			_render_pending = true
	if _render_pending:
		_render_pending = false
		_render_character_sheet()


func clear_character_sheet() -> void:
	if _health_panel != null:
		_health_panel.close_action()
	_health_panel = null
	if _health_action != null:
		_health_action.retire()
	_health_action = null
	if _special_panel != null:
		_special_panel.close_action()
	_special_panel = null
	if _special_action != null:
		_special_action.retire()
	_special_action = null
	if _powers_panel != null:
		_powers_panel.close_action()
	_powers_panel = null
	if _powers_action != null:
		_powers_action.retire()
	_powers_action = null
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_character_view = null
	_melee_view = null
	_defence_view = null
	_status = get_node(^"Status") as Label


func _render_character_sheet() -> void:
	if _character_route in ["rest", "improve", "broken"] and _character_actor != null:
		if _health_panel == null:
			clear_character_sheet()
			var panel := HEALTH_SCENE.instantiate()
			_content.add_child(panel)
			_health_panel = panel
			_health_panel.navigate_requested.connect(_navigate)
			_health_panel.action_created.connect(_health_action_created)
			_health_panel.workflow_changed.connect(_power_chrome)
		_health_panel.configure(_character_actor, sdk, _character_route)
		_status.visible = false
		return
	if _character_route == "use-item" and _character_actor != null:
		if _special_panel == null:
			clear_character_sheet()
			var panel := SPECIAL_SCENE.instantiate()
			_content.add_child(panel)
			_special_panel = panel
			_special_panel.navigate_requested.connect(_navigate)
			_special_panel.action_created.connect(_special_action_created)
			_special_panel.workflow_changed.connect(_power_chrome)
		_special_panel.configure(_character_actor, sdk, _item_id)
		_status.visible = false
		return
	if _character_route in ["powers", "cast"] and _character_actor != null:
		if _powers_panel == null:
			clear_character_sheet()
			var panel := POWERS_SCENE.instantiate()
			_content.add_child(panel)
			_powers_panel = panel
			_powers_panel.navigate_requested.connect(_navigate)
			_powers_panel.action_created.connect(_power_action_created)
			_powers_panel.workflow_changed.connect(_power_chrome)
		_powers_panel.configure(_character_actor, sdk, _item_id if _character_route == "cast" else "")
		_status.visible = false
		return
	if _character_route == "defence" and _defence != null:
		if _defence_view == null:
			clear_character_sheet()
			var view := DEFENCE_SCENE.instantiate()
			_content.add_child(view)
			_defence_view = view
		_defence_view.configure(_defence.snapshot, _defence.state, _defence.message)
		_status.visible = false
		_sync_chrome()
		return
	clear_character_sheet()
	if _character_actor == null:
		return
	if _character_route == "attack":
		_render_attack()
		return
	if _character_route == "companions":
		_show_companions()
		return
	var view = CHARACTER_SHEET_VIEW_SCENE.instantiate()
	view.modifier_requested.connect(_roll_ability)
	view.companions_requested.connect(_on_companions_requested)
	view.mutation_requested.connect(_mutate)
	view.navigate_requested.connect(_navigate)
	view.appearance_save_requested.connect(_on_appearance_save_requested)
	_content.add_child(view)
	var source_data: Dictionary = _character_actor.data
	var data: Dictionary = source_data.duplicate(true)
	_selected_rook = sdk.rooks.selected()
	if _selected_rook != null:
		var selected: SDK.RookResult = sdk.rooks.read(_selected_rook)
		if selected.ok and selected.rook.actor != null and selected.rook.actor.value == _character_actor.id.value:
			data["selected_rook_available"] = true
			data["selected_miniature"] = {"package_id": selected.rook.miniature.package_id, "local_id": selected.rook.miniature.local_id}
		else:
			_selected_rook = null
	data["pending_ability"] = _ability_throw.ability if _ability_throw != null and _ability_throw.pending else ""
	data["read_only"] = _character_actor.access_level != "Owner"
	data["inventory"] = ACTIONS.new(sdk, _character_actor.id).inventory(data)
	view.configure(data, _character_tab, _character_route, _character_miniatures, _character_miniature_choices, _short_window, _item_id)
	_character_view = view
	_status.visible = false
	if _ability_throw != null and not _ability_throw.pending:
		_set_status(_ability_throw.message, _ability_throw.failed)
	_sync_chrome()


func _navigate(route: String, item_id: String) -> void:
	if _busy:
		return
	if (_powers_panel != null or _special_panel != null or _health_panel != null) and (route != _character_route or item_id != _item_id):
		clear_character_sheet()
	if _character_actor.access_level != "Owner" and route in ["rest", "improve", "broken", "attack", "cast", "use-item", "edit", "item", "custom", "catalogue", "omens"]:
		_set_status("Owner access is required to change this Character.", true)
		return
	if route == "attack":
		if (_ability_throw != null and _ability_throw.pending) or (_melee != null and _melee.pending):
			_set_status("Finish the current Throw before starting another action.", true)
			return
		_selected_rook = sdk.rooks.selected()
		if _melee != null:
			_melee.retire()
		_melee = null
		_melee_options = {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}
	_character_route = route
	_item_id = item_id
	if route in ["character", "inventory", "appearance"]:
		_character_tab = route
	_render_pending = true

func _on_cancel_requested() -> void:
	_navigate("character", "")

func _mutate(operation: String, arguments: Array) -> void:
	if _busy or sdk == null:
		if _character_view != null and operation in ["correct", "item"]:
			_character_view.field_result(str(arguments[0] if operation == "correct" else arguments[1]), "Wait for the current save, then retry.", true)
		return
	var actions = ACTIONS.new(sdk, _character_actor.id)
	_set_busy(true, "Saving…")
	var result: SDK.ActorResult = await _perform(actions, operation, arguments)
	_set_busy(false, result.message if not result.ok else "Saved.", not result.ok)
	if _character_view != null and operation in ["correct", "item"]:
		_character_view.field_result(str(arguments[0] if operation == "correct" else arguments[1]), "Saved." if result.ok else result.message, not result.ok)
	if not result.ok:
		return
	_character_actor = result.actor
	sheet_changed.emit()
	_sync_chrome()
	if operation in ["add", "custom", "remove"]:
		_navigate("inventory", "")
	elif not _character_route in ["edit", "item"]:
		_render_pending = true


func _on_appearance_save_requested(scope: String, index: int) -> void:
	if index <= 0 or index - 1 >= _character_miniature_choices.size() or _busy or sdk == null:
		_set_status("Choose a published Miniature before saving.", true)
		return
	if scope == "Selected":
		var current_rook: SDK.RookId = sdk.rooks.selected()
		if _selected_rook == null or current_rook == null or current_rook.value != _selected_rook.value:
			_set_status("Select this Character’s Rook first.", true)
			return
		var selected: SDK.RookResult = sdk.rooks.read(_selected_rook)
		if not selected.ok or selected.rook.actor == null or selected.rook.actor.value != _character_actor.id.value:
			_set_status("The selected Rook is no longer linked to this Character.", true)
			return
		var selected_choice: Dictionary = _character_miniature_choices[index - 1]
		_set_busy(true, "Saving this Rook’s appearance…")
		var changed: SDK.RookResult = await sdk.rooks.set_miniature(_selected_rook, SDK.ContentReference.new(str(selected_choice.package_id), str(selected_choice.local_id)))
		_set_busy(false, "Appearance saved." if changed.ok else changed.message, not changed.ok)
		if changed.ok:
			_render_pending = true
		return
	var source: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Character data is unavailable.", true)
		return
	var choice: Dictionary = _character_miniature_choices[index - 1]
	var source_data: Dictionary = source.actor.data
	var data: Dictionary = source_data.duplicate(true)
	data["preferred_miniature"] = choice.duplicate(true)
	_set_busy(true, "Saving Character appearance…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "Appearance saved.", not result.ok)
	if result.ok:
		_character_actor = result.actor
		sheet_changed.emit()
		_character_tab = "appearance"
		_character_route = "character"
		_render_pending = true


func _set_status(message: String, error: bool = false) -> void:
	if _status == null:
		return
	_status.theme_type_variation = "RookframeError" if error else "RookframeMeta"
	_status.text = message
	_status.tooltip_text = message
	_status.visible = not message.is_empty()


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)
	_sync_chrome()


func set_available_height(height: float) -> void:
	var short_window := height < 500
	if short_window != _short_window:
		_short_window = short_window
		_render_pending = true


func _on_companions_requested() -> void:
	_character_route = "companions"
	_render_pending = true


func _show_companions() -> void:
	var result: SDK.ActorListResult = sdk.actors.list()
	if not result.ok:
		_set_status(result.message, true)
		return
	var companions: Array[SDK.Actor] = []
	var character_data: Dictionary = _character_actor.data
	var creation_request: String = character_data.get("creation_id", "")
	# Match the stable Package-owned creation request, preserved by World copies.
	# Raw Roll sequences are provenance only: local logs can restart in a copy.
	for actor in result.items:
		var data: Dictionary = actor.data
		var starting := not creation_request.is_empty() and str(data.get("creation_id", "")) == creation_request
		var summoned := str(data.get("summoner_actor", "")) == _character_actor.id.value
		if str(data.get("schema", "")) == "mork-borg-adversary/v1" and (starting or summoned):
			companions.append(actor)
	var view = COMPANIONS_SCENE.instantiate()
	view.back_requested.connect(_on_cancel_requested)
	view.actor_requested.connect(_on_companion_selected)
	view.placement_requested.connect(_on_companion_placement_requested)
	_content.add_child(view)
	view.configure(companions, character_data.get("companion_sheets", []))
	_sync_chrome()


func _on_companion_placement_requested(actor: SDK.Actor) -> void:
	companion_placement_requested.emit(actor)

func _on_companion_selected(actor: SDK.Actor) -> void:
	companion_selected.emit(actor)

func _perform(actions: ACTIONS, operation: String, arguments: Array) -> SDK.ActorResult:
	if operation == "correct":
		return await actions.correct(str(arguments[0]), str(arguments[1]))
	if operation == "omen":
		return await actions.spend_omen()
	if operation == "add":
		return await actions.add_equipment(str(arguments[0]))
	if operation == "custom":
		return await actions.add_custom(arguments[0])
	if operation == "item":
		return await actions.change_item(str(arguments[0]), str(arguments[1]), str(arguments[2]))
	if operation == "remove":
		return await actions.remove_item(str(arguments[0]))
	return SDK.ActorResult.new({"ok": false, "message": "Unknown Character action."})


func _world_changed() -> void:
	_refresh_pending = true
	_throw_refresh_pending = true
	_target_refresh_pending = true

func refresh_from_world() -> void:
	if _character_actor == null or sdk == null:
		return
	var latest: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not latest.ok or latest.actor == null:
		_character_actor = null
		clear_character_sheet()
		_set_status("Character data is no longer available.", true)
		actor_unavailable.emit()
		return
	var access_changed := latest.actor.access_level != _character_actor.access_level
	if not access_changed and latest.actor.data == _character_actor.data:
		if _character_tab == "appearance" or _character_route == "companions":
			_render_pending = true
		return
	_character_actor = latest.actor
	sheet_changed.emit()
	if access_changed:
		_character_route = "character"
		_render_pending = true
	elif (_character_route in ["edit", "item", "custom"] or (_character_route == "character" and _character_tab == "character")) and _character_view != null:
		var current: Dictionary = _character_actor.data
		var data: Dictionary = current.duplicate(true)
		data["inventory"] = ACTIONS.new(sdk, _character_actor.id).inventory(data)
		data["read_only"] = _character_actor.access_level != "Owner"
		data["pending_ability"] = _ability_throw.ability if _ability_throw != null and _ability_throw.pending else ""
		_character_view.refresh_data(data)
		_sync_chrome()
	else:
		_render_pending = true

func cancel_workflow() -> void:
	close_action()
	_navigate("character", "")

func spend_omen() -> void:
	_mutate("omen", [])

func _sync_chrome() -> void:
	if _character_route in ["rest", "improve", "broken"] and _health_panel != null:
		return
	if _character_route == "use-item" and _special_panel != null:
		return
	if _character_route in ["powers", "cast"] and _powers_panel != null:
		return
	if _character_actor == null:
		return
	var data: Dictionary = _character_actor.data
	var title := str(data.get("name", "Character"))
	if _character_route == "omens":
		title = "Spend an Omen"
	elif _character_route == "edit":
		title = "Edit Character"
	elif _character_route in ["catalogue", "custom"]:
		title = "Add Item"
	elif _character_route == "attack":
		title = str(_attack_item.get("name", "Weapon")) + " attack"
	elif _character_route == "item":
		title = "Inventory Item"
		var items: Array = data.get("inventory", [])
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("inventory_id", "")) == _item_id:
				title = str(item.get("name", "Inventory Item"))
	var count: int = data.get("omens", 0)
	var route: String = _character_tab if _character_route == "character" else _character_route
	var can_act := count > 0 and _character_actor.access_level == "Owner"
	if route == "defence" and _defence != null:
		workflow_changed.emit(route, "Roll damage" if _defence.snapshot.get("automatic_hit", false) else "Defend against attack", _defence.state == "ready", _defence.state == "pending" or _defence.is_submitting())
		return
	if route == "attack":
		can_act = _melee == null or _melee.state == "error"
	workflow_changed.emit(route, title, can_act, _busy or (_melee != null and _melee.pending))

func _roll_ability(ability: String) -> void:
	if _busy or sdk == null or (_ability_throw != null and _ability_throw.pending) or (_melee != null and _melee.pending):
		return
	_ability_throw = ABILITY_THROW.new(sdk, _character_actor.id)
	_ability_throw.changed.connect(_ability_changed)
	await _ability_throw.start(ability)

func _ability_changed() -> void:
	_render_pending = true

func close_action() -> void:
	if _health_panel != null:
		_health_panel.close_action()
	if _special_panel != null:
		_special_panel.close_action()
	if _powers_panel != null:
		_powers_panel.close_action()
	if _defence != null:
		_defence.cancel()
	if _shield != null:
		_shield.dismiss()
	if _shield_backdrop != null:
		_shield_backdrop.visible = false
	if _melee != null:
		_melee.cancel()
	if _ability_throw != null:
		_ability_throw.cancel()

func _exit_tree() -> void:
	close_action()

func _render_attack() -> void:
	var data: Dictionary = _character_actor.data
	data = data.duplicate(true)
	var items := ACTIONS.new(sdk, _character_actor.id).inventory(data)
	data["inventory"] = items
	_attack_item = {}
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == _item_id:
			_attack_item = item
	if _item_id == "class:bite" and str(data.get("class_id", "")) == "fanged-deserter":
		_attack_item = {"name": "Bite", "damage": "d6", "range_feet": 5, "attack_ability": "Strength", "natural": true}
	var view := MELEE_SCENE.instantiate()
	_content.add_child(view)
	_melee_view = view
	view.targets_requested.connect(_choose_attack_targets)
	view.configure(data, _attack_item, _melee_options, _melee.state if _melee != null else "ready", _melee.message if _melee != null else "")
	_status.visible = false
	_target_refresh_pending = true
	_sync_chrome()

func roll_attack() -> void:
	if _character_route in ["rest", "improve", "broken"] and _health_panel != null:
		await _health_panel.submit()
		return
	if _character_route == "use-item" and _special_panel != null:
		await _special_panel.submit()
		return
	if _character_route == "cast" and _powers_panel != null:
		await _powers_panel.submit()
		return
	if _character_route == "defence" and _defence != null and _defence_view != null:
		var options := _defence_view.options()
		if options.is_empty():
			_set_status("Enter whole numbers for difficulty and modifier.", true)
			return
		await _defence.roll(options)
		return
	if _busy or _melee_view == null or (_melee != null and _melee.pending):
		return
	var options := _melee_view.options()
	if options.is_empty():
		_set_status("Enter whole numbers for difficulty and modifier.", true)
		return
	if _selected_rook == null:
		_set_status("Select this Character’s source Rook before opening its attack.", true)
		return
	_melee_options = options
	var input := options.duplicate(true)
	input["source"] = _character_actor.id.value
	input["rook"] = _selected_rook.value
	input["item"] = _item_id
	if _melee != null:
		_melee.retire()
	var action := MELEE_ACTION.new(sdk)
	add_child(action)
	_melee = action
	_melee.changed.connect(_melee_changed)
	await _melee.start(input)

func _melee_changed() -> void:
	_render_pending = true
	_refresh_pending = true

func _targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_target_refresh_pending = true

func _choose_attack_targets() -> void:
	if _melee_view != null:
		var options := _melee_view.options()
		if not options.is_empty():
			_melee_options = options
	if _melee != null and _melee.state == "error":
		_melee.retire()
		_melee = null
		_melee_view.configure(_character_actor.data, _attack_item, _melee_options, "ready", "")
		_sync_chrome()
	var result: SDK.OperationResult = sdk.targeting.choose()
	if not result.ok:
		_set_status(result.message, true)

func _refresh_attack_targets() -> void:
	if _melee_view == null or sdk == null:
		return
	var view := _melee_view
	_target_reading = true
	var reach: float = _attack_item.get("range_feet", 0)
	var summary: String = await TARGETS.new().describe(sdk, _selected_rook, reach)
	_target_reading = false
	if _melee_view == view:
		view.set_targets(summary)

func offer_defence(outcome: Dictionary) -> void:
	if _defence != null and str(_defence.snapshot.get("id", "")) == str(outcome.id):
		return
	close_action()
	if _defence != null:
		_defence.retire()
	var action := DEFENCE_ACTION.new(sdk)
	add_child(action)
	_defence = action
	_defence.changed.connect(_defence_changed.bind(action))
	_defence.adopt(outcome)

func _defence_changed(action: DEFENCE_ACTION) -> void:
	if action == _defence:
		_defence_update_pending = true

func _present_defence_update() -> void:
	if _defence == null:
		return
	_character_route = "character" if _defence.state in ["shield", "resolved"] else "defence"
	_character_tab = "character"
	_render_pending = true
	_refresh_pending = true
	if _defence.state == "shield":
		if _shield_backdrop == null:
			var backdrop := SHIELD_BACKDROP.instantiate()
			add_child(backdrop)
			_shield_backdrop = backdrop
		_shield_backdrop.visible = true
		if _shield == null:
			var dialog := SHIELD_SCENE.instantiate()
			add_child(dialog)
			_shield = dialog
			_shield.choice_requested.connect(_choose_shield)
			_shield.cancelled.connect(_cancel_defence)
		_shield.present(_defence.snapshot)
		_shield.set_pending(_defence.is_submitting())
	elif _shield != null:
		var was_open: bool = _shield_backdrop.visible
		_shield.dismiss()
		_shield_backdrop.visible = false
		if was_open:
			shield_decision_closed.emit()

func _choose_shield(choice: String) -> void:
	await _defence.choose(choice)

func _cancel_defence() -> void:
	await _defence.cancel()

func _power_chrome(route: String, title: String, can_submit: bool, busy: bool) -> void:
	workflow_changed.emit(route, title, can_submit, busy)

func power_primary_text() -> String:
	return _powers_panel.primary_text() if _powers_panel != null else "Roll casting test"

func _power_action_created(action: MELEE_ACTION) -> void:
	_powers_action = action
	add_child(action)

func special_primary_text() -> String:
	return _special_panel.primary_text() if _special_panel != null else "Use item"

func _special_action_created(action: MELEE_ACTION) -> void:
	_special_action = action
	add_child(action)

func health_primary_text() -> String:
	return _health_panel.primary_text() if _health_panel != null else "Roll recovery"

func _health_action_created(action: MELEE_ACTION) -> void:
	_health_action = action
	add_child(action)
