extends SceneTree

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/character_actions.gd")
const BOUNDARY = preload("res://tests/creation_sdk_boundary.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var host = BOUNDARY.new()
	host.actors.append({"id": "character", "access_level": "Owner", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "omens": 2, "hit_points": 7, "maximum_hit_points": 9, "abilities": {"Strength": {"score": 8, "modifier": -1}}, "inventory": []}})
	var sdk = SDK.new(host)
	var actions = ACTIONS.new(sdk, SDK.ActorId.new("character"))
	var result: SDK.ActorResult = await actions.correct("Strength", "5")
	_check(result.ok and result.actor.data.abilities.Strength.modifier == 5, "Completed corrections edit the played modifier, including improvement values.")
	_check(result.actor.data.abilities.Strength.score == 8, "Corrections preserve creation provenance.")
	result = await actions.correct("hit_points", "-2")
	_check(result.ok and result.actor.data.hit_points == -2, "Manual HP corrections retain below-zero results.")
	var before: Dictionary = sdk.actors.read(SDK.ActorId.new("character")).actor.data.duplicate(true)
	result = await actions.spend_omen()
	before.omens = 1
	_check(result.ok and result.actor.data == before, "Spending one Omen changes only the current count.")
	await actions.spend_omen()
	result = await actions.spend_omen()
	_check(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data.omens == 0, "No Omen can be spent below zero.")
	_check(host.requests.is_empty(), "Corrections and Omen spending request no dice.")
	result = await actions.add_equipment("sword")
	_check(result.ok, "Core catalogue adds a live sword.")
	var sword: Dictionary = result.actor.data.inventory[0]
	_check(sword.name == "Sword" and sword.damage == "d6" and not sword.equipped, "Catalogue supplies printed damage and starts carried.")
	var item_id: String = sword.inventory_id
	result = await actions.change_item(item_id, "equipped", "true")
	_check(result.ok and result.actor.data.inventory[0].equipped, "Equip persists on the selected live entry.")
	result = await actions.change_item(item_id, "quantity", "3")
	_check(result.ok and result.actor.data.inventory[0].quantity == 3, "Quantity correction changes the live entry.")
	result = await actions.change_item(item_id, "damage", "d8")
	_check(not result.ok, "Bundled mechanical definitions cannot be rewritten through a live edit.")
	result = await actions.add_custom({"name": "Bent blade", "kind": "Weapon", "damage": "d4", "range_feet": 5, "quantity": 1, "uses": 2})
	_check(result.ok and result.actor.data.inventory.size() == 2, "Custom supported fields become a separate live item.")
	var custom_id: String = result.actor.data.inventory[1].inventory_id
	result = await actions.change_item(custom_id, "damage", "d6")
	_check(result.ok and result.actor.data.inventory[1].damage == "d6", "Custom item damage can be corrected without changing the catalogue.")
	result = await actions.change_item(custom_id, "uses", "0")
	_check(result.ok and result.actor.data.inventory[1].uses == 0, "Depleted uses are retained, without automatic replenishment.")
	await actions.remove_item(item_id)
	result = await actions.change_item(item_id, "quantity", "9")
	_check(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data.inventory[0].name == "Bent blade", "A stale item editor never changes the entry shifted into its old position.")
	result = await actions.add_equipment("sword")
	_check(result.ok and result.actor.data.inventory[1].damage == "d6" and result.actor.data.inventory[1].quantity == 1, "New catalogue instances retain immutable defaults.")
	result = await actions.add_equipment("femur")
	_check(result.ok and result.actor.data.inventory[2].damage == "d4", "Core catalogue includes the printed Femur weapon.")
	await actions.correct("omens", "2")
	before = sdk.actors.read(SDK.ActorId.new("character")).actor.data.duplicate(true)
	host.actors[0].access_level = "Viewer"
	result = await actions.spend_omen()
	_check(not result.ok and sdk.actors.read(SDK.ActorId.new("character")).actor.data == before, "Viewer cannot perform sheet mutations even with Omens available.")
	host.actors[0].access_level = "Owner"
	await _check_pending_fields(host)
	await _check_appearance(host)
	await _check_live_refresh(host)
	print("CHARACTER_INVENTORY %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _check_pending_fields(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	root.add_child(sheet)
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "edit", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	var fields: Dictionary = {}
	for field in sheet.find_children("*", "VBoxContainer", true, false):
		if field.get_script() == load(ROOT + "ui/sheet_field.gd"):
			fields[field.field] = field
	host.defer_update = true
	fields.name.get_node(^"Field").value = "Pending name"
	fields.name.get_node(^"Actions/Save").pressed.emit()
	_check(fields.name.get_node(^"Actions/Save").disabled, "Pending field visibly disables duplicate saves.")
	fields.maximum_hit_points.get_node(^"Field").value = "17"
	fields.maximum_hit_points.get_node(^"Actions/Save").pressed.emit()
	_check(not fields.maximum_hit_points.get_node(^"Actions/Save").disabled, "Another field rejected while busy can retry.")
	_check(not fields.maximum_hit_points.get_node(^"Field").error_text.is_empty(), "Busy rejection is field-local.")
	host.complete_update()
	await process_frame
	_check(host.actors[0].data.name == "Pending name", "Pending save commits the submitted field.")
	_check(fields.maximum_hit_points.get_node(^"Field").value == "17", "Saving one field preserves another field’s unsaved text.")
	fields.name.get_node(^"Field").value = "Discard me"
	fields.name.get_node(^"Actions/Cancel").pressed.emit()
	_check(fields.name.get_node(^"Field").value == "Pending name", "Cancel restores the most recently saved value.")
	fields.maximum_hit_points.get_node(^"Actions/Save").pressed.emit()
	await process_frame
	_check(host.actors[0].data.maximum_hit_points == 17, "Rejected pending field can be retried successfully.")
	sheet.queue_free()
	await process_frame

func _check_appearance(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	root.add_child(sheet)
	host.rooks["one"] = {"id": "one", "actor": "character", "scene": "scene", "position": Vector2.ZERO, "yaw": 0.0, "miniature": {"packageId": "published", "localId": "a"}}
	host.rooks["two"] = host.rooks.one.duplicate(true)
	host.rooks.two.id = "two"
	host.selected_rook = ""
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = [{"package_id": "published", "local_id": "a", "title": "A"}, {"package_id": "published", "local_id": "b", "title": "B"}]
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "appearance", "character", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	var appearance = sheet.find_child("CharacterAppearance", true, false)
	_check(appearance.get_node(^"Selected/Content/Row/Details/Choose").disabled, "Appearance without a selection disables only the Rook choice.")
	host.selected_rook = "one"
	await process_frame
	await process_frame
	appearance = sheet.find_child("CharacterAppearance", true, false)
	_check(not appearance.get_node(^"Selected/Content/Row/Details/Choose").disabled, "An open Appearance sheet follows a new local Rook selection.")
	sheet._on_appearance_save_requested("Default", 2)
	await process_frame
	_check(host.actors[0].data.preferred_miniature.local_id == "b" and host.appearance_changes == 0, "Actor default changes no existing Rook.")
	sheet._on_appearance_save_requested("Selected", 2)
	await process_frame
	_check(host.rooks.one.miniature.localId == "b" and host.rooks.two.miniature.localId == "a", "Selected appearance changes exactly the linked selected Rook.")
	host.selected_rook = "two"
	sheet._on_appearance_save_requested("Selected", 1)
	await process_frame
	_check(host.appearance_changes == 1, "A changed local selection refuses the stale appearance action.")
	sheet.queue_free()
	await process_frame

func _check_live_refresh(host: RefCounted) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	root.add_child(sheet)
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "inventory", "character", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	host.actors[0].data.inventory = []
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	var empty = sheet.find_child("Empty", true, false)
	_check(empty != null and empty.visible, "An already-open Inventory projects remote removal without reopening.")
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	var overview = sheet.find_child("CharacterOverview", true, false)
	var row = overview.get_node(^"Resources/HitPoints/Content/Row")
	row.get_node(^"Edit").pressed.emit()
	row.get_node(^"Input").text = "23"
	host.actors[0].data.name = "Remote name"
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	_check(is_instance_valid(overview) and row.get_node(^"Input").text == "23" and row.get_node(^"Input").visible, "Remote edits preserve a dirty overview numeric field.")
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "inventory", "character", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	host.actors[0].access_level = "Viewer"
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	_check(sheet.find_child("Add", true, false).disabled, "A live access downgrade disables inventory mutation entries.")
	sheet.set_character(SDK.new(host).actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, SDK.new(host))
	await process_frame
	await process_frame
	host.actors[0].data.name = "Later remote name"
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	overview = sheet.find_child("CharacterOverview", true, false)
	_check(overview.get_node(^"Resources/HitPoints/Content/Row/Edit").disabled, "A Viewer overview stays read-only after subsequent remote data changes.")
	host.actors.clear()
	host.WorldChanged.emit()
	await process_frame
	await process_frame
	_check(sheet.get_node(^"Content").get_child_count() == 0, "Revoked Actor access removes the cached private sheet.")
	sheet.queue_free()
	await process_frame
