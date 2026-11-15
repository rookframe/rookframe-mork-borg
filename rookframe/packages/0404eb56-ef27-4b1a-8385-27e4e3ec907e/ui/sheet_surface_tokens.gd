extends RefCounted
## Token reads the full-screen sheet's layout scripts share.
##
## Every value comes from the World theme's `RookframeTokens`. The sheet re-runs
## its layout on a World theme change, so each read follows the live theme.

const TYPE := &"RookframeTokens"


static func color(control: Control, token: StringName) -> Color:
	return control.get_theme_color(token, TYPE)


## Pixels of a `space_*`, `icon_*` or other constant token; an empty name is 0.
static func pixels(control: Control, token: StringName) -> int:
	return control.get_theme_constant(token, TYPE) if token else 0


## The font of a type role. The sheet's compact rows trim the line box.
static func font(control: Control, role: StringName, trim_top: int = 0, trim_bottom: int = 0) -> Font:
	var face := control.get_theme_font(role, TYPE)
	if trim_top == 0 and trim_bottom == 0:
		return face
	var trimmed := FontVariation.new()
	trimmed.base_font = face
	trimmed.spacing_top = -trim_top
	trimmed.spacing_bottom = -trim_bottom
	return trimmed


## Gap of a box container: through its token script when it carries one.
static func gap(container: Control, token: StringName) -> void:
	if &"gap" in container:
		container.set(&"gap", token)
	else:
		container.add_theme_constant_override(&"separation", pixels(container, token))


## Gaps of a grid: through its token script when it carries one.
static func grid_gaps(grid: Control, horizontal: StringName, vertical: StringName) -> void:
	if &"gap_horizontal" in grid:
		grid.set(&"gap_horizontal", horizontal)
		grid.set(&"gap_vertical", vertical)
	else:
		grid.add_theme_constant_override(&"h_separation", pixels(grid, horizontal))
		grid.add_theme_constant_override(&"v_separation", pixels(grid, vertical))


## Margins of a MarginContainer whose left edge clears its Button's icon.
static func icon_margins(inset: MarginContainer, button: Button, icon: StringName, icon_gap: StringName, vertical: StringName, right: StringName) -> void:
	button.add_theme_constant_override(&"icon_max_width", pixels(button, icon))
	var left := int(button.get_theme_stylebox(&"normal").content_margin_left) + pixels(button, icon) + pixels(button, icon_gap)
	inset.add_theme_constant_override(&"margin_left", left)
	inset.add_theme_constant_override(&"margin_top", pixels(inset, vertical))
	inset.add_theme_constant_override(&"margin_bottom", pixels(inset, vertical))
	inset.add_theme_constant_override(&"margin_right", pixels(inset, right))
