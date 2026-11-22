extends GdUnitTestSuite
## Two open copies of one surface each keep their own exclusive set. A set
## shared between copies would unpress a choice on the other Character's
## surface; a set copied per control would let two choices stay pressed.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"

func test_exclusive_set_belongs_to_one_open_surface(scene: String, first: String, second: String, _test_parameters := [
		["character_hud", "Bar/Bar/Row/CategorySlot/Abilities", "Bar/Bar/Row/CategorySlot/Attacks"],
		["health_panel", "Scrolls/Choices/Scroll0", "Scrolls/Choices/Scroll1"],
	]) -> void:
	var packed: PackedScene = load(ROOT + "ui/%s.tscn" % scene)
	var one: Control = auto_free(packed.instantiate())
	var other: Control = auto_free(packed.instantiate())
	add_child(one)
	add_child(other)
	(one.get_node(first) as BaseButton).button_pressed = true
	(other.get_node(first) as BaseButton).button_pressed = true
	(one.get_node(second) as BaseButton).button_pressed = true
	assert_bool((one.get_node(first) as BaseButton).button_pressed).is_false()
	assert_bool((one.get_node(second) as BaseButton).button_pressed).is_true()
	assert_bool((other.get_node(first) as BaseButton).button_pressed).is_true()
