extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/token_box.gd"
## One side of the encounter strip. The active side's caption takes the World
## theme's `accent` ink and follows a live World theme change.


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_ink()


# Overriding a child's colour does not notify this container again.
func _read_ink() -> void:
	var label := get_node_or_null(^"ActiveSide") as Label
	if label != null and is_inside_tree():
		label.add_theme_color_override(&"font_color", get_theme_color(&"accent", TOKENS))
