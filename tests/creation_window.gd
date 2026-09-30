extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/creation_window_boundary.gd")
const THEME = preload("res://rookframe/ui/theme/rookframe_theme.tres")

func test_complete_wizard_retains_draft_while_hidden_and_fits_each_window() -> void:
	for profile in [["desktop", 0, Vector2i(1920, 1080)], ["phone", 1, Vector2i(844, 390)]]:
		var host = BOUNDARY.new()
		host.device = profile[1]
		host.outcomes = {"Agility": [[3, 3, 3]], "Presence": [[3, 3, 3]], "Strength": [[3, 3, 3]], "Toughness": [[3, 3, 3]], "Hit points": [[4]], "Silver": [[3, 3]], "Omens": [[1]], "Food": [[3]], "Equipment pack": [[6]], "Equipment first": [[3]], "Equipment second": [[6]], "Weapon": [[1]], "Armor": [[1]]}
		host.outcomes.merge({"Origin": [[2]], "First decoction": [[1]], "Second decoction": [[4]], "Decoction doses": [[3]]})
		var viewport: SubViewport = auto_free(SubViewport.new())
		viewport.size = profile[2]
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var surface = load(ROOT + "ui/character_creation_window.tscn").instantiate()
		host.window = surface
		surface.sdk = SDK.new(host)
		viewport.add_child(surface)
		surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var creator = surface.get_node(^"CharacterCreator")
		var primary: Button = surface.get_node(^"CharacterCreator/View/Layout/Footer/Row/Primary")
		var view = creator.get_node(^"View")
		await _settle()
		if profile[0] == "phone":
			await _capture(viewport, "phone-class")
			var classes: Array[Node] = view.get_node(view.LEFT + "/Choices/Area/Rows").get_children()
			assert_int(classes.size()).is_equal(7)
			for row in classes:
				assert_bool(row.is_visible_in_tree()).is_true()
				assert_bool(row.get_global_rect().end.x <= viewport.size.x).is_true()
				assert_bool(row.get_global_rect().end.y <= primary.global_position.y).is_true()
			assert_bool(primary.get_global_rect().end.y <= viewport.size.y).is_true()
		for resource in ["Silver", "Omens"]:
			assert_str(view.get_node(view.CONTEXT + "/PortraitVitals/Vitals/" + resource + "/Row/Value").text).is_equal("—")
		view.get_node(view.LEFT).get_node(^"Choices/Area/Rows").get_child(6).pressed.emit()
		if profile[0] == "phone":
			_button(view, "Class details").pressed.emit()
			await _settle()
			await _capture(viewport, "phone-class-detail")
			_button(view, "Class list").pressed.emit()
		var captures: Array[String] = []
		for frame in range(180):
			await get_tree().process_frame
			var route: String = creator.capture_reconnect_state().stage
			if not captures.has(route):
				captures.append(route)
				await _settle()
				await _capture(viewport, str(profile[0]) + "-" + route)
				if profile[0] == "phone" and route in ["create-abilities", "create-origin"]:
					_button(view, "Roll details").pressed.emit()
					await _settle()
					await _capture(viewport, "phone-" + route + "-detail")
					_button(view, "Roll list").pressed.emit()
			if bool(creator.capture_reconnect_state().draft.get("pack_choice_pending", false)):
				break
			if not primary.disabled:
				primary.pressed.emit()
		await _settle()
		assert_bool(primary.get_global_rect().end.y <= viewport.size.y).is_true()
		assert_bool(primary.size.y >= 44).is_true()
		assert_bool(surface.get_combined_minimum_size().x <= viewport.size.x).is_true()
		await _capture(viewport, str(profile[0]) + "-equipment")
		var choice: Button = creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Detail/Content/PackChoices/Options/Choice1")
		assert_bool(choice.is_visible_in_tree()).is_true()
		await _settle()
		await _capture(viewport, str(profile[0]) + "-pack")
		choice.pressed.emit()
		for frame in range(180):
			await get_tree().process_frame
			if creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Left/Identity").visible:
				break
			if not primary.disabled:
				primary.pressed.emit()
		var field = creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Left/Identity/Name")
		field.get_node(^"Editor").text = "Varg"
		field.get_node(^"Editor").text_changed.emit("Varg")
		await _settle()
		await _capture(viewport, str(profile[0]) + "-identity")
		if profile[0] == "phone":
			_button(view, "Appearance").pressed.emit()
			await _settle()
			await _capture(viewport, "phone-appearance")
		var picker: Control = creator.get_node(^"MiniaturePicker")
		creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Detail/Content/Appearance/Copy/PreferredMiniature").pressed.emit()
		await _settle()
		await _capture(viewport, str(profile[0]) + "-browser")
		surface.hide()
		await _settle()
		assert_bool(creator.is_active()).is_true()
		assert_bool(picker.get_combined_minimum_size().x <= viewport.size.x).is_true()
		assert_bool(picker.get_node(^"Picker/Layout/Footer/Row/Choose").get_global_rect().end.y <= viewport.size.y).is_true()
		picker.get_node(^"Picker/Layout/Footer/Row/Cancel").pressed.emit()
		assert_str(field.value).is_equal("Varg")
		assert_bool(creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Left/Identity").visible).is_true()
		view.miniature_requested.emit()
		picker.get_node(^"Picker/Layout/Results/Content/GridArea/Rows").get_child(0).pressed.emit()
		picker.get_node(^"Picker/Layout/Footer/Row/Choose").pressed.emit()
		primary.pressed.emit()
		assert_str(creator.capture_reconnect_state().stage).is_equal("create-review")
		await _settle()
		await _capture(viewport, str(profile[0]) + "-review")
		if profile[0] == "phone":
			for section in ["Gear", "Traits", "Character"]:
				_button(view, section).pressed.emit()
				await _settle()
				await _capture(viewport, "phone-review-" + section.to_lower())
		view.get_node(^"Layout/Footer/Row/Back").pressed.emit()
		surface.hide()
		surface.closed.emit()
		assert_bool(creator.is_active()).is_true()
		surface.show()
		await _settle()
		assert_str(field.value).is_equal("Varg")
		assert_bool(creator.get_node(^"View/Layout/Body/StageSlot/Stage/Content/Split/Left/Identity").visible).is_true()
		var restart: Button = surface.get_node(^"CharacterCreator/View/Layout/Footer/Row/Restart")
		restart.pressed.emit()
		assert_str(host.feedback_request.severity).is_equal("confirmation")
		host.FeedbackActionSelected.emit(71, "keep-character")
		assert_str(field.value).is_equal("Varg")
		restart.pressed.emit()
		host.FeedbackActionSelected.emit(71, "restart-character")
		assert_str(creator.capture_reconnect_state().stage).is_equal("create-class")
		assert_bool(creator.is_active()).is_true()
		await _settle()
		viewport.free()

func _button(root: Node, text: String) -> Button:
	for control in root.find_children("*", "Button", true, false):
		if control.is_visible_in_tree() and control.text == text:
			return control
	fail("Visible action missing: " + text)
	return null

func _settle() -> void:
	for frame in range(5):
		await get_tree().process_frame

func _capture(viewport: SubViewport, name: String) -> void:
	if name.begins_with("phone-") and not name.ends_with("-browser"):
		var view = viewport.get_child(0).get_node(^"CharacterCreator/View")
		assert_bool(view.get_node(^"Layout").get_global_rect() == Rect2(1, 1, 842, 388)).is_true()
		var bounds := Rect2(Vector2.ZERO, viewport.size)
		for button in view.find_children("*", "Button", true, false):
			if button.is_visible_in_tree():
				assert_bool(button.size.y >= 44).is_true()
				assert_bool(bounds.encloses(button.get_global_rect())).is_true()
		var portrait = view.get_node(view.CONTEXT + "/PortraitVitals/PortraitFrame")
		assert_bool(portrait.size == Vector2(80, 100)).is_true()
	if DisplayServer.get_name() != "headless":
		var directory := OS.get_environment("RFG_EVIDENCE_DIR")
		if directory.is_empty():
			directory = OS.get_user_data_dir().path_join("creation-evidence")
		DirAccess.make_dir_recursive_absolute(directory)
		RenderingServer.force_draw()
		viewport.get_texture().get_image().save_png(directory.path_join("creator-" + name + ".png"))

func test_created_actor_sheet_retry_survives_a_fresh_sdk_after_reconnect() -> void:
	var first = BOUNDARY.new()
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var surface = load(ROOT + "ui/character_creation_window.tscn").instantiate()
	first.window = surface
	surface.sdk = SDK.new(first)
	viewport.add_child(surface)
	var actor := {"id": "already-created", "access_level": "Owner", "data": {"name": "Retained survivor", "class_title": "No Class", "silver": 70, "omens": 2, "inventory": []}}
	first.actors.append(actor)
	surface.get_node("CharacterCreator").discard()
	surface._created(SDK.Actor.new(actor))
	assert_str(surface.get_node("CharacterCreator/View/Layout/Footer/Row/Primary").text).is_equal("Open character")
	var retained: Dictionary = surface.capture_reconnect_state()
	assert_str(str(retained.get("created_actor_id", ""))).is_equal("already-created")
	surface.free()
	var fresh = BOUNDARY.new()
	fresh.actors.append(actor.duplicate(true))
	fresh.reject_sheet = false
	var restored = load(ROOT + "ui/character_creation_window.tscn").instantiate()
	fresh.window = restored
	restored.sdk = SDK.new(fresh)
	viewport.add_child(restored)
	fresh.restoring_private_draft = true
	restored.restore_reconnect_state(retained)
	fresh.restoring_private_draft = false
	var view = restored.get_node("CharacterCreator/View")
	assert_bool(view.get_node(view.STAGE + "/Content/Review").visible).is_true()
	assert_str(view.get_node(view.CONTEXT + "/PortraitVitals/Vitals/Silver/Row/Value").text).is_equal("70")
	assert_str(view.get_node(view.CONTEXT + "/PortraitVitals/Vitals/Omens/Row/Value").text).is_equal("2")
	assert_bool(restored.get_node("CharacterCreator").is_active()).is_false()
	restored.get_node("CharacterCreator/View/Layout/Footer/Row/Primary").pressed.emit()
	assert_str(fresh.opened_actor).is_equal("already-created")
	assert_int(fresh.actors.size()).is_equal(1)
	assert_bool(restored.visible).is_false()
	await _settle()
	viewport.free()
