extends RefCounted
## Token reads the full-screen sheet's layout scripts share.
##
## Every value comes from the World theme's `RookframeTokens`. The sheet re-runs
## its layout on a World theme change, so each read follows the live theme.

const TYPE := &"RookframeTokens"


func color(control: Control, token: StringName) -> Color:
	return control.get_theme_color(token, TYPE)


## Pixels of a `space_*`, `icon_*` or other constant token; an empty name is 0.
func pixels(control: Control, token: StringName) -> int:
	return control.get_theme_constant(token, TYPE) if token else 0

