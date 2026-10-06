extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const LIBRARY = preload(ROOT + "ui/creature_library.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")

class Boundary extends "res://tests/miniature_boundary.gd":
	var feedback: Array = []
	var fail_link := false
	var surface_parent: Node
	var create_signal_active := false
	var opened_during_create_signal := false
	func ReadContent(package: String, id: String) -> Dictionary:
		if package == PackageId() and id == "seth-goblin":
			return {"ok": true, "value": {"packageId": package, "localId": id, "displayName": "Seth, Goblin", "localizedDisplayName": "Seth, Goblin", "type": "actor_definition", "available": true}}
		return super.ReadContent(package, id)
	func OpenActorWindowWithPresentation(scene: PackedScene, actor: String, _options: Dictionary) -> Dictionary:
		opened_surfaces.append(scene.resource_path)
		if surface_parent != null:
			opened_during_create_signal = create_signal_active
			# Match the host's checked fresh scene load, including shared scripts.
			var loaded: PackedScene = ResourceLoader.load(scene.resource_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
			var content := loaded.instantiate()
			content.set_meta("rookframe_sdk", self)
			surface_parent.add_child(content)
			content._rookframe_open_actor(actor)
		return {"ok": true}
	func opened_count() -> int:
		return opened_surfaces.size()
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
	viewport.size = Vector2i(844, 390)
	add_child(viewport)
	viewport.add_child(sheet)
	sheet.opened_definition(SDK.ContentReference.new(host.PackageId(), "seth-goblin"))
	await get_tree().process_frame
	await get_tree().process_frame
	var surface = sheet.get_node("Sheet")
	assert_str(surface.get_node(surface.IDENTITY + "Name").text).is_equal("Seth")
	assert_str(surface.get_node(surface.IDENTITY + "Health").accessibility_name).contains("6")
	assert_bool(surface.get_node("Inset/Layout/Footer/Create").disabled).is_false()
	assert_bool(surface.get_node(surface.IDENTITY + "Health").disabled).is_true()
	surface.show_chapter(1)
	assert_bool(surface.get_node(surface.WORK + "Inventory").is_visible_in_tree()).is_true()
	assert_bool(surface.get_node(surface.WORK + "Encounter").is_visible_in_tree()).is_false()
	surface.show_chapter(2)
	await get_tree().process_frame
	assert_str(surface.get_node(surface.WORK + "Appearance/Columns/MiniaturePanel/Inset/Content/MiniatureCaption").text).is_equal("Goblin")
	var source_button: Button = surface.get_node(surface.SOURCE)
	source_button.grab_focus()
	surface.show_source()
	assert_bool(surface.get_node(surface.WORK + "Reader").is_visible_in_tree()).is_true()
	surface.back()
	# Stable return focus follows the native layout frames.
	await assert_func(source_button, "has_focus").wait_until(1000).is_true()

func test_button_creates_actor_and_loads_live_sheet_after_create_signal_returns() -> void:
	var host := _host()
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	host.surface_parent = viewport
	var scene: PackedScene = ResourceLoader.load(ROOT + "ui/creature_definition_sheet.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var sheet := scene.instantiate()
	sheet.set_meta("rookframe_sdk", host)
	viewport.add_child(sheet)
	sheet._rookframe_open_definition(host.PackageId(), "seth-goblin")
	await get_tree().process_frame
	await get_tree().process_frame
	var create: Button = sheet.get_node("Sheet/Inset/Layout/Footer/Create")
	assert_bool(create.disabled).is_false()
	host.create_signal_active = true
	create.pressed.emit()
	host.create_signal_active = false
	await assert_func(host, "opened_count").wait_until(1000).is_equal(1)
	assert_bool(host.opened_during_create_signal).is_false()
	assert_int(host.actors.size()).is_equal(3)
	assert_int(host.placed.size()).is_equal(0)
	assert_int(host.opened_surfaces.size()).is_equal(1)
	var live: Control = viewport.get_child(1)
	assert_str(live.actor.data.name).is_equal("Seth, Goblin")
	assert_str(live.sheet.get_node(live.sheet.IDENTITY + "Name").text).is_equal("Seth, Goblin")

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
