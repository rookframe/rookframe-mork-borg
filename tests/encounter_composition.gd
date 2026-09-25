extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/encounter_sdk_boundary.gd")
const VIEW = preload(ROOT + "ui/encounter_view.gd")

func test_phone_gm_can_act_without_scrolling_and_participant_sees_active_side() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("encounter.edit", {"revision": 0, "kind": "add", "rook": "hero-rook"})
	await sdk.system_actions.submit("encounter.edit", {"revision": 1, "kind": "add", "rook": "enemy-rook"})
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var strip = auto_free(load(ROOT + "ui/encounter_strip.tscn").instantiate())
	strip.sdk = sdk
	viewport.add_child(strip)
	var local = strip.encounter_view_state()
	local.select_rook("enemy-rook")
	var task_slot := VBoxContainer.new()
	viewport.add_child(task_slot)
	task_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	task_slot.offset_top = 56
	var window = auto_free(load(ROOT + "ui/encounter_window.tscn").instantiate())
	window.sdk = sdk
	task_slot.add_child(window)
	await get_tree().process_frame
	await get_tree().process_frame
	var primary: Button = window.get_node("Layout/Footer/TrailingSlot/Navigation/Primary")
	var previous: Button = window.get_node("Layout/Footer/TrailingSlot/Navigation/Previous")
	assert_float(primary.size.x).is_equal(previous.size.x)
	assert_float(primary.size.y).is_equal(previous.size.y)
	assert_bool(primary.get_global_rect().end.y <= 369).is_true()
	assert_bool(primary.size.y >= 44).is_true()
	var body: Control = window.get_node("Layout/Body")
	for action in ["Reaction", "Morale"]:
		var button: Button = window.get_node("Layout/Body/Content/Selected/Actions/" + action)
		assert_bool(button.get_global_rect().end.y <= body.get_global_rect().end.y).is_true()
		assert_bool(button.size.y >= 44).is_true()
	primary.grab_focus()
	primary.pressed.emit()
	await get_tree().process_frame
	assert_array(host.requests[host.last_request].terms).is_equal([{"name": "Initiative", "faces": 6, "count": 1}])
	var initiating_name: String = window.get_node("Layout/Body/Content/Selected/Identity/Name").text
	local.select_rook("hero-rook")
	assert_str(window.get_node("Layout/Body/Content/Selected/Identity/Name").text).is_equal(initiating_name)
	host.roll(host.last_request, [4])
	await window._poll()
	assert_str(primary.text).is_equal("Next")
	primary.pressed.emit()
	await get_tree().process_frame
	assert_str(host.world_data.encounter.current).is_equal("enemy")
	assert_bool(primary.has_focus()).is_true()
	host.SelectedRookContextChanged.emit({"id": host.selected_rook})
	assert_int(host.closed_surfaces).is_equal(0)
	window.hide()
	window.closed.emit()
	window.show()
	await get_tree().process_frame
	primary.pressed.emit()
	await get_tree().process_frame
	assert_int(host.world_data.encounter.round).is_equal(2)
	previous.pressed.emit()
	await get_tree().process_frame
	viewport.size = Vector2i(900, 390)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(primary.size.x >= 132).is_true()
	assert_float(primary.size.x).is_equal(previous.size.x)
	assert_bool(previous.get_global_rect().end.x < primary.get_global_rect().position.x).is_true()
	window.hide()
	window.closed.emit()
	host.game_master = false
	var state: Dictionary = VIEW.new().snapshot(sdk)
	assert_str(state.rows[1].label).is_equal("Hooded stranger")
	assert_str(str(state.rows)).not_contains("Seth").not_contains("armor")
	assert_str(state.rows[1].rook).is_equal("enemy-rook")
	strip.refresh()
	await get_tree().process_frame
	var card: Button = strip.get_node("Panel/Layout/Scroll/Groups").get_child(1).get_node("Entries").get_child(0)
	assert_bool(card.button_pressed).is_true()
	assert_array(host.previews).contains(["hero-rook", "enemy-rook"])
	card.set_pressed_no_signal(false)
	card.pressed.emit()
	await get_tree().process_frame
	assert_bool(card.button_pressed).is_true()
	assert_str(host.world_data.encounter.current).is_equal("enemy")

func test_swords_action_targets_currently_selected_rook_with_shared_actor() -> void:
	var host := BOUNDARY.new()
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.rooks["second-enemy"] = "enemy"
	host.selected_rook = "enemy-rook"
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var strip = auto_free(load(ROOT + "ui/encounter_strip.tscn").instantiate())
	strip.sdk = SDK.new(host)
	add_child(strip)
	var context = auto_free(load(ROOT + "ui/encounter_rook.tscn").instantiate())
	context.sdk = SDK.new(host)
	add_child(context)
	var button: Button = context.get_node("Toggle")
	assert_str(button.accessibility_name).is_equal("Add to combat")
	button.pressed.emit()
	await get_tree().process_frame
	assert_str(button.accessibility_name).is_equal("Remove from combat")
	host.selected_rook = "second-enemy"
	host.SelectedRookContextChanged.emit({"id": "second-enemy"})
	assert_str(button.accessibility_name).is_equal("Add to combat")
	button.pressed.emit()
	await get_tree().process_frame
	assert_int(host.world_data.encounter.entries.size()).is_equal(2)
	button.pressed.emit()
	await get_tree().process_frame
	assert_int(host.world_data.encounter.entries.size()).is_equal(1)
	assert_str(host.world_data.encounter.entries[0].rook).is_equal("enemy-rook")
	host.selected_rook = "enemy-rook"
	host.rooks["enemy-rook"] = ""
	host.SelectedRookContextChanged.emit({"id": "enemy-rook"})
	assert_bool(context.visible).is_true()
	assert_str(button.accessibility_name).is_equal("Remove from combat")
	button.pressed.emit()
	await get_tree().process_frame
	assert_int(host.world_data.encounter.entries.size()).is_equal(0)

func test_desktop_order_shows_three_complete_miniatures() -> void:
	var host := BOUNDARY.new()
	host.device = 0
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	host.rooks["second-enemy"] = "enemy"
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	var sdk := SDK.new(host)
	for rook in ["hero-rook", "enemy-rook", "second-enemy"]:
		var revision := int(host.world_data.get("encounter", {}).get("revision", 0))
		await sdk.system_actions.submit("encounter.edit", {"revision": revision, "kind": "add", "rook": rook})
	await sdk.system_actions.submit("encounter.edit", {"revision": 3, "kind": "correct", "round": 1, "current": "pc"})
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var strip = auto_free(load(ROOT + "ui/encounter_strip.tscn").instantiate())
	strip.sdk = sdk
	viewport.add_child(strip)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll: ScrollContainer = strip.get_node("Panel/Layout/Scroll")
	for group in scroll.get_node("Groups").get_children():
		for card in group.get_node("Entries").get_children():
			assert_bool(card.get_global_rect().end.x <= scroll.get_global_rect().end.x).is_true()

func after_test() -> void:
	await get_tree().process_frame
