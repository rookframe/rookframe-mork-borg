extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/creature_hud_boundary.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const MODEL = preload(ROOT + "ui/creature_hud_model.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.actors.hero.data = load(ROOT + "content/lich-necromancer.tres").create_data({"name": "The Lich, Tired"})
	host.actors.enemy.data = load(ROOT + "content/bone-bowyer.tres").create_data({})
	host.actors.enemy.access_level = "Owner"
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	return host

func _open(canvas: Vector2i) -> Dictionary:
	var host := _host()
	host.device = 2 if canvas.x == 844 else 1 if canvas.x == 1024 else 0
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = canvas
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var hud = load(ROOT + "ui/creature_hud.tscn").instantiate()
	hud.sdk = SDK.new(host)
	viewport.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.get_node("Panel").reduced_motion = true
	return {"host": host, "hud": hud, "viewport": viewport}

func _settle() -> void:
	for frame in 8:
		await get_tree().process_frame

func _capture(fixture: Dictionary, name: String) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			var path := argument.trim_prefix("--evidence-dir=")
			DirAccess.make_dir_recursive_absolute(path)
			RenderingServer.force_draw(false)
			fixture.viewport.get_texture().get_image().save_png(path.path_join(name + ".png"))

func test_native_hud_keeps_fixed_geometry_and_bounded_panels(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width, height))
	var hud = fixture.hud
	await _settle()
	var expected := Rect2(150,274,544,98) if width == 844 else Rect2(167,630,690,114) if width == 1024 else Rect2(510,920,900,136)
	assert_bool(hud.visible).is_true()
	assert_vector(hud.get_node("Bar").position).is_equal(expected.position)
	assert_vector(hud.get_node("Bar").size).is_equal(expected.size)
	for category in ["Attacks", "Special", "Checks", "Scene", "Hit points"]:
		hud._open_category(category)
		await _settle()
		assert_bool(hud.get_global_rect().encloses(hud.get_node("Panel").get_global_rect())).override_failure_message("%s panel outside %d canvas" % [category, width]).is_true()
		assert_bool(hud.get_node("Panel").get_global_rect().intersects(hud.get_node("Bar").get_global_rect())).is_false()
		await _capture(fixture, "%d-%s" % [width, category.replace(" ", "-")])
		assert_vector(hud.get_node("Bar").size).is_equal(expected.size)
	for button: Control in hud.get_node("Bar/Categories").get_children():
		if not button is Button: continue
		assert_bool(button.size.x >= 44 and button.size.y >= 44).is_true()
	hud._close_panel()
	assert_bool(hud.get_node("Bar/Health").has_focus()).is_true()
	hud.get_node("Bar/Dice").pressed.emit()
	assert_int(fixture.host.dice_opened).is_equal(1)

func test_hp_composition_and_show_all_states_match_design(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width, height))
	var hud = fixture.hud
	await _settle()
	hud._open_category("Attacks")
	await _settle()
	var health: Button = hud.get_node("Bar/Health")
	assert_bool(health.button_pressed).is_false()
	var divider: Control = health.get_node("Divider")
	assert_bool(divider.is_visible_in_tree()).is_false()
	assert_bool(hud.get_node("Bar/Identity").get_global_rect().encloses(health.get_global_rect())).is_true()
	assert_float(health.size.y).is_greater_equal(44.0)
	var all: CheckBox = hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/ShowAll")
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		assert_bool(all.get_theme_color(state).is_equal_approx(hud.MUTED)).override_failure_message("Show all %s must use secondary text" % state).is_true()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box: StyleBox = all.get_theme_stylebox(state)
		assert_float(box.get_content_margin(SIDE_LEFT)).override_failure_message("Show all %s left content inset" % state).is_greater_equal(8.0)
		assert_float(box.get_content_margin(SIDE_RIGHT)).override_failure_message("Show all %s right content inset" % state).is_greater_equal(8.0)
	all.set_pressed(true)
	await _settle()
	await _capture(fixture, "%d-show-all-selected" % width)
	hud._open_category("Hit points")
	await _settle()
	assert_bool(health.button_pressed).is_true()
	assert_float((health.get_theme_stylebox("pressed") as StyleBoxFlat).bg_color.a).is_less_equal(0.25)
	var current: Label = hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Header/CurrentHP")
	assert_bool(current.is_visible_in_tree()).is_true()
	assert_str(current.text).is_equal("15 / 15 HP")
	assert_float(current.size.x).is_greater_equal(65.0)
	assert_bool(hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Header").get_global_rect().encloses(current.get_global_rect())).is_true()
	assert_float(hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/Amount").size.x).is_equal(80.0 if width == 844 else 96.0)
	for operation in ["damage", "heal", "set"]:
		var button: Button = hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/" + operation)
		assert_bool(button.has_node("Icon")).override_failure_message("HP action must include its approved pictogram").is_true()
		assert_str(button.get_node("Preview").text).contains("15 → ")
	await _capture(fixture, "%d-health-design" % width)
	hud._close_panel()
	assert_bool(health.button_pressed).is_false()

func test_health_action_stays_clear_of_the_stepped_edge(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	await _settle()
	var identity: Control = fixture.hud.get_node("Bar/Identity")
	var health: Control = fixture.hud.get_node("Bar/Health")
	assert_bool(identity.get_global_rect().encloses(health.get_global_rect())).is_true()
	assert_float(identity.get_global_rect().end.x-health.get_global_rect().end.x).is_greater_equal(38.0)
	assert_float(identity.get_global_rect().end.y-health.get_global_rect().end.y).is_greater_equal(6.0)
	await _capture(fixture, "%d-closed" % width)

func test_leaf_focus_reaches_native_health_and_search_fields(reduced: bool, _test_parameters := [[false],[true]]) -> void:
	var fixture := _open(Vector2i(1024,768))
	var hud = fixture.hud
	var panel = hud.get_node("Panel")
	panel.reduced_motion = reduced
	await _settle()
	for category in ["Hit points", "Scene"]:
		hud._open_category(category)
		await get_tree().create_timer(1.0).timeout
		var field: LineEdit = panel.get_content().get_node("Health/Amount" if category == "Hit points" else "Search")
		assert_object(field.get_viewport().gui_get_focus_owner()).is_same(field)
		var event := InputEventKey.new()
		event.keycode = KEY_2
		event.unicode = 50
		event.pressed = true
		fixture.viewport.push_input(event, true)
		await _settle()
		assert_str(field.text).contains("2")
		hud._close_panel()
		await _settle()
		assert_bool(panel.get_node("Bindings").is_visible_in_tree()).is_true()

func test_resizing_preserves_creature_panel_and_refreshes_experience() -> void:
	var fixture := _open(Vector2i(1920,1080))
	await _settle()
	fixture.hud._open_category("Scene")
	for canvas in [Vector2i(844,390),Vector2i(1024,768),Vector2i(1920,1080)]:
		fixture.host.device = 2 if canvas.x == 844 else 1 if canvas.x == 1024 else 0
		fixture.viewport.size = canvas
		await _settle()
		assert_bool(fixture.hud._phone).is_equal(canvas.x == 844)
		assert_bool(fixture.hud._tablet).is_equal(canvas.x == 1024)
		assert_bool(fixture.hud.get_node("Panel").is_open).is_true()
		assert_bool(fixture.hud.get_global_rect().encloses(fixture.hud.get_node("Panel").get_global_rect())).is_true()

func test_special_announces_once_without_rule_effects_and_validates_current_actor() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var before := host.actors.duplicate(true)
	var request := {"id": "special-one", "actor": "hero", "entry": "scroll-theft"}
	var result := await sdk.system_actions.submit("creature-hud.special", request)
	assert_bool(result.value.ok).is_true()
	assert_int(host.reports.size()).is_equal(1)
	assert_int(host.announcements.size()).is_equal(1)
	assert_str(host.reports[0].text[0].text).is_equal("The Lich, Tired uses Scroll theft")
	await sdk.system_actions.submit("creature-hud.special", request)
	assert_int(host.reports.size()).is_equal(1)
	assert_int(host.announcements.size()).is_equal(1)
	assert_str(host.announcements[0].caption).is_equal("Uses Scroll theft")
	assert_int(host.announcements[0].logSequence).is_equal(1)
	assert_array(host.announcements[0].results).is_empty()
	assert_dict(host.actors).is_equal(before)
	assert_dict(host.requests).is_empty()
	request.id = "special-two"
	request.entry = "made-up"
	result = await sdk.system_actions.submit("creature-hud.special", request)
	assert_bool(result.value.ok).is_false()
	request.entry = "scroll-theft"
	host.actors.hero.access_level = "Read"
	result = await sdk.system_actions.submit("creature-hud.special", request)
	assert_bool(result.value.ok).is_false()
	host.actors.hero.access_level = "Owner"
	host.actors.hero.data.hit_points = 0
	result = await sdk.system_actions.submit("creature-hud.special", request)
	assert_bool(result.value.ok).is_false()
	host.actors.hero.data.hit_points = 10
	host.session = "expired"
	result = await sdk.system_actions.submit("creature-hud.special", request)
	assert_bool(result.value.ok).is_false()
	assert_int(host.reports.size()).is_equal(1)
	assert_int(host.announcements.size()).is_equal(1)

func test_hp_set_keeps_signed_uncapped_values_and_retries_do_not_rewind_newer_hp() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var actions := ACTIONS.new(sdk, SDK.ActorId.new("hero"))
	var result := await actions.adjust_health("set-negative", "set", "-15")
	assert_bool(result.ok).is_true()
	assert_int(host.actors.hero.data.hit_points).is_equal(-15)
	result = await actions.adjust_health("set-over", "set", "900")
	assert_bool(result.ok).is_true()
	assert_int(host.actors.hero.data.hit_points).is_equal(900)
	await actions.adjust_health("set-negative", "set", "-15")
	assert_int(host.actors.hero.data.hit_points).is_equal(900)
	for invalid in ["", "1.5", "9223372036854775808"]:
		result = await actions.adjust_health("invalid-" + invalid, "set", invalid)
		assert_bool(result.ok).is_false()
	assert_int(host.actors.hero.data.hit_points).is_equal(900)

func test_scene_selection_and_local_favorites_preserve_actor_target_and_action_identity() -> void:
	var fixture := _open(Vector2i(844,390))
	var hud = fixture.hud
	var host: BOUNDARY = fixture.host
	await _settle()
	var before := host.actors.duplicate(true)
	var targets := host.targets.duplicate()
	hud._open_category("Attacks")
	var attack: String = hud._page_entries[0].id
	hud._launch_row(0)
	assert_dict(host.tasks[0]).is_equal({"actor": "hero", "task": {"item": "creature:" + attack, "mode": "attack"}})
	hud._open_category("Attacks")
	hud._favorite_row(false, 0)
	assert_dict(host.actors).is_equal(before)
	assert_bool(host.preferences.is_empty()).is_false()
	var restored := MODEL.new()
	restored.sdk = SDK.new(host)
	restored.load_preferences()
	assert_bool(restored.entries(host.actors.hero.data, "Attacks", false)[0].favorite).is_false()
	hud._open_category("Scene")
	for entry in hud._page_entries:
		assert_bool(entry.detail in ["", "Selected"]).override_failure_message("Scene rows must not include locations or coordinates").is_true()
	hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Search").text = "Bowyer"
	hud._search_changed("Bowyer")
	assert_int(hud._page_entries.size()).is_equal(1)
	hud._launch_row(0)
	assert_str(host.selected_rook).is_equal("enemy-rook")
	assert_str(hud._actor.value).is_equal("enemy")
	assert_array(Array(host.targets)).is_equal(Array(targets))
	assert_dict(host.actors).is_equal(before)
	hud._open_category("Special")
	hud._launch_row(0)
	await _settle()
	assert_str(host.reports[0].text[0].text).is_equal("The Bone Bowyer uses Ambush")
	hud._open_category("Hit points")
	hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/Amount").text = "-3"
	hud._amount_changed("-3")
	assert_bool(hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/damage").disabled).is_true()
	assert_bool(hud.get_node("Panel/Surface/Viewport/Root/Ink/Content/Health/set").disabled).is_false()
	host.defer_reply = true
	hud._adjust_hp("set")
	host.SelectRook("hero-rook")
	host.complete_reply()
	await _settle()
	assert_int(host.actors.enemy.data.hit_points).is_equal(-3)
	assert_dict(host.actors.hero).is_equal(before.hero)

func test_generic_checks_capture_raw_physical_roll_without_actor_or_target_changes() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var before := host.actors.duplicate(true)
	for part in ["test", "reaction", "initiative"]:
		var id: String = "check-" + part
		var result := await sdk.system_actions.submit("creature-roll.start", {"id": id, "source": "hero", "part": part, "entry": ""})
		assert_str(result.value.state).is_equal("pending")
		host.roll(id, [3,4] if part == "reaction" else [4])
		result = await sdk.system_actions.submit("creature-roll.advance", {"id": id})
		assert_str(result.value.state).is_equal("resolved")
		assert_int(result.value.total).is_equal(7 if part == "reaction" else 4)
	assert_dict(host.actors).is_equal(before)
	assert_int(host.reports.size()).is_equal(3)

func test_shared_hud_switches_between_creature_character_and_no_selection() -> void:
	var host := _host()
	var character: Dictionary = BOUNDARY.new().actors.hero.data.duplicate(true)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var hud = load(ROOT + "ui/actor_hud.tscn").instantiate()
	hud.sdk = SDK.new(host)
	viewport.add_child(hud)
	await _settle()
	var creature: Control = hud.get_node("CreatureHud")
	var hero: Control = hud.get_node("CharacterHud")
	assert_bool(hud.visible and creature.visible and not hero.visible).is_true()
	host.actors.hero.data = character
	host.emit_signal("CharacterHudContextChanged")
	await _settle()
	assert_bool(hud.visible and hero.visible and not creature.visible).is_true()
	host.hud_actor = ""
	host.emit_signal("CharacterHudContextChanged")
	await _settle()
	assert_bool(hud.visible).is_false()
	host.hud_actor = "enemy"
	host.emit_signal("CharacterHudContextChanged")
	await _settle()
	assert_bool(hud.visible and creature.visible and not hero.visible).is_true()

func test_scene_names_use_measured_three_line_rows_on_every_page(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	for index in range(12):
		var id := "roster-%02d" % index
		var data: Dictionary = load(ROOT+"content/bone-bowyer.tres").create_data({"name": "Bone Bowyer %02d, guardian of the northern catacombs" % index})
		fixture.host.actors[id] = {"id": id, "access_level": "Owner", "public_label": "", "data": data}
		fixture.host.rooks[id+"-rook"] = id
	await _settle()
	fixture.hud._open_category("Checks")
	fixture.hud._launch_row(0)
	await _settle()
	assert_bool(fixture.hud._roll.pending).is_true()
	fixture.hud._open_category("Scene")
	for page in range(3):
		await _settle()
		var layout_errors: Array[String] = []
		# A pending check refreshes the HUD every quarter second. Names must remain
		# fully laid out between refreshes, not flicker or cross their separator.
		for sample in range(10):
			await get_tree().create_timer(0.05).timeout
			for row in fixture.hud._rows:
				if not row.visible: continue
				var title: Label = row.get_node("Launch/Content/Copy/Title")
				if title.get_visible_line_count() != mini(3,title.get_line_count()) or not row.get_global_rect().encloses(title.get_global_rect()):
					if not title.text in layout_errors: layout_errors.append(title.text)
		assert_array(layout_errors).override_failure_message("Page %d names must stay readable inside their rows during a pending roll: %s" % [page,layout_errors]).is_empty()
		await _capture(fixture, "%d-long-scene-%d" % [width,page])
		fixture.hud._change_page(1)
	await fixture.hud._roll._action.cancel()
	await _settle()
