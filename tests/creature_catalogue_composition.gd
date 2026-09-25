extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")

func test_catalogue_has_core_choices_and_responsive_definition_preview() -> void:
	var window = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	assert_bool(window.has_node("Layout/Body/Content/Catalogue")).override_failure_message("The approved Creature catalogue requires its selectable list and definition preview.").is_true()
	if not window.has_node("Layout/Body/Content/Catalogue"):
		return
	var catalogue = window.get_node("Layout/Body/Content/Catalogue")
	catalogue.owner = null
	catalogue.get_parent().remove_child(catalogue)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(960, 944)
	add_child(viewport)
	viewport.add_child(auto_free(catalogue))
	var entries: Array[SDK.ContentEntry] = []
	for id in CREATURES.CORE_DEFINITIONS:
		entries.append(SDK.ContentEntry.new({"packageId": "system", "localId": id, "displayName": CREATURES.CORE_DEFINITIONS[id].display_name, "type": "actor_definition", "available": true}))
	catalogue.configure(entries, "seth-goblin")
	catalogue.size = Vector2(912, 650)
	await get_tree().process_frame
	await get_tree().process_frame
	var rows = catalogue.get_node("List/Content/DefinitionList").get_children()
	assert_int(rows.size()).is_equal(12)
	assert_bool(catalogue.vertical).is_false()
	assert_str(catalogue.get_node("Preview/Identity/Content/Title").text).is_equal("SETH, GOBLIN")
	assert_str(catalogue.get_node("Preview/Stats/HitPoints/Content/Value").text).is_equal("6")
	assert_str(catalogue.get_node("Preview/Stats/Morale/Content/Value").text).is_equal("7")
	for row in rows:
		row.pressed.emit()
		assert_str(catalogue.get_node("Preview/Identity/Content/Title").text).is_equal(row.title.to_upper())
	catalogue.configure(entries, "seth-goblin")
	var chosen = rows.filter(func(row): return row.title == "Seth, Goblin")[0]
	assert_bool(chosen.button_pressed).is_true()
	assert_bool(chosen.get_node("Content/IndicatorLane/Indicator").visible).is_true()
	assert_bool(rows[0].get_node("Content/IndicatorLane/Indicator").visible).is_false()
	assert_bool(chosen.size.y >= 44).is_true()
	var selections: Array = []
	catalogue.selected.connect(func(entry): selections.append(entry))
	chosen.grab_focus()
	catalogue.configure(entries, "seth-goblin")
	assert_bool(chosen.has_focus()).is_true()
	assert_int(selections.size()).is_equal(0)
	chosen.pressed.emit()
	assert_int(selections.size()).is_equal(1)
	assert_str(chosen.get_node("Content/State").text).is_equal("Selected")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_END
	chosen._gui_input(key)
	assert_str(catalogue.selection().reference.local_id).is_equal("zukuma-berserker")
	assert_bool(rows[-1].has_focus()).is_true()
	key.keycode = KEY_HOME
	rows[-1]._gui_input(key)
	assert_str(catalogue.selection().reference.local_id).is_equal("aland-wickhead")
	assert_bool(rows[0].has_focus()).is_true()
	catalogue.filter("troll")
	assert_int(rows.filter(func(row): return row.visible).size()).is_equal(1)
	assert_int(rows.filter(func(row): return row.visible and row.focus_mode == 2).size()).is_equal(1)
	assert_str(catalogue.selection().reference.local_id).is_equal("aland-wickhead")
	catalogue.filter("")
	assert_int(rows[0].focus_mode).is_equal(2)
	catalogue.size = Vector2(351, 260)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(catalogue.vertical).is_true()
	assert_bool(catalogue.get_node("Preview").size.x <= 351).is_true()
	assert_int(CREATURES.CORE_DEFINITIONS["seth-goblin"].hit_points).is_equal(6)

func test_catalogue_footer_recovers_after_character_navigation() -> void:
	var window = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	assert_bool(window.has_method("_configure_catalogue_actions")).is_true()
	if not window.has_method("_configure_catalogue_actions"):
		return
	var back: Button = window.get_node("Layout/CatalogueBar/LeadingSlot/Back")
	var creation: Button = window.get_node("Layout/CatalogueBar/TrailingSlot/CreateCharacter")
	back.visible = false
	back.disabled = true
	back.text = "Start over"
	creation.visible = true
	window._configure_catalogue_actions(true)
	assert_bool(back.visible).is_true()
	assert_bool(back.disabled).is_false()
	assert_str(back.text).is_equal("Back")
	assert_bool(creation.visible).is_false()
	assert_bool(window.get_node("Layout/CatalogueBar").visible).is_true()
	var footer: Control = window.get_node("Layout/CatalogueBar")
	footer.theme = window.theme
	footer.owner = null
	footer.get_parent().remove_child(footer)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	viewport.add_child(auto_free(footer))
	footer.size = Vector2(351, 44)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(footer.get_combined_minimum_size().x <= 351).is_true()
	assert_bool(footer.get_rect().encloses(back.get_rect())).is_true()
	assert_bool(back.size.y >= 44).is_true()
