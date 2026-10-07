extends Button
## Godot owns tooltip timing, positioning, dismissal and lifetime.
var hint_title := ""
var hint_summary := ""

func configure_hint(title: String, summary: String, enabled: bool = true) -> void:
	hint_title = title
	hint_summary = summary
	tooltip_text = title + "\n" + summary if enabled and not summary.is_empty() else ""
	accessibility_description = summary

func _make_custom_tooltip(_for_text: String) -> Object:
	if tooltip_text.is_empty():
		return null
	var content: Control = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_tooltip.tscn").instantiate()
	(content.get_node(^"Title") as Label).text = hint_title
	(content.get_node(^"Summary") as Label).text = hint_summary
	return content
