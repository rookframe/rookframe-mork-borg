extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/power_composition_boundary.gd")

func test_recovery_panel_eligibility_focus_pending_and_result() -> void:
	var path := ROOT + "ui/health_panel.tscn"
	assert_bool(ResourceLoader.exists(path)).is_true()
	if not ResourceLoader.exists(path):
		return
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data.merge({"hit_points": 4, "maximum_hit_points": 9}, true)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	var scene: PackedScene = load(path)
	var panel = auto_free(scene.instantiate())
	viewport.add_child(panel)
	panel.size = Vector2(351, 260)
	panel.action_created.connect(func(action: Node) -> void: viewport.add_child(action))
	panel.configure(SDK.Actor.new(host.actors.hero), SDK.new(host), "rest")
	await get_tree().process_frame
	var breath: Button = panel.get_node("Columns/Task/Rest/Content/Breath")
	var sleep: Button = panel.get_node("Columns/Task/Rest/Content/Sleep")
	sleep.button_pressed = true
	sleep.pressed.emit()
	assert_bool(breath.button_pressed).is_false()
	assert_object(sleep.icon).is_not_null()
	assert_object(breath.icon).is_null()
	breath.button_pressed = true
	breath.pressed.emit()
	assert_bool(sleep.button_pressed).is_false()
	assert_str(breath.accessibility_description).is_equal("Selected")
	await panel.submit()
	assert_int(host.requests.size()).is_equal(0)
	await get_tree().process_frame
	assert_str(panel.get_node("Outcome").text).contains("eligibility")
	var eligible: Button = panel.get_node("Columns/Context/Content/Eligible")
	assert_bool(eligible.size.y >= 44).is_true()
	eligible.grab_focus()
	assert_bool(eligible.has_focus()).is_true()
	eligible.button_pressed = true
	await panel.submit()
	await get_tree().process_frame
	assert_str(panel.primary_text()).is_equal("Waiting…")
	host.roll(host.last_request, [4])
	await get_tree().create_timer(0.6).timeout
	assert_str(panel.get_node("Result/Content/Copy").text).contains("regained 4 HP")
	assert_bool(panel.get_node("Columns").visible).is_false()
	assert_bool(panel.get_node("Result").is_visible_in_tree()).is_true()
	assert_bool(panel.get_node("Result/Content/Heading").has_focus()).is_true()
	assert_str(panel.primary_text()).is_equal("Done")

func after_test() -> void:
	await get_tree().process_frame

func test_specialty_corrections_refresh_live_fields_and_preserve_other_drafts() -> void:
	var classes = load(ROOT + "logic/creation_classes.gd").new()
	var data := {"class_id": "gutterborn-scum", "name": "Graveworm", "traits": [classes.feature("gutterborn-scum", 1)]}
	var editor = auto_free(load(ROOT + "ui/character_sheet_edit.tscn").instantiate())
	add_child(editor)
	editor.configure(data, [])
	var name_field = _field(editor, "name")
	name_field.get_node("Field").value = "Unsaved name"
	var first_trait = _field(editor, "trait:0:name")
	first_trait.get_node("Field").value = "Unsaved first specialty"
	data.traits.append(classes.feature("gutterborn-scum", 3))
	editor.refresh_data(data)
	assert_str(_field(editor, "trait:1:name").current_value()).is_equal("Abominable gob lobber")
	assert_object(_field(editor, "trait:1:uses")).is_not_null()
	assert_str(name_field.current_value()).is_equal("Unsaved name")
	assert_str(_field(editor, "trait:0:name").current_value()).is_equal("Unsaved first specialty")
	data.traits[1] = classes.feature("gutterborn-scum", 4)
	editor.refresh_data(data)
	assert_str(_field(editor, "trait:1:name").current_value()).is_equal("Escaping fate")
	assert_object(_field(editor, "trait:1:uses")).is_null()
	data.traits.remove_at(1)
	editor.refresh_data(data)
	assert_object(_field(editor, "trait:1:name")).is_null()
	assert_str(name_field.current_value()).is_equal("Unsaved name")
	assert_str(_field(editor, "trait:0:name").current_value()).is_equal("Unsaved first specialty")

func _field(editor: Node, key: String) -> Node:
	for field in editor.get_node("Fields").get_children():
		if field.field == key:
			return field
	return null
