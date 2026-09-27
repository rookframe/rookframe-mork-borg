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
	assert_str(_copy(view.get_node("Main/Content/Equipment/Omens"))).contains("1 omen")
	assert_str(_copy(view.get_node("Main/Content/Equipment/Food"))).contains("3 days")
	assert_str(_copy(view.get_node("Main/Content/Equipment/Pack"))).contains("Backpack")

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
