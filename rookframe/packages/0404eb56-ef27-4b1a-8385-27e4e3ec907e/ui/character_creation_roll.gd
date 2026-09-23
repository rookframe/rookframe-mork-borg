extends PanelContainer

const CHECK = preload("res://rookframe/ui/icons/check.svg")
const DICE = preload("res://rookframe/ui/icons/dice.svg")
const SPINNER = preload("res://rookframe/ui/icons/spinner.svg")
const LOCK = preload("res://rookframe/ui/icons/lock.svg")

func present_roll(title: String, formula: String, result: String, state: String, ordinal: int, compact: bool) -> void:
	get_node(^"Row/Identity/Title").text = title
	get_node(^"Row/Identity/Title").set("theme_override_font_sizes/font_size", 14 if compact else 16)
	get_node(^"Row/Identity/Formula").text = formula
	get_node(^"Row/Identity/Formula").set("theme_override_font_sizes/font_size", 12 if compact else 16)
	get_node(^"Row/Result").text = result
	get_node(^"Row/Result").set("theme_override_font_sizes/font_size", 16 if compact else 18)
	get_node(^"Row/Ordinal").text = str(ordinal)
	get_node(^"Row/Ordinal").visible = not compact
	get_node(^"Row/Die").texture = DICE
	get_node(^"Row/Die").visible = not compact
	get_node(^"Row/State").texture = CHECK if state == "complete" else (SPINNER if state == "pending" else (DICE if state == "current" else LOCK))
	custom_minimum_size = Vector2(0, 52 if compact else 64)
	accessibility_name = "%s, %s, %s" % [title, formula, result if state == "complete" else state]
