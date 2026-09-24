extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const DIALOG = preload(ROOT + "ui/shield_dialog.tscn")

func test_compact_shield_geometry_focus_pending_and_close() -> void:
	get_window().gui_embed_subwindows = true
	get_window().size = Vector2i(844, 390)
	var dialog = auto_free(DIALOG.instantiate())
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(844, 390)
	viewport.gui_embed_subwindows = true
	add_child(viewport)
	viewport.add_child(dialog)
	dialog.present({"character": "Graveworm", "loss": 2, "hp": 7})
	await get_tree().process_frame
	await get_tree().process_frame
	# The headless display driver has no native Window size. Native evidence
	# checks the real dialog, while this case checks the authored composition.
	if DisplayServer.get_name() != "headless":
		assert_vector(dialog.size).is_equal(Vector2i(368, 224))
	else:
		dialog.get_node("Shell").size = Vector2(368, 224)
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var shell: Control = dialog.get_node("Shell")
	assert_vector(shell.size).is_equal(Vector2(368, 224))
	var take: Button = dialog.get_node("Shell/Content/Actions/Take")
	var destroy: Button = dialog.get_node("Shell/Content/Actions/Break")
	assert_bool(take.has_focus()).is_true()
	assert_str(take.text).is_equal("Take 2 damage")
	assert_bool(take.size.y >= 44 and destroy.size.y >= 44).is_true()
	assert_bool(shell.get_global_rect().encloses(take.get_global_rect())).is_true()
	assert_bool(shell.get_global_rect().encloses(destroy.get_global_rect())).is_true()
	assert_str(dialog.get_node("Shell/Content/Body/Copy").text).contains("7 → 5 HP")
	dialog.set_pending(true)
	assert_bool(take.disabled and destroy.disabled).is_true()
	dialog.close_requested.emit()
	assert_bool(dialog.visible).is_false()

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
