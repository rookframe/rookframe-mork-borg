extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/power_composition_boundary.gd")

func test_recovery_panel_eligibility_focus_pending_and_result() -> void:
	var path := ROOT + "ui/health_panel.tscn"
	assert_bool(ResourceLoader.exists(path)).is_true()
	if not ResourceLoader.exists(path):
		return
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.merge({"hit_points": 4, "maximum_hit_points": 9}, true)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var scene: PackedScene = load(path)
	var panel = auto_free(scene.instantiate())
	viewport.add_child(panel)
	panel.size = Vector2(351, 260)
	panel.action_created.connect(func(action: Node) -> void: viewport.add_child(action))
	panel.configure(SDK.Actor.new(host.actors.hero), SDK.new(host), "rest")
	await get_tree().process_frame
	await panel.submit()
	assert_int(host.requests.size()).is_equal(0)
	await get_tree().process_frame
	assert_str(panel.get_node("Outcome").text).contains("eligibility")
	var eligible: Button = panel.get_node("Columns/Context/Content/Eligible")
	assert_bool(eligible.size.y >= 44).is_true()
	eligible.grab_focus()
	assert_bool(eligible.has_focus()).is_true()
	eligible.button_pressed = true
	await panel.submit()
	await get_tree().process_frame
	assert_str(panel.primary_text()).is_equal("Waiting…")
	host.roll(host.last_request, [4])
	await get_tree().create_timer(0.6).timeout
	assert_str(panel.get_node("Outcome").text).contains("regained 4 HP")
	assert_str(panel.primary_text()).is_equal("Done")

func after_test() -> void:
	await get_tree().process_frame
