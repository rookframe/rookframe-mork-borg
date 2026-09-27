extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"

func test_phone_overview_has_one_edit_and_inline_omens() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(351, 313)
	add_child(viewport)
	var view = auto_free(load(ROOT + "ui/character_sheet_overview.tscn").instantiate())
	view.theme = load("res://rookframe/ui/theme/rookframe_theme.tres")
	viewport.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	view.configure({"description": "Hu", "class_title": "No Class", "hit_points": 3, "maximum_hit_points": 3, "omens": 1, "silver": 60}, [], true)
	for frame in range(8):
		await get_tree().process_frame
	var edits: Array = view.find_children("Edit", "Button", true, false)
	assert_int(edits.size()).override_failure_message("Exactly one sheet edit control, not a pencil on every stat.").is_equal(1)
	assert_bool(view.find_child("DecreaseOmens", true, false) != null).is_true()
	assert_bool(view.find_child("IncreaseOmens", true, false) != null).is_true()
	assert_bool(view.find_child("OmensAction", true, false) == null).is_true()
	assert_bool(view.get_combined_minimum_size().x <= 351).is_true()

func test_health_has_no_eligibility_or_authorization_widgets() -> void:
	var view = auto_free(load(ROOT + "ui/health_panel.tscn").instantiate())
	add_child(view)
	assert_bool(view.find_child("Eligible", true, false) == null).is_true()
	assert_bool(view.find_child("Authorize", true, false) == null).is_true()

const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/miniature_boundary.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")

func _settle() -> void:
	for frame in range(10):
		await get_tree().process_frame

func test_sheet_at_constrained_sizes(width: int, height: int, language: String, _test_parameters := [[326, 315, "en"], [326, 315, "ru"], [375, 313, "en"], [375, 313, "ru"], [412, 712, "en"], [960, 888, "en"]]) -> void:
	var host := BOUNDARY.new()
	host.language = language
	host.game_master = true
	host.actors.hero.data.merge({"name": "Graveworm", "description": "Hu", "class_title": "No Class", "hit_points": 3, "maximum_hit_points": 3, "omens": 1, "silver": 60, "abilities": {"Agility": {"modifier": 1}, "Toughness": {"modifier": -3}}}, true)
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(width, height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var background: Panel = auto_free(Panel.new())
	background.theme = load("res://rookframe/ui/theme/rookframe_theme.tres")
	background.add_theme_stylebox_override("panel", background.theme.get_stylebox("panel", "RookframePackageInk"))
	viewport.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	sheet.sdk = SDK.new(host)
	viewport.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.opened(SDK.ActorId.new("hero"))
	await _settle()
	for tab: Button in sheet.get_node("Layout/CharacterTabs").get_children():
		var font: Font = tab.get_theme_font("font")
		var text_width := font.get_string_size(tab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tab.get_theme_font_size("font_size")).x
		assert_bool(text_width + tab.get_theme_stylebox("normal").get_minimum_size().x <= tab.size.x).override_failure_message("Tab text must fit in full after safe-area and window-border deductions.").is_true()
	var view: Control = sheet.find_child("CharacterOverview", true, false)
	assert_object(view).is_not_null()
	assert_bool(view.get_global_rect().position.x >= 12 and view.get_global_rect().end.x <= width - 12).is_true()
	assert_bool(view.get_node("Body/Identity").size.y <= 30).override_failure_message("One line of profile must not turn into a giant card.").is_true()
	for key in ["Edit", "DecreaseOmens", "IncreaseOmens"]:
		var button: Button = view.find_child(key, true, false)
		assert_bool(button.size.x == 24 and button.size.y == 24).is_true()
		assert_bool(view.get_global_rect().encloses(button.get_global_rect())).is_true()
		assert_str(button.accessibility_name).is_not_empty()
	var omen_value: Label = view.get_node("Resources/Omens/Padding/Content/Row/Value")
	assert_bool(omen_value.size.x >= 28).is_true()
	assert_int(omen_value.vertical_alignment).is_equal(VERTICAL_ALIGNMENT_CENTER)
	for key in ["DecreaseOmens", "IncreaseOmens"]:
		var button: Button = view.find_child(key, true, false)
		assert_float(button.get_global_rect().get_center().y).is_equal(omen_value.get_global_rect().get_center().y)
	assert_int(view.get_node("Header/Edit").icon_alignment).is_equal(HORIZONTAL_ALIGNMENT_CENTER)
	assert_bool(view.get_node("Abilities").size.y <= 64).is_true()
	assert_bool(view.get_node("Body/Combat/Title").get_global_rect().end.x <= view.get_node("Body/Combat/Equipment").get_global_rect().position.x).override_failure_message("Combat label and equipped item names must not overlap.").is_true()
	var down: Button = view.find_child("DecreaseOmens", true, false)
	var up: Button = view.find_child("IncreaseOmens", true, false)
	down.pressed.emit()
	await _settle()
	assert_int(host.actors.hero.data.omens).is_equal(0)
	assert_bool(down.disabled).is_true()
	assert_str(view.get_node("Resources/Omens/Padding/Content/Row/Value").text).is_equal("0")
	up.pressed.emit()
	await _settle()
	assert_int(host.actors.hero.data.omens).is_equal(1)
	assert_bool(down.disabled).is_false()
	assert_bool(is_instance_valid(view)).override_failure_message("Counter updates retain focus and the existing sheet.").is_true()
	up.grab_focus()
	assert_bool(up.has_focus()).is_true()
	await _capture(viewport, "%s-%dx%d-character" % [language, width, height])
	var character = sheet.find_child("CharacterSheet", true, false)
	for route in ["rest", "improve", "broken"]:
		character._navigate(route, "")
		await _settle()
		var panel: Control = sheet.find_child("HealthPanel", true, false)
		assert_bool(panel.get_combined_minimum_size().x <= width - 24).is_true()
		assert_bool(sheet.get_node("Layout/SheetActions").is_visible_in_tree()).is_true()
		assert_bool(sheet.get_global_rect().encloses(sheet.get_node("Layout/SheetActions").get_global_rect())).is_true()
		await _capture(viewport, "%s-%dx%d-%s" % [language, width, height, route])
	character._navigate("character", "")
	await _settle()
	host.actors.hero.access_level = "Viewer"
	host.WorldChanged.emit()
	await _settle()
	view = sheet.find_child("CharacterOverview", true, false)
	assert_bool(not view.get_node("Header/Edit").visible).is_true()
	assert_bool(view.find_child("IncreaseOmens", true, false).disabled).is_true()
	assert_bool(view.find_child("DecreaseOmens", true, false).disabled).is_true()

func _capture(viewport: SubViewport, name: String) -> void:
	var directory := OS.get_environment("MORK_SHEET_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute(directory)
	assert_int(viewport.get_texture().get_image().save_png(directory.path_join(name + ".png"))).is_equal(OK)

func test_omen_counter_pending_failure_retry_and_read_only() -> void:
	var host = preload("res://tests/creation_sdk_boundary.gd").new()
	host.actors.append({"id": "character", "access_level": "Owner", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "omens": 1, "hit_points": 3, "maximum_hit_points": 3, "inventory": []}})
	var sheet = auto_free(load(ROOT + "ui/character_sheet.tscn").instantiate())
	add_child(sheet)
	var sdk := SDK.new(host)
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(sdk.actors.read(SDK.ActorId.new("character")).actor, "character", "character", miniatures, choices, sdk)
	await _settle()
	var view: Control = sheet.find_child("CharacterOverview", true, false)
	var down: Button = view.find_child("DecreaseOmens", true, false)
	var up: Button = view.find_child("IncreaseOmens", true, false)
	host.defer_update = true
	down.pressed.emit()
	assert_bool(down.disabled and up.disabled).is_true()
	assert_int(host.actors[0].data.omens).is_equal(1)
	host.TabletopCommandCompleted.emit({"requestId": 43, "ok": false, "message": "Save failed"})
	await _settle()
	assert_bool(view.get_node("OmenStatus").visible).is_true()
	assert_str(view.get_node("OmenStatus").text).is_equal("Save failed")
	assert_bool(not down.disabled and not up.disabled).is_true()
	assert_int(host.actors[0].data.omens).is_equal(1)
	down.pressed.emit()
	host.complete_update()
	await _settle()
	assert_int(host.actors[0].data.omens).is_equal(0)
	assert_bool(down.disabled).is_true()
	assert_bool(not view.get_node("OmenStatus").visible).is_true()
