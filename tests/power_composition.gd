extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const PANEL = preload(ROOT + "ui/powers_panel.tscn")
const BOUNDARY = preload("res://tests/power_composition_boundary.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")

func test_cast_controls_and_terminal_gm_report_in_phone_body() -> void:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data["power_uses"] = 3
	host.actors.hero.data["hit_points"] = 7
	host.actors.hero.data.inventory.append({"inventory_id": "scroll", "source_item_id": "tongue-of-eris", "quantity": 1})
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var panel = auto_free(PANEL.instantiate())
	viewport.add_child(panel)
	panel.action_created.connect(func(action: Node) -> void: viewport.add_child(action))
	panel.size = Vector2(351, 260)
	panel.configure(SDK.Actor.new(host.actors.hero), SDK.new(host), "scroll")
	await get_tree().process_frame
	await get_tree().process_frame
	var eligible: Button = panel.get_node("Cast/Options/Eligible")
	assert_bool(eligible.size.y >= 44).is_true()
	eligible.grab_focus()
	assert_bool(eligible.has_focus()).is_true()
	panel.get_node("Cast/Options/Modifier").value = "bad"
	await panel.submit()
	assert_bool(host.requests.is_empty()).is_true()
	assert_str(panel.get_node("Outcome").text).contains("whole-number")
	panel.get_node("Cast/Options/Modifier").value = "0"
	eligible.button_pressed = true
	await panel.submit()
	await get_tree().process_frame
	assert_bool(panel.get_node("Cast/Columns/Targets/Content/Change").disabled).is_true()
	host.roll(host.last_request, [20])
	host.WorldChanged.emit()
	await get_tree().create_timer(0.6).timeout
	assert_str(panel.get_node("Outcome").text).contains("Power critical: GM determines the outcome").contains("ended")
	assert_bool(panel.get_node("Cast").visible).is_false()
	assert_int(host.actors.hero.data.power_uses).is_equal(3)

func after_test() -> void:
	await get_tree().process_frame
