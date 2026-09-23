extends VBoxContainer

const OVERVIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_overview.gd")
const INVENTORY = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_inventory.gd")
const ITEM = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_item.gd")
const EDIT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_edit.gd")
const APPEARANCE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_sheet_appearance.gd")
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

signal edit_requested
signal add_item_requested
signal item_save_requested(item_name: String)
signal sheet_save_requested(private_name: String, description: String, hit_points: int, silver: int, omens: int)
signal cancel_requested
signal appearance_save_requested(index: int)


func configure(data: Dictionary, tab: String, route: String, miniatures: Array[SDK.ContentEntry]) -> void:
	for child in get_children():
		child.queue_free()
	if route == "edit":
		var edit_view = EDIT.new()
		edit_view.configure(data, miniatures)
		edit_view.sheet_save_requested.connect(_emit_sheet_save_requested)
		edit_view.cancel_requested.connect(_emit_cancel_requested)
		add_child(edit_view)
		return
	if route == "item":
		var item_view = ITEM.new()
		item_view.configure(data, miniatures)
		item_view.item_save_requested.connect(_emit_item_save_requested)
		item_view.cancel_requested.connect(_emit_cancel_requested)
		add_child(item_view)
		return
	if route == "appearance" or tab == "appearance":
		var appearance_view = APPEARANCE.new()
		appearance_view.configure(data, miniatures.size())
		appearance_view.appearance_save_requested.connect(_emit_appearance_save_requested)
		appearance_view.cancel_requested.connect(_emit_cancel_requested)
		add_child(appearance_view)
		return
	if tab == "inventory":
		var inventory_view = INVENTORY.new()
		inventory_view.configure(data, miniatures)
		inventory_view.add_item_requested.connect(_emit_add_item_requested)
		add_child(inventory_view)
		return
	var overview_view = OVERVIEW.new()
	overview_view.configure(data, miniatures)
	overview_view.edit_requested.connect(_emit_edit_requested)
	add_child(overview_view)


func _emit_edit_requested() -> void:
	edit_requested.emit()


func _emit_add_item_requested() -> void:
	add_item_requested.emit()


func _emit_item_save_requested(item_name: String) -> void:
	item_save_requested.emit(item_name)


func _emit_sheet_save_requested(private_name: String, description: String, hit_points: int, silver: int, omens: int) -> void:
	sheet_save_requested.emit(private_name, description, hit_points, silver, omens)


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _emit_appearance_save_requested(index: int) -> void:
	appearance_save_requested.emit(index)
