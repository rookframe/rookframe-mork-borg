extends RefCounted
## Icon-only Creature sheet actions: the label moves to the tooltip and the
## accessible name, and the UI Kit button keeps its World theme look.
const ACTION_ICONS := {
	"remove": preload("res://rookframe/ui/icons/remove.svg"),
	"check": preload("res://rookframe/ui/icons/check.svg"),
	"close": preload("res://rookframe/ui/icons/close.svg"),
	"edit": preload("res://rookframe/ui/icons/character/quill.svg"),
	"person-add": preload("res://rookframe/ui/icons/person-add.svg"),
	"add": preload("res://rookframe/ui/icons/add.svg"),
	"back": preload("res://rookframe/ui/icons/back.svg"),
	"info": preload("res://rookframe/ui/icons/info.svg"),
	"chevron-left": preload("res://rookframe/ui/icons/chevron-left.svg"),
	"chevron-right": preload("res://rookframe/ui/icons/chevron-right.svg"),
}
const PRIMARY := 1
const TOKENS := &"RookframeTokens"

func icon_action(button: Button, role: String, primary: bool = false) -> void:
	if not button.text.is_empty():
		button.accessibility_name = button.text
		button.tooltip_text = button.text
	button.text = ""
	# Only the UI Kit button component carries an emphasis variant.
	if primary and &"variant" in button:
		button.variant = PRIMARY
	button.icon = ACTION_ICONS.get(role, ACTION_ICONS["close"])
	bound_icon(button)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

## Pictograms come in several source sizes; the theme's icon size bounds them.
func bound_icon(button: Button) -> void:
	var extent := button.get_theme_constant(&"icon_medium", TOKENS)
	if button.get_theme_constant(&"icon_max_width") != extent:
		button.add_theme_constant_override(&"icon_max_width", extent)
