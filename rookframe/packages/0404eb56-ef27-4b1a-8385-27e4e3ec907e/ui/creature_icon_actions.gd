extends RefCounted
const ACTION_ICONS := {
	"remove": preload("res://rookframe/ui/icons/remove.svg"),
	"check": preload("res://rookframe/ui/icons/check.svg"),
	"close": preload("res://rookframe/ui/icons/close.svg"),
	"edit": preload("res://rookframe/ui/icons/edit.svg"),
	"person-add": preload("res://rookframe/ui/icons/person-add.svg"),
	"add": preload("res://rookframe/ui/icons/add.svg"),
	"back": preload("res://rookframe/ui/icons/back.svg"),
	"info": preload("res://rookframe/ui/icons/info.svg"),
	"chevron-left": preload("res://rookframe/ui/icons/chevron-left.svg"),
	"chevron-right": preload("res://rookframe/ui/icons/chevron-right.svg"),
}

func icon_action(button: Button, role: String, primary: bool = false) -> void:
	if not button.text.is_empty():
		button.accessibility_name = button.text
		button.tooltip_text = button.text
	button.text = ""
	button.theme_type_variation = "SilkPrimaryIcon" if primary else "SilkIcon"
	button.icon = ACTION_ICONS.get(role, ACTION_ICONS["close"])
	button.icon_alignment = 1
	button.custom_minimum_size = Vector2(44,44)
	button.size_flags_horizontal = 8
	button.size_flags_vertical = 4


