extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"

func test_pending_roll_indicator_keeps_moving() -> void:
	var row = auto_free(load(ROOT + "ui/character_creation_roll.tscn").instantiate())
	add_child(row)
	row.present_roll("Omens", "1d2", "Rolling…", "pending", 2, true)
	await get_tree().process_frame
	var before: float = row.get_node("Row/State").rotation
	await get_tree().create_timer(0.15).timeout
	assert_float(row.get_node("Row/State").rotation).is_not_equal(before)

func test_equipment_results_have_meaning_before_remaining_rolls() -> void:
	var view = auto_free(load(ROOT + "ui/character_creation_view.tscn").instantiate())
	add_child(view)
	view.present_creation("create-equipment", {
		"equipment_roll_pending": true, "roll_ready": true, "active_roll": "Equipment first",
		"equipment_rolls": {"Silver": 6, "Omens": 1, "Food": 3, "Equipment pack": 3}
	}, true)
	var choices = view.get_node("Layout/Body/StageSlot/Stage/Content/Split/Left/Choices")
	for result in [["Omens", "1 omen"], ["Food", "3 days"], ["Equipment pack", "Backpack"]]:
		choices.selected.emit(result[0])
		var detail = view.get_node("Layout/Body/StageSlot/Stage/Content/Split/Detail/Content/Result")
		assert_bool(detail.is_visible_in_tree()).is_true()
		assert_str(_copy(detail)).contains(result[1])

func test_fixed_pack_does_not_offer_a_choice_button() -> void:
	var view = auto_free(load(ROOT + "ui/character_creation_view.tscn").instantiate())
	add_child(view)
	view.present_creation("create-equipment", {
		"pack": "Backpack", "equipment_rolls": {"Equipment pack": 3},
		"inventory": [{"name": "Backpack", "source_item_id": "backpack"}]
	}, true)
	for button in view.find_children("*", "Button", true, false):
		if button.is_visible_in_tree():
			assert_str(button.text).not_contains("Pack:")
	assert_str(_copy(view)).not_contains("Choose from the packs")

func _copy(root: Node) -> String:
	var text := ""
	for label in root.find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			text += label.text + "\n"
	return text

func test_completed_conditional_results_remain_selectable_with_raw_faces() -> void:
	var view = auto_free(load(ROOT + "ui/character_creation_view.tscn").instantiate())
	add_child(view)
	var draft := {"equipment_rolls": {"Hermit scroll family": 1, "Hermit scroll": 2, "Red poison doses": 3, "Dog hit points": 4}, "roll_faces": {"Hermit scroll": [2], "Red poison doses": [3], "Dog hit points": [4]}, "roll_formulas": {"Hermit scroll": "1d10", "Red poison doses": "1d4", "Dog hit points": "1d6"}}
	view.present_creation("create-equipment", draft, false)
	var choices = view.get_node(view.LEFT + "/Choices")
	for result in [["Hermit scroll", "Grace for a sinner"], ["Red poison doses", "3"], ["Dog hit points", "6"]]:
		var found := false
		for button in choices.get_node("Area/Rows").get_children():
			if button.accessibility_name.begins_with(result[0] + "."):
				found = true
				button.pressed.emit()
		assert_bool(found).is_true()
		assert_str(_copy(view.get_node(view.DETAIL + "/Result"))).contains(result[1]).contains("Rolled:")
	await get_tree().process_frame

func test_origin_detail_contains_only_the_selected_resolved_trait() -> void:
	var view = auto_free(load(ROOT + "ui/character_creation_view.tscn").instantiate())
	add_child(view)
	view.present_creation("create-origin", {"class_id": "occult-herbmaster", "first_decoction_roll": 1, "second_decoction_roll": 4, "roll_faces": {"First decoction": [1], "Second decoction": [4]}}, false)
	view.get_node(view.LEFT + "/Choices").selected.emit("First decoction")
	var copy := _copy(view.get_node(view.DETAIL))
	assert_str(copy).contains("Red poison").contains("Toughness DR12").contains("Rolled: 1").not_contains("Elixir vitalis")
	view.get_node(view.LEFT + "/Choices").selected.emit("Second decoction")
	copy = _copy(view.get_node(view.DETAIL))
	assert_str(copy).contains("Elixir vitalis").contains("Heals d6").contains("Rolled: 4").not_contains("Red poison")
	await get_tree().process_frame
