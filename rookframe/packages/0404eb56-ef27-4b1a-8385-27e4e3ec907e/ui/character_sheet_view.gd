extends VBoxContainer

const OVERVIEW_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_overview.tscn")
const INVENTORY_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_inventory.tscn")
const ITEM_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.tscn")
const EDIT_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_edit.tscn")
const APPEARANCE_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_appearance.tscn")
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

const OVERVIEW_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_overview.gd")
var _overview: OVERVIEW_SCRIPT
var _short_window := false
const ITEM_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.gd")
const EDIT_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_edit.gd")
var _item_editor: ITEM_SCRIPT
var _character_editor: EDIT_SCRIPT

signal modifier_requested(ability: String)
signal companions_requested
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
signal appearance_save_requested(scope: String, index: int)
const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/equipment_catalogue.tscn")
const OMENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_omens.tscn")
func configure(data: Dictionary, tab: String, route: String, miniatures: Array[SDK.ContentEntry], miniature_choices: Array[Dictionary], short_window: bool = false, item_id: String = "") -> void:
	_short_window = short_window
	if route in ["item", "custom"]:
		var item_view = ITEM_SCENE.instantiate()
		_item_editor = item_view
		_connect_form(item_view)
		var item: Dictionary = {}
		var inventory: Array = data.get("inventory", [])
		for raw in inventory:
			var entry: Dictionary = raw
			if str(entry.get("inventory_id", "")) == item_id:
				item = entry
		if route == "item" and item.is_empty():
			item_view.show_missing()
		else:
			item_view.configure(item, miniatures)
		return
	if route == "edit":
		var edit = EDIT_SCENE.instantiate()
		_character_editor = edit
		_connect_form(edit)
		edit.configure(data, miniatures)
		return
	if route == "catalogue":
		var catalogue = CATALOGUE.instantiate()
		_connect_form(catalogue)
		catalogue.configure(data, miniatures)
		return
	if route == "omens":
		var omens = OMENS.instantiate()
		_connect_form(omens)
		omens.configure(data, miniatures)
		return
	if route == "appearance" or tab == "appearance":
		var appearance = APPEARANCE_SCENE.instantiate()
		appearance.appearance_save_requested.connect(_appearance)
		get_node(^"Content").add_child(appearance)
		appearance.configure(data, miniature_choices.size(), miniature_choices)
		return
	if route == "inventory" or tab == "inventory":
		var inventory_view = INVENTORY_SCENE.instantiate()
		_connect_form(inventory_view)
		inventory_view.configure(data, miniatures)
		return
	var overview = OVERVIEW_SCENE.instantiate()
	_overview = overview
	overview.modifier_requested.connect(_roll)
	overview.companions_requested.connect(_companions)
	overview.edit_requested.connect(_edit)
	overview.omens_requested.connect(_omens)
	overview.value_save_requested.connect(_correct)
	get_node(^"Content").add_child(overview)
	overview.configure(data, miniatures, short_window)

func _connect_form(view: Control) -> void:
	view.mutation_requested.connect(_mutation)
	view.navigate_requested.connect(_navigate)
	get_node(^"Content").add_child(view)

func _appearance(scope: String, index: int) -> void:
	appearance_save_requested.emit(scope, index)

func _companions() -> void:
	companions_requested.emit()

func _edit() -> void:
	navigate_requested.emit("edit", "")

func _omens() -> void:
	navigate_requested.emit("omens", "")

func _correct(key: String, value: String) -> void:
	mutation_requested.emit("correct", [key, str(value)])

func _mutation(operation: String, arguments: Array) -> void:
	mutation_requested.emit(operation, arguments)

func _navigate(next_route: String, id: String) -> void:
	navigate_requested.emit(next_route, id)

func field_result(key: String, message: String, error: bool) -> void:
	if _overview != null:
		_overview.field_result(key, message, error)
	if _item_editor != null:
		_item_editor.field_result(key, message, error)
	if _character_editor != null:
		_character_editor.field_result(key, message, error)

func refresh_data(data: Dictionary) -> void:
	if _overview != null:
		_overview.configure(data, [], _short_window)
	if _item_editor != null:
		_item_editor.refresh_data(data)
	if _character_editor != null:
		_character_editor.refresh_data(data)

func _roll(ability: String) -> void:
	modifier_requested.emit(ability)
