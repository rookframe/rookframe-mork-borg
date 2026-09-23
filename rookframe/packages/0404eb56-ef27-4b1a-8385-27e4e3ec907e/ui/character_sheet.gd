extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const COMPANIONS_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_companions.tscn")
const CHARACTER_SHEET_VIEW_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_view.tscn")

signal companion_selected(actor: SDK.Actor)
signal sheet_changed
signal workflow_changed(route: String, title: String, can_spend: bool, busy: bool)
signal actor_unavailable
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
	_character_actor = actor
	_character_tab = tab
	_character_route = route
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	sdk = facade
	if not sdk.world_changed.is_connected(_world_changed):
		sdk.world_changed.connect(_world_changed)
	_render_pending = true


func _process(_delta: float) -> void:
	if not visible:
		return
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
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_character_view = null
	_status = get_node(^"Status") as Label


func _render_character_sheet() -> void:
	clear_character_sheet()
	if _character_actor == null:
		return
	if _character_route == "companions":
		_show_companions()
		return
	var view = CHARACTER_SHEET_VIEW_SCENE.instantiate()
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
	data["read_only"] = _character_actor.access_level != "Owner"
	data["inventory"] = ACTIONS.new(sdk, _character_actor.id).inventory(data)
	view.configure(data, _character_tab, _character_route, _character_miniatures, _character_miniature_choices, _short_window, _item_id)
	_character_view = view
	_status.visible = false
	_sync_chrome()


func _navigate(route: String, item_id: String) -> void:
	if _busy:
		return
	if _character_actor.access_level != "Owner" and route in ["attack", "edit", "item", "custom", "catalogue", "omens"]:
		_set_status("Owner access is required to change this Character.", true)
		return
	if route == "attack":
		_set_status("Weapon attacks will be available with the combat actions.", true)
		return
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
		if not creation_request.is_empty() and str(data.get("schema", "")) == "mork-borg-adversary/v1" and str(data.get("creation_id", "")) == creation_request:
			companions.append(actor)
	var view = COMPANIONS_SCENE.instantiate()
	view.back_requested.connect(_on_cancel_requested)
	view.actor_requested.connect(_on_companion_selected)
	_content.add_child(view)
	view.configure(companions, character_data.get("companion_sheets", []))


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
		if _character_tab == "appearance":
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
		_character_view.refresh_data(data)
		_sync_chrome()
	else:
		_render_pending = true

func cancel_workflow() -> void:
	_navigate("character", "")

func spend_omen() -> void:
	_mutate("omen", [])

func _sync_chrome() -> void:
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
	elif _character_route == "item":
		title = "Inventory Item"
	var count: int = data.get("omens", 0)
	var route: String = _character_tab if _character_route == "character" else _character_route
	workflow_changed.emit(route, title, count > 0 and _character_actor.access_level == "Owner", _busy)
