extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/character_hud_boundary.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ENTRY = preload(ROOT + "ui/hud_entry.gd")

func _open(canvas: Vector2i, language := "en") -> Dictionary:
	var host := BOUNDARY.new()
	host.language = language
	host.device = 2 if canvas.x <= 900 else 1 if canvas.x <= 1300 else 0
	host.actors.hero.data.merge({"name":"Graveworm", "class_id":"occult-herbmaster", "class_title":"Occult Herbmaster", "hit_points":6, "maximum_hit_points":9, "power_uses":2, "power_uses_total":3, "omens":2, "silver":34, "abilities":{"Strength":{"modifier":-1},"Agility":{"modifier":0},"Presence":{"modifier":2},"Toughness":{"modifier":2}}}, true)
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = canvas
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	# Optional local authority artwork is evidence only, never Package content.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--reference-dir="):
			var reference := argument.trim_prefix("--reference-dir=")
			var background := TextureRect.new()
			background.texture = ImageTexture.create_from_image(Image.load_from_file(reference.path_join("scenes/fantasy.png")))
			background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			background.size = canvas
			viewport.add_child(background)
	var hud = load(ROOT + "ui/character_hud.tscn").instantiate()
	hud.sdk = SDK.new(host)
	viewport.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.get_node("Panel").reduced_motion = true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--reference-dir="):
			var portrait := Image.load_from_file(argument.trim_prefix("--reference-dir=").path_join("character-game/assets/graveworm.png"))
			hud.get_node("Bar/Identity/PortraitFrame/Portrait").texture = ImageTexture.create_from_image(portrait)
			hud._layout_portrait()
	return {"host":host,"hud":hud,"viewport":viewport}

func _settle() -> void:
	for frame in 8:
		await get_tree().process_frame

func test_keyboard_enters_leaf_and_returns_to_category(reduced: bool, _test_parameters := [[false], [true]]) -> void:
	var fixture := _open(Vector2i(1024, 768))
	var hud = fixture.hud
	var panel = hud.get_node("Panel")
	panel.reduced_motion = reduced
	await _settle()
	await hud._open_category("Attacks")
	await get_tree().create_timer(1.0).timeout
	var source: SubViewport = panel.get_node("Surface/Viewport")
	assert_object(source.gui_get_focus_owner()).is_same(panel.get_content().get_node("Header/ShowAll"))
	for key in [KEY_TAB, KEY_ENTER]:
		for down in [true, false]:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = down
			fixture.viewport.push_input(event, true)
		await _settle()
	assert_bool(panel.is_open).is_false()
	assert_object(fixture.viewport.gui_get_focus_owner()).is_same(hud.get_node("Bar/Categories/Attacks"))

func _capture(fixture: Dictionary, name: String) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			var path := argument.trim_prefix("--evidence-dir=")
			DirAccess.make_dir_recursive_absolute(path)
			RenderingServer.force_draw(false)
			fixture.viewport.get_texture().get_image().save_png(path.path_join(name+".png"))

func test_resizing_reuses_the_current_sdk_presentation_experience() -> void:
	var fixture := _open(Vector2i(1920, 1080))
	await _settle()
	await fixture.hud._open_category("Abilities")
	fixture.host.device = 2
	fixture.viewport.size = Vector2i(844, 390)
	await _settle()
	assert_bool(fixture.hud._phone).is_true()
	assert_vector(fixture.hud.get_node("Bar").size).is_equal(Vector2(680, 98))
	assert_bool(fixture.hud.get_global_rect().encloses(fixture.hud.get_node("Panel").get_global_rect())).is_true()

func test_resizing_keeps_full_name_detail_until_back() -> void:
	var fixture := _open(Vector2i(844, 390))
	var hud = fixture.hud
	await _settle()
	await hud._open_category("Items")
	var entry := ENTRY.new()
	entry.id = "long-name"
	entry.title = "The forgotten relic of the nameless king ".repeat(20)
	entry.favorite = true
	var entries: Array[ENTRY] = [entry]
	hud.set_entries("Items", entries)
	await _settle()
	hud._rows[0].get_node("FullName").pressed.emit()
	await _settle()
	var content: Control = hud.get_node("Panel").get_content()
	for canvas: Vector2i in [Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(844, 390)]:
		fixture.host.device = 2 if canvas.x == 844 else 1 if canvas.x == 1024 else 0
		fixture.viewport.size = canvas
		await _settle()
		assert_bool(content.get_node("Detail").visible).is_true()
		assert_bool(content.get_node("List").visible).is_false()
		assert_bool(content.get_node("Back").visible).is_true()
		assert_str(content.get_node("Header/Title").text).is_equal("Full name")
		assert_str(content.get_node("Detail/Text").text).is_equal(entry.title)
		assert_bool(hud.get_global_rect().encloses(hud.get_node("Panel").get_global_rect())).is_true()
		await _capture(fixture, str(canvas.x)+"-resized-full-name")
	content.get_node("Back").pressed.emit()
	await _settle()
	assert_bool(content.get_node("Detail").visible).is_false()
	assert_bool(content.get_node("List").visible).is_true()
	assert_str(content.get_node("Header/Title").text).is_equal("Items")

func test_reference_composition_and_bounded_actions(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var hud = fixture.hud
	await _settle()
	var expected: Rect2 = Rect2(82,274,680,98) if width == 844 else Rect2(48,630,928,114) if width == 1024 else Rect2(415,920,1090,136)
	assert_vector(hud.get_node("Bar").position).is_equal(expected.position)
	assert_vector(hud.get_node("Bar").size).is_equal(expected.size)
	var bar: Control = hud.get_node("Bar")
	for button: Control in [hud.get_node("Bar/Dice"),hud.get_node("Bar/Identity")]+hud.get_node("Bar/Categories").get_children():
		if button is Button and button.visible:
			assert_bool(bar.get_global_rect().encloses(button.get_global_rect())).override_failure_message("HUD action leaves the fixed bar: "+str(button.name)).is_true()
			assert_bool(button.size.x >= 44 and button.size.y >= 44).is_true()
	await _capture(fixture, str(width)+"-bar")
	await hud._open_category("Abilities")
	await _settle()
	var panel: Control = hud.get_node("Panel")
	assert_bool(hud.get_global_rect().encloses(panel.get_global_rect())).is_true()
	assert_bool(panel.get_global_rect().intersects(bar.get_global_rect())).is_false()
	assert_float(panel.size.x).is_equal_approx(400.0 if width == 844 else 546.0 if width == 1024 else 548.0, 0.001)
	assert_float(panel.get_global_rect().position.y).is_greater_equal(0.0)
	assert_int(hud.get_node("Panel").get_content().get_node("List").columns).is_equal(2 if width == 844 else 1)
	assert_bool(hud.get_node("Panel").get_content().get_node("Footer").visible).is_false()
	assert_bool(hud.get_node("Panel").get_content().get_node("Header/ShowAll").visible).is_false()
	await _capture(fixture, str(width)+"-abilities")
	assert_vector(bar.position).is_equal(expected.position)
	hud.get_node("Bar/Dice").pressed.emit()
	assert_int(fixture.host.dice_opened).is_equal(1)
	assert_bool(panel.is_open).is_false()

func test_empty_favorites_pagination_and_unavailable_entries(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var hud = fixture.hud
	await _settle()
	await hud._open_category("Items")
	var entries: Array[ENTRY] = []
	for index in 9:
		var entry := ENTRY.new()
		entry.id = "item-%d" % index
		entry.title = "Elixir vitalis %d" % index
		entry.detail = "Healing decoction"
		entry.value = "1 dose"
		entry.icon = load(ROOT+"ui/hud_art/items.svg")
		entry.available = index != 0
		entries.append(entry)
	hud.set_entries("Items",entries)
	await _settle()
	assert_bool(hud.get_node("Panel").get_content().get_node("Empty").visible).is_true()
	assert_str(hud.get_node("Panel").get_content().get_node("Empty/Sheet").text).is_equal("Show all")
	hud.get_node("Panel").get_content().get_node("Empty/Sheet").pressed.emit()
	await _settle()
	assert_int(hud._page_entries.size()).is_equal(2 if width == 844 else 4)
	assert_bool(hud._rows[0].get_node("Launch").disabled).is_true()
	assert_bool(hud._rows[0].get_node("Favorite").disabled).is_false()
	assert_bool(hud.get_node("Panel").get_content().get_node("Footer").visible).is_true()
	assert_bool(hud.get_node("Panel").get_content().get_node("Footer/Previous").disabled).is_true()
	hud.get_node("Panel").get_content().get_node("Footer/Next").pressed.emit()
	await _settle()
	assert_str(hud._page_entries[0].id).is_equal("item-2" if width == 844 else "item-4")
	assert_bool(hud.get_node("Panel").get_content().get_node("Footer/Previous").disabled).is_false()
	assert_bool(hud.get_global_rect().encloses(hud.get_node("Panel").get_global_rect())).is_true()
	await _capture(fixture, str(width)+"-items")
	fixture.host.actors.hero.access_level = "Viewer"
	fixture.host.WorldChanged.emit()
	await _settle()
	assert_bool(hud.visible).is_false()
	assert_bool(hud.get_node("Panel").is_open).is_false()

func test_long_name_pages_and_return_to_list(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var hud = fixture.hud
	await _settle()
	await hud._open_category("Items")
	var entry := ENTRY.new()
	entry.id = "long-name"
	entry.title = "The forgotten relic of the nameless king " .repeat(20)
	entry.favorite = true
	var entries: Array[ENTRY] = [entry]
	hud.set_entries("Items",entries)
	await _settle()
	assert_bool(hud._rows[0].get_node("FullName").visible).is_true()
	hud._rows[0].get_node("FullName").pressed.emit()
	await _settle()
	var detail: Control = hud.get_node("Panel").get_content().get_node("Detail")
	var detail_text: Label = detail.get_node("Text")
	assert_bool(detail.visible).is_true()
	assert_str(hud.get_node("Panel").get_content().get_node("Header/Title").text).is_equal("Full name")
	assert_bool(hud.get_node("Panel").get_content().get_node("Back").visible).is_true()
	assert_bool(hud.get_node("Panel").get_content().get_node("Footer").visible).is_true()
	assert_bool(hud.get_global_rect().encloses(hud.get_node("Panel").get_global_rect())).is_true()
	assert_bool(hud.get_node("Panel").get_global_rect().encloses(_rect_in_fixture(hud, detail))).is_true()
	assert_float(detail.size.y).is_less_equal(detail_text.get_line_height()*(3 if width == 844 else 5))
	await _capture(fixture,str(width)+"-full-name")
	hud.get_node("Panel").get_content().get_node("Footer/Next").pressed.emit()
	assert_float(detail_text.position.y).is_equal(float(-detail_text.get_line_height()*(3 if width == 844 else 5)))
	hud.get_node("Panel").get_content().get_node("Back").pressed.emit()
	await _settle()
	assert_bool(detail.visible).is_false()
	assert_str(hud.get_node("Panel").get_content().get_node("Header/Title").text).is_equal("Items")
	assert_bool(hud.get_node("Panel").get_content().get_node("List").visible).is_true()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	fixture.viewport.push_input(escape,true)
	assert_bool(hud.get_node("Panel").is_open).is_false()
	assert_bool(hud.get_node("Bar/Categories/Items").has_focus()).is_true()
	if width == 844:
		assert_bool(hud.get_node("Bar/Categories/Recovery").visible).is_true()
		hud.get_node("Bar/Categories/Recovery").pressed.emit()
		await _settle()
		assert_str(hud.get_node("Panel").get_content().get_node("Header/Title").text).is_equal("Recovery")
		assert_bool(hud.get_node("Bar/Categories/Recovery").button_pressed).is_true()

func test_russian_header_controls_and_rows_fit_phone() -> void:
	var fixture := _open(Vector2i(844,390),"ru")
	var hud = fixture.hud
	await _settle()
	await hud._open_category("Powers")
	var entry := ENTRY.new()
	entry.id = "scroll-test"
	entry.title = "Кровавый ритуал забытого короля"
	entry.detail = "Нечистый свиток"
	entry.value = "1 / 3"
	entry.favorite = true
	var entries: Array[ENTRY] = [entry]
	hud.set_entries("Powers",entries)
	await _settle()
	var header: Control = hud.get_node("Panel").get_content().get_node("Header")
	for control: Control in [header.get_node("Title"),header.get_node("ShowAll"),header.get_node("Morning"),header.get_node("Close")]:
		assert_bool(header.get_global_rect().encloses(control.get_global_rect())).is_true()
	assert_str(header.get_node("ShowAll").text).is_equal("Все")
	assert_bool(header.get_node("ShowAll").get_global_rect().intersects(header.get_node("Morning").get_global_rect())).is_false()
	await _capture(fixture,"844-russian")

func test_outside_press_reaches_host_controls_and_closes_popup(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var host_button := Button.new()
	host_button.position = Vector2(width-56,64)
	host_button.size = Vector2(44,44)
	fixture.viewport.add_child(host_button)
	fixture.viewport.move_child(host_button, fixture.viewport.get_child_count()-2)
	var clicked := {"count":0}
	host_button.pressed.connect(func(): clicked.count += 1)
	await _settle()
	for touch in [false,true]:
		await fixture.hud._open_category("Abilities")
		await _settle()
		for down in [true,false]:
			var event: InputEvent
			if touch:
				var press := InputEventScreenTouch.new()
				press.position = host_button.get_global_rect().get_center()
				press.pressed = down
				event = press
			else:
				var press := InputEventMouseButton.new()
				press.position = host_button.get_global_rect().get_center()
				press.button_index = MOUSE_BUTTON_LEFT
				press.pressed = down
				event = press
			fixture.viewport.push_input(event,true)
		assert_bool(fixture.hud.get_node("Panel").is_open).is_false()
		assert_int(clicked.count).is_equal(2 if touch else 1)

func test_fallback_portrait_fits_and_hover_is_drawn(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var hud = fixture.hud
	await _settle()
	var portrait: TextureRect = hud.get_node("Bar/Identity/PortraitFrame/Portrait")
	assert_bool(portrait.get_parent().get_global_rect().encloses(portrait.get_global_rect())).override_failure_message("The fallback portrait must fit inside its frame.").is_true()
	await hud._open_category("Attacks")
	hud.get_node("Panel").get_content().get_node("Header/ShowAll").set_pressed(true)
	await _settle()
	var buttons: Array[Button] = [hud.get_node("Bar/Dice"), hud.get_node("Bar/Identity"), hud.get_node("Bar/Categories/Items"), hud.get_node("Panel").get_content().get_node("Header/Close"), hud._rows[0].get_node("Launch"), hud._rows[0].get_node("Favorite")]
	for button in buttons:
		var motion := InputEventMouseMotion.new()
		motion.position = _rect_in_fixture(hud, button).get_center()
		fixture.viewport.push_input(motion, true)
		await _settle()
		assert_int(button.get_draw_mode()).override_failure_message(str(button.get_path())).is_equal(BaseButton.DRAW_HOVER)
		assert_bool(button.flat).override_failure_message("Flat buttons suppress the hover StyleBox: "+str(button.get_path())).is_false()

	var star: Button = hud._rows[0].get_node("Favorite")
	star.set_pressed_no_signal(true)
	await _settle()
	assert_int(star.get_draw_mode()).is_equal(BaseButton.DRAW_HOVER_PRESSED)
	assert_float(star.get_theme_stylebox("pressed").bg_color.a).is_zero()
	assert_bool(star.get_theme_stylebox("hover_pressed").bg_color.a > 0.0).is_true()
	await _capture(fixture, str(width)+"-hover")

func test_use_action_keeps_its_entry_and_favorite_separate() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var hud = fixture.hud
	await _settle()
	await hud._open_category("Items")
	var entry := ENTRY.new()
	entry.id = "owned-waterskin"
	entry.title = "Waterskin"
	entry.value = "Use"
	entry.value_is_action = true
	entry.favorite = true
	var entries: Array[ENTRY] = [entry]
	hud.set_entries("Items", entries)
	await _settle()
	var use: Button = hud._rows[0].get_node("Use")
	assert_bool(use.is_visible_in_tree()).is_true()
	assert_bool(hud._rows[0].get_node("Launch/Content/Value").visible).is_false()
	var requested := []
	hud.entry_requested.connect(func(actor, category, id): requested.append([actor.value, category, id]))
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = _rect_in_fixture(hud, use).get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		fixture.viewport.push_input(event, true)
	assert_int(requested.size()).is_equal(1)
	assert_str(requested[0][1]).is_equal("Items")
	assert_str(requested[0][2]).is_equal("owned-waterskin")

func test_show_all_shared_scene_keeps_padding_and_colors_in_every_state() -> void:
	var fixture := _open(Vector2i(844,390))
	var hud = fixture.hud
	await _settle()
	hud._open_category("Attacks")
	await _settle()
	var all: CheckBox = hud.get_node("Panel").get_content().get_node("Header/ShowAll")
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		assert_bool(all.get_theme_color(state).is_equal_approx(Color(0.682352941, 0.729411765, 0.745098039, 1.0))).is_true()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box: StyleBox = all.get_theme_stylebox(state)
		assert_float(box.get_content_margin(SIDE_LEFT)).is_equal(8.0)
		assert_float(box.get_content_margin(SIDE_RIGHT)).is_equal(8.0)
	all.set_pressed(true)
	await _settle()
	assert_bool(all.button_pressed).is_true()
	assert_bool(all.size.x >= 44 and all.size.y >= 44).is_true()

func _rect_in_fixture(hud: Control, control: Control) -> Rect2:
	var bounds := control.get_global_rect()
	if control.get_viewport() != hud.get_viewport():
		return Rect2(hud.get_node("Panel").global_position+bounds.position*0.5, bounds.size*0.5)
	return bounds
