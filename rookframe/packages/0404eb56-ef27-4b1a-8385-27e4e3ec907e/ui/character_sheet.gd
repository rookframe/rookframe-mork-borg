extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const CHARACTER_SHEET_VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_view.gd")

signal sheet_changed

var sdk: SDK
var _character_actor: SDK.Actor
var _character_miniatures: Array[SDK.ContentEntry] = []
var _character_miniature_choices: Array[Dictionary] = []
var _character_tab := "character"
var _character_route := "character"
var _character_view: Variant
var _status: Label
var _busy := false
var _render_pending := false


func set_character(actor: SDK.Actor, tab: String, route: String, miniatures: Array[SDK.ContentEntry], miniature_choices: Array[Dictionary], facade: SDK) -> void:
	_character_actor = actor
	_character_tab = tab
	_character_route = route
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	sdk = facade
	_render_character_sheet()


func _process(_delta: float) -> void:
	if _render_pending:
		_render_pending = false
		_render_character_sheet()


func clear_character_sheet() -> void:
	for child in get_children():
		child.queue_free()
	_character_view = null
	_status = null


func _render_character_sheet() -> void:
	clear_character_sheet()
	if _character_actor == null:
		return
	var view = CHARACTER_SHEET_VIEW.new()
	view.configure(_character_actor.data, _character_tab, _character_route, _character_miniatures)
	view.edit_requested.connect(_on_edit_requested)
	view.add_item_requested.connect(_on_add_item_requested)
	view.item_save_requested.connect(_on_item_save_requested)
	view.sheet_save_requested.connect(_on_sheet_save_requested)
	view.cancel_requested.connect(_on_cancel_requested)
	view.appearance_save_requested.connect(_on_appearance_save_requested)
	add_child(view)
	_character_view = view
	var status := Label.new()
	status.theme_type_variation = "RookframeMeta"
	status.visible = false
	add_child(status)
	_status = status


func _on_edit_requested() -> void:
	_character_route = "edit"
	_render_pending = true


func _on_cancel_requested() -> void:
	_character_route = "character"
	_render_pending = true


func _on_add_item_requested() -> void:
	_character_route = "item"
	_render_pending = true


func _on_item_save_requested(item_name: String) -> void:
	if item_name.is_empty() or _busy or sdk == null:
		_set_status("Enter an item name before saving.", true)
		return
	var source: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Character data is unavailable.", true)
		return
	var data: Dictionary = source.actor.data.duplicate(true)
	var inventory: Array = data.get("inventory", []).duplicate(true)
	inventory.append({"name": item_name})
	data["inventory"] = inventory
	_set_busy(true, "Saving Character inventory…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "Inventory saved.", not result.ok)
	if result.ok:
		_character_actor = result.actor
		_character_tab = "inventory"
		_character_route = "character"
		_render_pending = true


func _on_sheet_save_requested(private_name: String, description: String, hit_points: int, silver: int, omens: int) -> void:
	if private_name.is_empty() or _busy or sdk == null:
		_set_status("Enter a Character name before saving.", true)
		return
	var source: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Character data is unavailable.", true)
		return
	var data: Dictionary = source.actor.data.duplicate(true)
	data["name"] = private_name
	data["description"] = description
	data["hit_points"] = hit_points
	var maximum_hit_points: int = data.get("maximum_hit_points", 1)
	if maximum_hit_points < hit_points:
		maximum_hit_points = hit_points
	data["maximum_hit_points"] = maximum_hit_points
	data["silver"] = silver
	data["omens"] = omens
	_set_busy(true, "Saving Character sheet…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "Character changes saved.", not result.ok)
	if result.ok:
		_character_actor = result.actor
		_character_route = "character"
		_render_pending = true


func _on_appearance_save_requested(index: int) -> void:
	if index <= 0 or index - 1 >= _character_miniature_choices.size() or _busy or sdk == null:
		_set_status("Choose a published Miniature before saving.", true)
		return
	var source: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Character data is unavailable.", true)
		return
	var choice: Dictionary = _character_miniature_choices[index - 1]
	var data: Dictionary = source.actor.data.duplicate(true)
	data["preferred_miniature"] = choice.duplicate(true)
	_set_busy(true, "Saving Character appearance…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "Appearance saved.", not result.ok)
	if result.ok:
		_character_actor = result.actor
		_character_tab = "appearance"
		_character_route = "character"
		_render_pending = true


func _set_status(message: String, error: bool = false) -> void:
	if _status == null:
		return
	_status.text = message
	_status.tooltip_text = message
	_status.visible = error or _busy


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)
