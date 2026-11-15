extends VBoxContainer
## Oversized names remain complete native paginated text above a contextual action.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const TYPE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_type.gd")
signal requested(part: String, id: String)
const TOKENS := &"RookframeTokens"
## Constant token of the gap between the parts, `space_1` to `space_8`. Empty means no gap.
@export var gap: StringName = &"":
	set(value):
		gap = value
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
	add_theme_constant_override(&"separation", get_theme_constant(gap, TOKENS) if gap else 0)
	_reading = false

var entry_id := ""

func _ready() -> void:
	get_node("Summary").requested.connect(_requested)
	get_node("Summary").full_name_needed.connect(_show_full_name)

func configure(item: Dictionary, locale: I18N, phone: bool, tablet: bool) -> void:
	entry_id = str(item.get("inventory_id", ""))
	get_node("Summary").configure(item, locale, phone, tablet)
	get_node("FullName").text = get_node("Summary/Padding/Row/Identity/Name").text
	TYPE.apply(get_node("FullName"), "RuleTitle", phone, tablet)

func set_page_height(height: float) -> void:
	get_node("Summary").set_page_height(height)

func _show_full_name() -> void:
	get_node("FullName").visible = true

func _requested(part: String, id: String) -> void:
	requested.emit(part, id)

func restore_focus(part: String = "") -> bool:
	return get_node("Summary").restore_focus(part)
