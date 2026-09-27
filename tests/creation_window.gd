extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/creation_window_boundary.gd")
const THEME = preload("res://rookframe/ui/theme/rookframe_theme.tres")

func test_complete_wizard_retains_draft_while_hidden_and_fits_each_window() -> void:
	for profile in [["phone", 2, Vector2i(375, 321)], ["tablet", 1, Vector2i(412, 720)], ["desktop", 0, Vector2i(960, 896)]]:
		var host = BOUNDARY.new()
		host.device = profile[1]
		host.outcomes = {"Agility": [[3, 3, 3]], "Presence": [[3, 3, 3]], "Strength": [[3, 3, 3]], "Toughness": [[3, 3, 3]], "Hit points": [[4]], "Silver": [[3, 3]], "Omens": [[1]], "Food": [[3]], "Equipment pack": [[6]], "Equipment first": [[3]], "Equipment second": [[6]], "Weapon": [[1]], "Armor": [[1]]}
		var viewport: SubViewport = auto_free(SubViewport.new())
		viewport.size = profile[2]
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var surface = load(ROOT + "ui/character_creation_window.tscn").instantiate()
		host.window = surface
		surface.sdk = SDK.new(host)
		viewport.add_child(surface)
		surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var creator = surface.get_node(^"Layout/Body/Content/CharacterCreator")
		var primary: Button = surface.get_node(^"Layout/CatalogueBar/TrailingSlot/CreateCharacter")
		for frame in range(180):
			await get_tree().process_frame
			if host.requests.size() >= 9:
				break
			if not primary.disabled:
				primary.pressed.emit()
		await _settle()
		assert_bool(primary.get_global_rect().end.y <= viewport.size.y).is_true()
		assert_bool(primary.size.y >= 44).is_true()
		assert_bool(surface.get_combined_minimum_size().x <= viewport.size.x).is_true()
		await _capture(viewport, str(profile[0]) + "-equipment")
		var choice: Button = creator.get_node(^"View/Main/Content/Equipment/PackChoices/Options/Choice1")
		assert_bool(choice.is_visible_in_tree()).is_true()
		await _settle()
		await _capture(viewport, str(profile[0]) + "-pack")
		choice.pressed.emit()
		for frame in range(180):
			await get_tree().process_frame
			if creator.get_node(^"View/Main/Content/Identity").visible:
				break
			if not primary.disabled:
				primary.pressed.emit()
		var field = creator.get_node(^"View/Main/Content/Identity/Name")
		field.value = "Varg"
		var picker: Control = creator.get_node(^"MiniaturePicker")
		creator.get_node(^"View/Aside/Context/Content/PreferredMiniature").pressed.emit()
		surface.hide()
		await _settle()
		assert_bool(creator.is_active()).is_true()
		assert_bool(picker.get_combined_minimum_size().x <= viewport.size.x).is_true()
		assert_bool(picker.get_node(^"Picker/Actions/Apply").get_global_rect().end.y <= viewport.size.y).is_true()
		await _capture(viewport, str(profile[0]) + "-miniatures")
		picker.get_node(^"Picker/Actions/Back").pressed.emit()
		assert_str(field.value).is_equal("Varg")
		assert_bool(creator.get_node(^"View/Main/Content/Identity").visible).is_true()
		surface.hide()
		surface.closed.emit()
		assert_bool(creator.is_active()).is_false()
		viewport.free()

func _settle() -> void:
	for frame in range(5):
		await get_tree().process_frame

func _capture(viewport: SubViewport, name: String) -> void:
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		viewport.get_texture().get_image().save_png("/tmp/creator-" + name + ".png")
