extends VBoxContainer

const TITLES := ["Class", "Abilities", "Origin & Traits", "Equipment", "Identity", "Review"]

func present_progress(step: int, compact: bool) -> void:
	get_node(^"Wide").visible = not compact
	get_node(^"Compact").visible = compact
	get_node(^"Compact/Label").text = "%d / 6 · %s" % [step, TITLES[step - 1].to_upper()]
	get_node(^"Compact/Track").value = step
	for index in range(6):
		var cell := get_node(^"Wide").get_child(index) as VBoxContainer
		var underline := cell.get_node(^"Underline") as ProgressBar
		underline.visible = index + 1 == step
		var marker := cell.get_node(^"MarkerRow/Circle/Marker") as Label
		var title := cell.get_node(^"Title") as Label
		marker.text = "✓" if index + 1 < step else str(index + 1)
		marker.theme_type_variation = "RookframeValue" if index + 1 <= step else "RookframeMeta"
		title.theme_type_variation = "RookframeValue" if index + 1 <= step else "RookframeMeta"
	accessibility_name = "Step %d of 6: %s" % [step, TITLES[step - 1]]
