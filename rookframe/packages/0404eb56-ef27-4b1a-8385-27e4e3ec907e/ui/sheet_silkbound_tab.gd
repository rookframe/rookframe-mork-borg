extends Button
## Chapter tab: the UI Kit tab button with the chapter's pictogram and title.
const SHEET_TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_surface_tokens.gd")
var _title := ""
var _pictogram: Texture2D

func _ready() -> void:
	_remember()

func _remember() -> void:
	if _title.is_empty():
		_title = text
		_pictogram = icon
		accessibility_name = _title

## A narrow canvas shows the title alone; a tab without a title keeps its
## pictogram and names itself in its tooltip.
func configure_layout(font_size: int, icon_size: StringName, titled: bool, pictogram: bool) -> void:
	_remember()
	add_theme_font_size_override("font_size", font_size)
	add_theme_constant_override("icon_max_width", SHEET_TOKENS.pixels(self, icon_size))
	text = _title if titled else ""
	icon = _pictogram if pictogram or not titled else null
	tooltip_text = "" if titled else _title
	size_flags_stretch_ratio = 1.0 if titled else 0.5

func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
