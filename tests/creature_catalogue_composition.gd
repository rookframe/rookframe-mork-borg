extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const LIBRARY = preload(ROOT + "ui/creature_library.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")

class Boundary extends "res://tests/miniature_boundary.gd":
	var feedback: Array = []
	var fail_link := false
	func ReadContent(package: String, id: String) -> Dictionary:
		if package == PackageId() and id == "seth-goblin":
			return {"ok": true, "value": {"packageId": package, "localId": id, "displayName": "Seth, Goblin", "localizedDisplayName": "Seth, Goblin", "type": "actor_definition", "available": true}}
		return super.ReadContent(package, id)
	func OpenActorWindowWithPresentation(scene: PackedScene, _actor: String, _options: Dictionary) -> Dictionary:
		opened_surfaces.append(scene.resource_path)
		return {"ok": true}
	func ShowFeedback(title: String, message: String, severity: String, actions: Array) -> int:
		feedback.append({"title": title, "message": message, "severity": severity, "actions": actions})
		return feedback.size()
	func DeleteActor(id: String) -> Dictionary:
		actors.erase(id)
		return {"ok": true}
	func LinkRook(id: String, actor: String) -> Dictionary:
		return {"ok": false, "message": "Link failed"} if fail_link else super.LinkRook(id, actor)

func _host() -> Boundary:
	var host := Boundary.new()
	host.game_master = true
	host.world_data = {"creature_miniatures": {"seth-goblin": {"package_id": "external-miniatures", "local_id": "goblin"}}}
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	return host

func test_library_definition_opens_independent_sheet() -> void:
	var host := _host()
	var sheet = auto_free(load(ROOT + "ui/creature_definition_sheet.tscn").instantiate())
	sheet.sdk = SDK.new(host)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	viewport.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sheet.size = Vector2(351, 325)
	sheet.opened_definition(SDK.ContentReference.new(host.PackageId(), "seth-goblin"))
	await get_tree().process_frame
	assert_str(sheet.get_node("Layout/Tabs/Creature/Preview/Identity/Content/Title").text).is_equal("SETH, GOBLIN")
	assert_str(sheet.get_node("Layout/Tabs/Creature/Preview/Stats/HitPoints/Content/Value").text).is_equal("6")
	assert_bool(sheet.get_node("Layout/Create").disabled).is_false()
	var appearance: Control = sheet.get_node("Layout/Tabs/Appearance/Miniature")
	assert_bool(appearance.is_visible_in_tree()).is_false()
	sheet.get_node("Layout/Tabs").current_tab = 1
	assert_bool(appearance.is_visible_in_tree()).is_true()
	assert_bool(sheet.get_node("Layout/Tabs/Creature").is_visible_in_tree()).is_false()
	assert_str(appearance.get_node("Current").text).is_equal("Goblin")
	assert_bool(sheet.find_child("DefinitionList", true, false) == null).is_true()
	assert_bool(sheet.get_combined_minimum_size().x <= 351).is_true()
	var actor = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	assert_bool(actor.has_node("Layout/Body/Content/Catalogue")).is_false()
	assert_bool(actor.has_node("Layout/Body/Content/LiveList")).is_false()
	assert_bool(actor.has_node("Layout/Header/Routes/Desktop/Creatures")).is_false()

func test_button_creates_actor_without_placing_rook() -> void:
	var host := _host()
	var result = await LIBRARY.new(SDK.new(host)).create(SDK.ContentReference.new(host.PackageId(), "seth-goblin"))
	assert_bool(result.ok).is_true()
	assert_int(host.actors.size()).is_equal(3)
	assert_int(host.placed.size()).is_equal(0)
	assert_int(host.opened_surfaces.size()).is_equal(1)

func test_drop_creates_linked_rook_at_selected_scene_and_position() -> void:
	var host := _host()
	var result = await LIBRARY.new(SDK.new(host)).create(SDK.ContentReference.new(host.PackageId(), "seth-goblin"), SDK.SceneId.new("dungeon"), Vector2(2, -3))
	assert_bool(result.ok).is_true()
	assert_int(host.placed.size()).is_equal(1)
	var rook: Dictionary = host.placed.values()[0]
	assert_str(rook.actor).is_equal(result.actor.id.value)
	assert_str(rook.scene).is_equal("dungeon")
	assert_vector(rook.position).is_equal(Vector2(2, -3))
	assert_int(host.opened_surfaces.size()).is_equal(0)

func test_failed_link_removes_partial_rook_and_actor() -> void:
	var host := _host()
	host.fail_link = true
	var result = await LIBRARY.new(SDK.new(host)).create(SDK.ContentReference.new(host.PackageId(), "seth-goblin"), SDK.SceneId.new("dungeon"))
	assert_bool(result.ok).is_false()
	assert_int(host.actors.size()).is_equal(2)
	assert_int(host.placed.size()).is_equal(0)
	assert_int(host.feedback.size()).is_equal(1)

func test_participant_cannot_create_creatures() -> void:
	var host := _host()
	host.game_master = false
	var result = await LIBRARY.new(SDK.new(host)).create(SDK.ContentReference.new(host.PackageId(), "seth-goblin"))
	assert_bool(result.ok).is_false()
	assert_int(host.actors.size()).is_equal(2)
	assert_int(host.placed.size()).is_equal(0)
