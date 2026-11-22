extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const DIALOG = preload(ROOT + "ui/shield_dialog.tscn")
const WORLD_THEME = preload("res://tests/world_theme.gd")

func test_compact_shield_geometry_focus_pending_and_close() -> void:
	get_window().gui_embed_subwindows = true
	# A portrait phone: the headless display driver gives a Window no size, so
	# the Dialog's opening height has to fit the canvas for it to be placed.
	get_window().size = Vector2i(390, 844)
	var dialog = auto_free(DIALOG.instantiate())
	# Rookframe supplies its active theme to Package surfaces.
	dialog.theme = WORLD_THEME.entry()
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(390, 844)
	viewport.gui_embed_subwindows = true
	add_child(viewport)
	viewport.add_child(dialog)
	dialog.present({"character": "Graveworm", "loss": 2, "hp": 7})
	# The UI Kit Dialog settles its size over two frames, then the Package
	# focuses its own body action.
	for frame in 6:
		await get_tree().process_frame
	var window: Window = dialog.get_node("Dialog")
	assert_bool(window.visible).is_true()
	if DisplayServer.get_name() != "headless":
		var needed := window.get_contents_minimum_size()
		assert_bool(window.size.x >= needed.x and window.size.y >= needed.y).override_failure_message("Shield dialog %s is smaller than its content %s." % [window.size, needed]).is_true()
		assert_bool(Rect2i(Vector2i.ZERO, viewport.size).encloses(Rect2i(window.position, window.size))).override_failure_message("Shield dialog %s at %s does not fit the canvas." % [window.size, window.position]).is_true()
	var take: Button = window.get_body_slot().get_child(0)
	assert_bool(take.has_focus()).is_true()
	assert_str(take.text).is_equal("Take 2 damage")
	assert_bool(take.size.y >= 44).is_true()
	if DisplayServer.get_name() != "headless":
		assert_bool(Rect2(Vector2.ZERO, window.size).encloses(take.get_global_rect())).is_true()
	assert_str(window.heading).is_equal("Break shield?")
	assert_str(window.confirm_label).is_equal("Break shield")
	assert_str(window.description).contains("7 → 5 HP")
	var choices: Array[String] = []
	var cancellations: Array[bool] = []
	dialog.choice_requested.connect(func(choice: String) -> void: choices.append(choice))
	dialog.cancelled.connect(func() -> void: cancellations.append(true))
	take.pressed.emit()
	assert_array(choices).is_equal(["take"])
	assert_bool(window.visible).is_true()
	assert_bool(take.disabled and not window.confirm_enabled).is_true()
	dialog.set_pending(false)
	assert_bool(not take.disabled and window.confirm_enabled).is_true()
	window.confirmed.emit()
	assert_array(choices).is_equal(["take", "break"])
	assert_bool(take.disabled and not window.confirm_enabled).is_true()
	window.close_requested.emit()
	assert_bool(window.visible).is_false()
	assert_array(cancellations).is_equal([true])

func after_test() -> void:
	await get_tree().process_frame

func test_switching_actor_discards_the_previous_defence_presentation() -> void:
	var host = preload("res://tests/defence_sdk_boundary.gd").new()
	host.handler = auto_free(preload(ROOT + "logic/implementation.gd").new())
	add_child(host.handler)
	var facade = SDK.new(host)
	var started = await facade.system_actions.submit("defence.start", {"id": "sheet-switch", "source": "enemy", "rook": "enemy-rook", "attack": "knife"})
	host.as_player()
	var sheet = auto_free(preload(ROOT + "ui/character_sheet.tscn").instantiate())
	add_child(sheet)
	sheet.hide()
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.Actor.new(host.actors.hero), "character", "character", miniatures, choices, facade)
	sheet.offer_defence(started.value)
	var other: Dictionary = host.actors.hero.duplicate(true)
	other.id = "another-character"
	sheet.set_character(SDK.Actor.new(other), "character", "character", miniatures, choices, facade)
	# Consume the queued cancellation update with the new Actor already selected.
	sheet._process(0.0)
	assert_str(sheet._character_route).is_equal("character")
	var ended = await facade.system_actions.submit("defence.advance", {"id": "sheet-switch"})
	assert_str(ended.value.state).is_equal("ended")
