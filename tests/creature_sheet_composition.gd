extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/miniature_boundary.gd")

func _settle() -> void:
	for frame in range(8):
		await get_tree().process_frame

func test_creature_tabs_editing_and_viewer_at_phone_width() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.actors.enemy.access_level = "Owner"
	host.actors.enemy.data = preload(ROOT + "content/zukuma-berserker.tres").create_data({})
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 313)
	add_child(viewport)
	var sheet = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	sheet.sdk = SDK.new(host)
	viewport.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.opened(SDK.ActorId.new("enemy"))
	await _settle()
	var tabs: Control = sheet.get_node("Layout/Header/Routes")
	var detail: Control = sheet.get_node("Layout/Body/Content/Detail")
	assert_int(tabs.get_child_count()).is_equal(3)
	assert_bool(detail.get_node("Miniature").is_visible_in_tree()).is_false()
	assert_bool(sheet.get_node("Layout/CreatureEditActions").is_visible_in_tree()).is_false()
	for name in ["Duplicate", "PlaceRook"]:
		assert_bool(sheet.find_child(name, true, false) == null).is_true()
	assert_bool(detail.find_child("CreatureInventory", true, false) == null).is_true()
	var gear: Button = detail.get_node("Identity/EditCreature")
	assert_str(gear.text).is_empty()
	assert_bool(gear.icon != null and gear.size.x == 44 and gear.size.y == 44).is_true()
	assert_bool(sheet.get_global_rect().encloses(gear.get_global_rect())).is_true()
	gear.pressed.emit()
	await _settle()
	assert_bool(detail.get_node("EditFields").is_visible_in_tree()).is_true()
	var footer: Control = sheet.get_node("Layout/CreatureEditActions")
	assert_bool(footer.is_visible_in_tree()).is_true()
	assert_bool(sheet.get_global_rect().encloses(footer.get_global_rect())).is_true()
	footer.get_node("LeadingSlot/Back").pressed.emit()
	await _settle()
	tabs.get_node("Appearance").pressed.emit()
	await _settle()
	assert_bool(detail.get_node("Miniature").is_visible_in_tree()).is_true()
	assert_bool(detail.get_node("Stats").is_visible_in_tree()).is_false()
	assert_bool(detail.get_node("SheetGrid").is_visible_in_tree()).is_false()
	tabs.get_node("CreatureInventory").pressed.emit()
	await _settle()
	assert_bool(detail.get_node("Miniature").is_visible_in_tree()).is_false()
	assert_bool(detail.get_node("Inventory").is_visible_in_tree()).is_true()
	host.actors.enemy.access_level = "Viewer"
	host.WorldChanged.emit()
	await _settle()
	var inventory: Control = detail.get_node("Inventory").get_child(0)
	assert_bool(inventory.get_node("Toolbar/Add").disabled).is_true()
	tabs.get_node("Creature").pressed.emit()
	await _settle()
	assert_bool(gear.is_visible_in_tree()).is_false()

func test_inventory_names_keep_space_and_icons_keep_accessible_actions() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(351, 313)
	add_child(viewport)
	var inventory = auto_free(load(ROOT + "ui/character_sheet_inventory.tscn").instantiate())
	inventory.theme = load("res://rookframe/ui/theme/rookframe_theme.tres")
	viewport.add_child(inventory)
	inventory.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	inventory.configure({"schema": "mork-borg-adversary/v1", "inventory": [
		{"inventory_id": "1", "name": "Long flail", "kind": "Weapon", "equipped": true, "damage": "d8", "range_feet": 10},
		{"inventory_id": "2", "name": "Heavy mace", "kind": "Weapon", "equipped": true, "damage": "d10", "range_feet": 5},
		{"inventory_id": "3", "name": "An unusually long item name that must remain readable", "kind": "Weapon", "equipped": false, "damage": "d6"}
	]}, [])
	await _settle()
	assert_str(inventory.get_node("Toolbar/Add").text).is_empty()
	var rows: Node = inventory.get_node("EquippedSection/Content/Items")
	var row: Control = rows.get_child(0)
	assert_bool(row.get_node("Copy").size.x >= 130).is_true()
	assert_bool(row.get_node("Copy/Title").size.y <= 25).is_true()
	for name in ["Attack", "Equip", "Edit"]:
		var button: Button = row.get_node("Actions/" + name)
		assert_str(button.text).is_empty()
		assert_bool(button.icon != null).is_true()
		assert_str(button.accessibility_name).contains("Long flail")
		assert_bool(button.size.x == 44 and button.size.y == 44).is_true()
		assert_bool(inventory.get_global_rect().encloses(button.get_global_rect())).is_true()
	assert_bool(row.get_node("Actions/Equip").button_pressed).is_true()
	var edits: Array = []
	row.navigate_requested.connect(func(route, id): edits.append([route, id]))
	row.get_node("Actions/Edit").pressed.emit()
	assert_array(edits).is_equal([["item", "1"]])
	var mutations: Array = []
	row.mutation_requested.connect(func(operation, arguments): mutations.append([operation, arguments]))
	row.get_node("Actions/Equip").pressed.emit()
	assert_array(mutations).is_equal([["item", ["1", "equipped", "false"]]])
	assert_bool(rows.get_child(2).position.y - row.position.y >= 76).is_true()
