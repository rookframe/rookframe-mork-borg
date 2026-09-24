extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/power_composition_boundary.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")

func test_use_item_shows_recipient_focus_pending_and_healing_outcome() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.merge({"hit_points": 7, "maximum_hit_points": 9}, true)
	host.actors.hero.data.inventory.append({"inventory_id": "medicine", "source_item_id": "medicine-box", "quantity": 1, "uses": 3})
	var path := ROOT + "ui/special_panel.tscn"
	assert_bool(ResourceLoader.exists(path)).is_true()
	if not ResourceLoader.exists(path):
		return
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var scene: PackedScene = load(path)
	var panel = auto_free(scene.instantiate())
	viewport.add_child(panel)
	panel.action_created.connect(func(action: Node) -> void: viewport.add_child(action))
	panel.size = Vector2(351, 260)
	panel.configure(SDK.Actor.new(host.actors.hero), SDK.new(host), "medicine")
	await get_tree().process_frame
	var eligible: Button = panel.get_node("Options/Eligible")
	assert_bool(eligible.size.y >= 44).is_true()
	eligible.grab_focus()
	assert_bool(eligible.has_focus()).is_true()
	eligible.button_pressed = true
	await panel.submit()
	await get_tree().process_frame
	assert_str(panel.primary_text()).is_equal("Waiting…")
	host.roll(host.last_request, [4])
	await get_tree().create_timer(0.6).timeout
	assert_str(panel.get_node("Outcome").text).contains("regained 2 HP")
	assert_str(panel.primary_text()).is_equal("Done")
	assert_int(host.actors.hero.data.inventory[-1].uses).is_equal(2)

func after_test() -> void:
	await get_tree().process_frame
