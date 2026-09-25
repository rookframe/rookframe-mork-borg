extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/character_actions.gd")
const BOUNDARY = preload("res://tests/creation_sdk_boundary.gd")

func test_character_inventory() -> void:
	var host = BOUNDARY.new()
	host.actors.append({"id": "character", "access_level": "Owner", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "omens": 2, "hit_points": 7, "maximum_hit_points": 9, "abilities": {"Strength": {"score": 8, "modifier": -1}}, "inventory": []}})
	var sdk = SDK.new(host)
	var actions = ACTIONS.new(sdk, SDK.ActorId.new("character"))
	var result: SDK.ActorResult = await actions.correct("Strength", "5")
	assert_bool(result.ok and result.actor.data.abilities.Strength.modifier == 5).override_failure_message("Completed corrections edit the played modifier, including improvement values.").is_true()
	assert_bool(result.actor.data.abilities.Strength.score == 8).override_failure_message("Corrections preserve creation provenance.").is_true()
	result = await actions.correct("hit_points", "-2")
	assert_bool(result.ok and result.actor.data.hit_points == -2).override_failure_message("Manual HP corrections retain below-zero results.").is_true()
	var before: Dictionary = sdk.actors.read(SDK.ActorId.new("character")).actor.data.duplicate(true)
	result = await actions.spend_omen()
	before.omens = 1
	assert_bool(result.ok and result.actor.data == before).override_failure_message("Spending one Omen changes only the current count.").is_true()
	await actions.spend_omen()
	result = await actions.spend_omen()
	assert_bool(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data.omens == 0).override_failure_message("No Omen can be spent below zero.").is_true()
	assert_bool(host.requests.is_empty()).override_failure_message("Corrections and Omen spending request no dice.").is_true()
	result = await actions.add_equipment("sword")
	assert_bool(result.ok).override_failure_message("Core catalogue adds a live sword.").is_true()
	var sword: Dictionary = result.actor.data.inventory[0]
	assert_bool(sword.name == "Sword" and sword.damage == "d6" and not sword.equipped).override_failure_message("Catalogue supplies printed damage and starts carried.").is_true()
	var item_id: String = sword.inventory_id
	result = await actions.change_item(item_id, "equipped", "true")
	assert_bool(result.ok and result.actor.data.inventory[0].equipped).override_failure_message("Equip persists on the selected live entry.").is_true()
	result = await actions.change_item(item_id, "quantity", "3")
	assert_bool(result.ok and result.actor.data.inventory[0].quantity == 3).override_failure_message("Quantity correction changes the live entry.").is_true()
	result = await actions.change_item(item_id, "damage", "d8")
	assert_bool(not result.ok).override_failure_message("Bundled mechanical definitions cannot be rewritten through a live edit.").is_true()
	result = await actions.add_custom({"name": "Bent blade", "kind": "Weapon", "damage": "d4", "range_feet": 5, "quantity": 1, "uses": 2})
	assert_bool(result.ok and result.actor.data.inventory.size() == 2).override_failure_message("Custom supported fields become a separate live item.").is_true()
	var custom_id: String = result.actor.data.inventory[1].inventory_id
	result = await actions.change_item(custom_id, "damage", "d6")
	assert_bool(result.ok and result.actor.data.inventory[1].damage == "d6").override_failure_message("Custom item damage can be corrected without changing the catalogue.").is_true()
	result = await actions.change_item(custom_id, "uses", "0")
	assert_bool(result.ok and result.actor.data.inventory[1].uses == 0).override_failure_message("Depleted uses are retained, without automatic replenishment.").is_true()
	await actions.remove_item(item_id)
	result = await actions.change_item(item_id, "quantity", "9")
	assert_bool(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data.inventory[0].name == "Bent blade").override_failure_message("A stale item editor never changes the entry shifted into its old position.").is_true()
	result = await actions.add_equipment("sword")
	assert_bool(result.ok and result.actor.data.inventory[1].damage == "d6" and result.actor.data.inventory[1].quantity == 1).override_failure_message("New catalogue instances retain immutable defaults.").is_true()
	result = await actions.add_equipment("femur")
	assert_bool(result.ok and result.actor.data.inventory[2].damage == "d4").override_failure_message("Core catalogue includes the printed Femur weapon.").is_true()
	await actions.correct("omens", "2")
	before = sdk.actors.read(SDK.ActorId.new("character")).actor.data.duplicate(true)
	host.actors[0].access_level = "Viewer"
	result = await actions.spend_omen()
	assert_bool(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data == before).override_failure_message("Viewer cannot perform sheet mutations even with Omens available.").is_true()
	host.actors[0].access_level = "Owner"
	await _check_pending_fields(host)
	await _check_appearance(host)
	await _check_live_refresh(host)


func _check_pending_fields(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "edit", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	var fields: Dictionary = {}
	for field in sheet.find_children("*", "VBoxContainer", true, false):
		if field.get_script() == load(ROOT + "ui/sheet_field.gd"):
			fields[field.field] = field
	host.defer_update = true
	fields.name.get_node(^"Field").value = "Pending name"
	fields.name.get_node(^"Actions/Save").pressed.emit()
	assert_bool(fields.name.get_node(^"Actions/Save").disabled).override_failure_message("Pending field visibly disables duplicate saves.").is_true()
	fields.maximum_hit_points.get_node(^"Field").value = "17"
	fields.maximum_hit_points.get_node(^"Actions/Save").pressed.emit()
	assert_bool(not fields.maximum_hit_points.get_node(^"Actions/Save").disabled).override_failure_message("Another field rejected while busy can retry.").is_true()
	assert_bool(not fields.maximum_hit_points.get_node(^"Field").error_text.is_empty()).override_failure_message("Busy rejection is field-local.").is_true()
	host.complete_update()
	await get_tree().process_frame
	assert_bool(host.actors[0].data.name == "Pending name").override_failure_message("Pending save commits the submitted field.").is_true()
	assert_bool(fields.maximum_hit_points.get_node(^"Field").value == "17").override_failure_message("Saving one field preserves another field’s unsaved text.").is_true()
	fields.name.get_node(^"Field").value = "Discard me"
	fields.name.get_node(^"Actions/Cancel").pressed.emit()
	assert_bool(fields.name.get_node(^"Field").value == "Pending name").override_failure_message("Cancel restores the most recently saved value.").is_true()
	fields.maximum_hit_points.get_node(^"Actions/Save").pressed.emit()
	await get_tree().process_frame
	assert_bool(host.actors[0].data.maximum_hit_points == 17).override_failure_message("Rejected pending field can be retried successfully.").is_true()
	sheet.queue_free()
	await get_tree().process_frame

func _check_appearance(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	host.rooks["one"] = {"id": "one", "actor": "character", "scene": "scene", "position": Vector2.ZERO, "yaw": 0.0, "miniature": {"packageId": "published", "localId": "a"}}
	host.rooks["two"] = host.rooks.one.duplicate(true)
	host.rooks.two.id = "two"
	host.selected_rook = ""
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = [{"package_id": "published", "local_id": "a", "title": "A"}, {"package_id": "published", "local_id": "b", "title": "B"}]
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "appearance", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	var appearance = sheet.find_child("CharacterAppearance", true, false)
	assert_bool(appearance.get_node(^"Selected/Content/Row/Details/Choose").disabled).override_failure_message("Appearance without a selection disables only the Rook choice.").is_true()
	host.selected_rook = "one"
	await get_tree().process_frame
	await get_tree().process_frame
	appearance = sheet.find_child("CharacterAppearance", true, false)
	assert_bool(not appearance.get_node(^"Selected/Content/Row/Details/Choose").disabled).override_failure_message("An open Appearance sheet follows a new local Rook selection.").is_true()
	sheet._on_appearance_save_requested("Default", 2)
	await get_tree().process_frame
	assert_bool(host.actors[0].data.preferred_miniature.local_id == "b" and host.appearance_changes == 0).override_failure_message("Actor default changes no existing Rook.").is_true()
	sheet._on_appearance_save_requested("Selected", 2)
	await get_tree().process_frame
	assert_bool(host.rooks.one.miniature.localId == "b" and host.rooks.two.miniature.localId == "a").override_failure_message("Selected appearance changes exactly the linked selected Rook.").is_true()
	host.selected_rook = "two"
	sheet._on_appearance_save_requested("Selected", 1)
	await get_tree().process_frame
	assert_bool(host.appearance_changes == 1).override_failure_message("A changed local selection refuses the stale appearance action.").is_true()
	sheet.queue_free()
	await get_tree().process_frame

func _check_live_refresh(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "inventory", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	host.actors[0].data.inventory = []
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var empty = sheet.find_child("Empty", true, false)
	assert_bool(empty != null and empty.visible).override_failure_message("An already-open Inventory projects remote removal without reopening.").is_true()
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	var overview = sheet.find_child("CharacterOverview", true, false)
	var row = overview.get_node(^"Resources/HitPoints/Content/Row")
	row.get_node(^"Edit").pressed.emit()
	row.get_node(^"Input").text = "23"
	host.actors[0].data.name = "Remote name"
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(is_instance_valid(overview) and row.get_node(^"Input").text == "23" and row.get_node(^"Input").visible).override_failure_message("Remote edits preserve a dirty overview numeric field.").is_true()
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "inventory", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	host.actors[0].access_level = "Viewer"
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(sheet.find_child("Add", true, false).disabled).override_failure_message("A live access downgrade disables inventory mutation entries.").is_true()
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	host.actors[0].data.name = "Later remote name"
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	overview = sheet.find_child("CharacterOverview", true, false)
	assert_bool(overview.get_node(^"Resources/HitPoints/Content/Row/Edit").disabled).override_failure_message("A Viewer overview stays read-only after subsequent remote data changes.").is_true()
	host.actors.clear()
	host.WorldChanged.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(sheet.get_node(^"Content").get_child_count() == 0).override_failure_message("Revoked Actor access removes the cached private sheet.").is_true()
	sheet.queue_free()
	await get_tree().process_frame

func after_test() -> void:
	await get_tree().process_frame


func test_overview_groups_actions_in_responsive_sections() -> void:
	var overview = auto_free(load(ROOT + "ui/character_sheet_overview.tscn").instantiate())
	assert_bool(overview.has_node("Body/Context/AtTable/Content/HealthActions")).override_failure_message("Character actions belong to their approved sections, not full-width root buttons.").is_true()
	if not overview.has_node("Body/Context/AtTable/Content/HealthActions"):
		return
	overview.theme = load("res://rookframe/ui/theme/rookframe_theme.tres")
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(960, 944)
	add_child(viewport)
	viewport.add_child(overview)
	overview.configure({"class_title": "No Class", "power_uses": 3}, [])
	overview.size = Vector2(912, 800)
	await get_tree().process_frame
	await get_tree().process_frame
	var profile: Control = overview.get_node("Body/Identity")
	var attributes: Control = overview.get_node("Body/Attributes")
	assert_bool(profile.get_global_rect().position.y >= attributes.get_global_rect().end.y).is_true()
	assert_bool(overview.get_node("Body/Context/Powers").get_global_rect().position.x > profile.get_global_rect().position.x).is_true()
	var opened: Array = []
	overview.navigate_requested.connect(func(route, item): opened.append(route))
	overview.get_node("Body/Context/AtTable/Content/HealthActions/rest").pressed.emit()
	assert_array(opened).is_equal(["rest"])
	overview.size = Vector2(351, 800)
	overview.configure({}, [], true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(overview.get_node("Body").columns).is_equal(1)
	var actions: Control = overview.get_node("Body/Context/AtTable/Content/HealthActions")
	for button in actions.get_children():
		assert_bool(button.size.y >= 44).is_true()
		assert_bool(actions.get_global_rect().encloses(button.get_global_rect())).is_true()
