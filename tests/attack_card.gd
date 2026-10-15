extends GdUnitTestSuite
const CARD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/attack_card.tscn")

func _card():
	var card = auto_free(CARD.instantiate())
	card.theme = preload("res://rookframe/ui/theme/silkbound_theme.tres")
	add_child(card)
	card.identity("Graveworm", "Shortsword", "Melee · Strength · 5 ft")
	return card

func test_ready_outside_and_defence_preserve_primary_action_semantics() -> void:
	var card = _card()
	card.combat("1d20 - 1", "1d4", true)
	card.target("Creature", "4 ft", true, true)
	await await_idle_frame()
	var roll := _button(card, "Prepare attack")
	assert_object(roll).is_not_null()
	assert_bool(roll.disabled).is_false()
	card.combat("1d20 - 1", "1d4", false)
	card.target("Creature", "6 ft", false, true)
	assert_bool(roll.disabled).is_true()
	card.combat("1d20 + 2", "1d6", true, "Defence", true)
	card.show_target(false)
	assert_object(_button(card, "Prepare defence")).is_same(roll)
	assert_bool(roll.disabled).is_false()

func test_consequences_remove_roll_and_target_and_keep_decisions() -> void:
	var card = _card()
	card.combat("1d20", "1d4", true)
	card.target("Creature", "4 ft", true, true)
	card.identity("Graveworm", "Shield", "Small knife", true)
	card.message("Break your shield to prevent all damage from this attack.")
	card.consequence("Take 3 damage", "Break shield")
	await await_idle_frame()
	assert_bool(_button(card, "Prepare attack").is_visible_in_tree()).is_false()
	assert_bool(_button(card, "Choose target").is_visible_in_tree()).is_false()
	assert_bool(_button(card, "Break shield").is_visible_in_tree()).is_true()
	card.identity("Graveworm", "Fumble", "Shortsword")
	card.consequence("Broken", "Lost")
	assert_bool(_button(card, "Lost").is_visible_in_tree()).is_true()
	card.consequence("Done", "")
	assert_bool(_button(card, "Done").is_visible_in_tree()).is_true()

func test_all_form_factors_keep_compact_size_and_44_pixel_actions() -> void:
	var card = _card()
	for device in ["desktop", "tablet", "phone"]:
		card.responsive(device)
		card.combat("1d20 - 1", "1d4", true)
		card.target("Restless dead", "4 ft", true, true)
		await await_idle_frame()
		card.reset_size()
		await await_idle_frame()
		assert_float(card.get_combined_minimum_size().y).is_less_equal(340.0 if device == "desktop" else 260.0)
		for name in ["Prepare attack", "Choose target"]:
			var button := _button(card, name)
			assert_float(button.size.x).is_greater_equal(44.0)
			assert_float(button.size.y).is_greater_equal(44.0)

func _button(node: Node, name: String) -> Button:
	if node is Button and (node.accessibility_name == name or node.text == name):
		return node
	for child in node.get_children():
		var result := _button(child, name)
		if result != null:
			return result
	return null

func test_compact_damage_keeps_a_clear_gap_from_roll_and_uses_right_edge() -> void:
	var card = _card()
	for device in ["tablet", "phone"]:
		card.responsive(device)
		card.combat("1d20 − 1", "d4", true)
		card.reset_size()
		for i in range(5): await await_idle_frame()
		var combat: Control = card.body.get_node("Combat")
		var roll: Control = combat.get_node("Attack/Roll")
		var damage_icon: Control = combat.get_node("Damage/Icon")
		var damage_values: Control = combat.get_node("Damage/Values")
		assert_float(damage_icon.global_position.x - roll.get_global_rect().end.x).is_greater_equal(16.0)
		assert_float(damage_values.get_global_rect().end.x).is_equal_approx(combat.get_global_rect().end.x, 1.0)
