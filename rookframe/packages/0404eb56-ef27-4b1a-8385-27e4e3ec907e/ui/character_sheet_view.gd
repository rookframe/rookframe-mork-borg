extends VBoxContainer

const OVERVIEW_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_overview.tscn")
const INVENTORY_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_inventory.tscn")
const ITEM_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.tscn")
const EDIT_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_edit.tscn")
const APPEARANCE_SCENE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_appearance.tscn")
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

signal edit_requested
signal value_save_requested(key: String, value: int)
signal add_item_requested
signal item_save_requested(item_name: String)
signal sheet_save_requested(private_name: String, description: String, hit_points: int, maximum_hit_points: int, silver: int, omens: int, abilities: Dictionary, inventory: Array)
signal cancel_requested
signal appearance_save_requested(index: int)


func configure(data: Dictionary, tab: String, route: String, miniatures: Array[SDK.ContentEntry], miniature_choices: Array[Dictionary], short_window: bool = false) -> void:
	var content := get_node(^"Content") as VBoxContainer
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if route == "edit":
		var edit_view = EDIT_SCENE.instantiate()
		edit_view.sheet_save_requested.connect(_emit_sheet_save_requested)
		edit_view.cancel_requested.connect(_emit_cancel_requested)
		content.add_child(edit_view)
		edit_view.configure(data, miniatures)
		return
	if route == "item":
		var item_view = ITEM_SCENE.instantiate()
		item_view.item_save_requested.connect(_emit_item_save_requested)
		item_view.cancel_requested.connect(_emit_cancel_requested)
		content.add_child(item_view)
		item_view.configure(data, miniatures)
		return
	if route == "appearance" or tab == "appearance":
		var appearance_view = APPEARANCE_SCENE.instantiate()
		appearance_view.appearance_save_requested.connect(_emit_appearance_save_requested)
		content.add_child(appearance_view)
		appearance_view.configure(data, miniature_choices.size(), miniature_choices)
		return
	if tab == "inventory":
		var inventory_view = INVENTORY_SCENE.instantiate()
		inventory_view.add_item_requested.connect(_emit_add_item_requested)
		content.add_child(inventory_view)
		inventory_view.configure(data, miniatures)
		return
	var overview_view = OVERVIEW_SCENE.instantiate()
	overview_view.edit_requested.connect(_emit_edit_requested)
	overview_view.value_save_requested.connect(_emit_value_save_requested)
	content.add_child(overview_view)
	overview_view.configure(data, miniatures, short_window)


func _emit_edit_requested() -> void:
	edit_requested.emit()


func _emit_add_item_requested() -> void:
	add_item_requested.emit()


func _emit_item_save_requested(item_name: String) -> void:
	item_save_requested.emit(item_name)


func _emit_sheet_save_requested(private_name: String, description: String, hit_points: int, maximum_hit_points: int, silver: int, omens: int, abilities: Dictionary, inventory: Array) -> void:
	sheet_save_requested.emit(private_name, description, hit_points, maximum_hit_points, silver, omens, abilities, inventory)


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _emit_appearance_save_requested(index: int) -> void:
	appearance_save_requested.emit(index)


func _emit_value_save_requested(key: String, value: int) -> void:
	value_save_requested.emit(key, value)
