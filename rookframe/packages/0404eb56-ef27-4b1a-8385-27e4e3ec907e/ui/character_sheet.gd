extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const COMPANIONS_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_companions.tscn")
const CHARACTER_SHEET_VIEW_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_view.tscn")

signal companion_selected(actor: SDK.Actor)
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
var _short_window := false
@onready var _content := get_node(^"Content") as VBoxContainer


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
	view.edit_requested.connect(_on_edit_requested)
	view.value_save_requested.connect(_on_value_save_requested)
	view.add_item_requested.connect(_on_add_item_requested)
	view.item_save_requested.connect(_on_item_save_requested)
	view.sheet_save_requested.connect(_on_sheet_save_requested)
	view.cancel_requested.connect(_on_cancel_requested)
	view.appearance_save_requested.connect(_on_appearance_save_requested)
	_content.add_child(view)
	view.configure(_character_actor.data, _character_tab, _character_route, _character_miniatures, _character_miniature_choices, _short_window)
	_character_view = view
	_status.visible = false


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
		sheet_changed.emit()
		_character_tab = "inventory"
		_character_route = "character"
		_render_pending = true


func _on_sheet_save_requested(private_name: String, description: String, hit_points: int, maximum_hit_points: int, silver: int, omens: int, abilities: Dictionary, inventory: Array) -> void:
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
	data["maximum_hit_points"] = maximum_hit_points
	data["silver"] = silver
	data["omens"] = omens
	data["inventory"] = inventory.duplicate(true)
	var normalized_abilities: Dictionary = {}
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var submitted: Dictionary = abilities.get(ability_name, {})
		var score: int = submitted.get("score", 1)
		if score < 1:
			score = 1
		elif score > 20:
			score = 20
		normalized_abilities[ability_name] = {"score": score, "modifier": _modifier(score)}
	data["abilities"] = normalized_abilities
	_set_busy(true, "Saving Character sheet…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "Character changes saved.", not result.ok)
	if result.ok:
		_character_actor = result.actor
		sheet_changed.emit()
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
	data["preferred_miniature"]["choice_index"] = index
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
	_status.text = message
	_status.tooltip_text = message
	_status.visible = error or _busy


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)


func _modifier(score: int) -> int:
	if score <= 4:
		return -3
	if score <= 6:
		return -2
	if score <= 8:
		return -1
	if score <= 12:
		return 0
	if score <= 14:
		return 1
	if score <= 16:
		return 2
	return 3


func _on_value_save_requested(key: String, value: int) -> void:
	if _busy or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_character_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Character data is unavailable.", true)
		return
	var data: Dictionary = source.actor.data.duplicate(true)
	if ["hit_points", "omens", "silver"].has(key):
		data[key] = value
	elif ["Agility", "Presence", "Strength", "Toughness"].has(key):
		var abilities: Dictionary = data.get("abilities", {}).duplicate(true)
		abilities[key] = {"score": value, "modifier": _modifier(value)}
		data["abilities"] = abilities
	else:
		return
	_set_busy(true, "Saving…")
	var result: SDK.ActorResult = await sdk.actors.update(_character_actor.id, data)
	_set_busy(false, result.message if not result.ok else "", not result.ok)
	if result.ok:
		_character_actor = result.actor
		sheet_changed.emit()
		_render_pending = true


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
	_character_view = view


func _on_companion_selected(actor: SDK.Actor) -> void:
	companion_selected.emit(actor)
