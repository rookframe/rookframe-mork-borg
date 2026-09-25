extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/encounter_sdk_boundary.gd")
const VIEW = preload(ROOT + "ui/encounter_view.gd")

func test_phone_tracker_advances_from_fixed_controls_and_player_strip_hides_private_name() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "actor": "hero", "side": "pc"})
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "add", "actor": "enemy", "side": "enemy"})
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var window = auto_free(load(ROOT + "ui/encounter_window.tscn").instantiate())
	window.sdk = sdk
	var task_slot := VBoxContainer.new()
	viewport.add_child(task_slot)
	task_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	task_slot.add_child(window)
	await get_tree().process_frame
	var primary: Button = window.get_node("Layout/Footer/Primary")
	assert_float(window.size.y).is_equal(369.0)
	assert_bool(primary.get_global_rect().end.y <= window.get_global_rect().end.y).is_true()
	assert_bool(primary.size.y >= 44).is_true()
	assert_bool(primary.get_global_rect().end.y <= 369).is_true()
	assert_bool(window.get_node("Layout/Body").size.y < window.get_node("Layout/Body/Content").size.y).is_true()
	primary.grab_focus()
	assert_bool(primary.has_focus()).is_true()
	primary.pressed.emit()
	await get_tree().process_frame
	assert_str(primary.text).is_equal("Next turn")
	primary.pressed.emit()
	await get_tree().process_frame
	assert_str(host.world_data.encounter.current).is_equal("enemy")
	window.hide()
	window.closed.emit()
	window.show()
	await get_tree().process_frame
	primary.pressed.emit()
	await get_tree().process_frame
	assert_int(host.world_data.encounter.round).is_equal(2)
	window.get_node("Layout/Footer/Previous").pressed.emit()
	await get_tree().process_frame
	window.hide()
	window.closed.emit()
	host.game_master = false
	var state: Dictionary = VIEW.new().snapshot(sdk)
	assert_str(state.rows[1].label).is_equal("Hooded stranger")
	assert_bool(state.rows[1].can_open).is_false()
	assert_str(str(state.rows)).not_contains("Seth").not_contains("armor")
	var strip = auto_free(load(ROOT + "ui/encounter_strip.tscn").instantiate())
	strip.sdk = sdk
	viewport.add_child(strip)
	await get_tree().process_frame
	assert_int(strip.get_node("Panel/Layout/Scroll/Entries").get_child_count()).is_equal(2)
	assert_str(strip.get_node("Panel/Layout/Scroll/Entries").get_child(1).get_node("Layout/Turn").text).is_equal("CURRENT")

	# Native BaseButton toggles before emitting pressed. Inspection must not
	# replace the World-owned current-turn highlight with local button state.
	var current_card: Button = strip.get_node("Panel/Layout/Scroll/Entries").get_child(1)
	current_card.set_pressed_no_signal(false)
	current_card.pressed.emit()
	await get_tree().process_frame
	assert_bool(strip.get_node("Panel/Layout/Scroll/Entries").get_child(1).button_pressed).is_true()
	assert_str(host.world_data.encounter.current).is_equal("enemy")

func after_test() -> void:
	await get_tree().process_frame
