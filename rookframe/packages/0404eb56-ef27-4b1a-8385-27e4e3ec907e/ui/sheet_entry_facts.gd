extends GridContainer
const FRAME = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/token_frame.gd")
const BOX = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/token_box.gd")
const TOKENS := &"RookframeTokens"
## Constant token of the gap between columns. Empty means no gap.
@export var gap_horizontal: StringName = &"space_5":
	set(value):
		gap_horizontal = value
		_read_tokens()
## Constant token of the gap between rows. Empty means no gap.
@export var gap_vertical: StringName = &"space_4":
	set(value):
		gap_vertical = value
		_read_tokens()
var _reading := false

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_read_tokens()

# Setting an override notifies this Control of a theme change, so the read
# guards against re-entering itself.
func _read_tokens() -> void:
	if _reading or not is_inside_tree():
		return
	_reading = true
	add_theme_constant_override(&"h_separation", get_theme_constant(gap_horizontal, TOKENS) if gap_horizontal else 0)
	add_theme_constant_override(&"v_separation", get_theme_constant(gap_vertical, TOKENS) if gap_vertical else 0)
	_reading = false

func configure(facts: Array, phone: bool) -> void:
	for raw in facts:
		var fact: Array = raw
		# Each fact sits on its own hairline.
		var frame: PanelContainer = FRAME.new()
		frame.size_flags_horizontal = 3
		frame.fill = &""
		frame.outline = &"divider"
		frame.outline_sides = 8
		frame.padding_horizontal = &""
		frame.padding_vertical = &"space_2"
		add_child(frame)
		var lane := BOX.new()
		lane.vertical = true
		lane.size_flags_horizontal = 3
		lane.gap = &"space_1"
		frame.add_child(lane)
		var caption := Label.new()
		caption.text = str(fact[0])
		caption.autowrap_mode = 3
		caption.theme_type_variation = &"RookframeMeta"
		caption.add_theme_font_size_override("font_size", 12 if phone else 15)
		lane.add_child(caption)
		var value := Label.new()
		value.text = str(fact[1])
		value.autowrap_mode = 3
		value.theme_type_variation = &"RookframeValue"
		value.add_theme_font_size_override("font_size", 20 if phone else 22)
		lane.add_child(value)
