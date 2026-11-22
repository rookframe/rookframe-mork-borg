extends VBoxContainer
## One loot entry: a UI Kit action row with the name, the summary and Details.
## Oversized names remain complete native paginated text above the row.
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const TYPE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_type.gd")
var _type := TYPE.new()
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
var page_height := 0.0
var _summary := ""
var _compact := false
var _settling := 0
@onready var _row: Button = get_node("Summary")

func _ready() -> void:
	set_process(false)
	_row.pressed.connect(_details)
	_row.resized.connect(_queue_measure)
	_row.minimum_size_changed.connect(_queue_measure)

func configure(item: Dictionary, locale: I18N, phone: bool, tablet: bool) -> void:
	entry_id = str(item.get("inventory_id", ""))
	var title := str(item.get("name", "Item"))
	if not item.get("custom", false):
		title = locale.text(title)
	_summary = str(item.get("quantity", 1)) + " × " + locale.text(str(item.get("kind", "Item")))
	var row: Button = get_node("Summary")
	row.set(&"title", _summary if _compact else title)
	row.set(&"description", "" if _compact else _summary)
	row.set(&"action_label", locale.text("Details"))
	row.accessibility_name = title + ". " + _summary + ". " + locale.text("Details")
	get_node("FullName").text = title
	_type.apply(get_node("FullName"), "RuleTitle", phone, tablet)

func set_page_height(height: float) -> void:
	page_height = height
	_queue_measure()

# The row wraps its name at the width its Containers assign, so its height is
# read only after the layout has stood still for two frames.
func _queue_measure() -> void:
	if _compact or not is_node_ready():
		return
	_settling = 2
	set_process(true)

func _process(_delta: float) -> void:
	_settling -= 1
	if _settling > 0:
		return
	set_process(false)
	if _compact or page_height <= 0 or _row.size.x <= 1:
		return
	# A row is an indivisible pager item. A name taller than a page moves above
	# the row as complete text, and the row keeps the summary and its action.
	if _row.get_combined_minimum_size().y > page_height:
		_compact = true
		_row.set(&"title", _summary)
		_row.set(&"description", "")
		get_node("FullName").visible = true

func _details() -> void:
	requested.emit("details", entry_id)

func restore_focus(_part: String = "") -> bool:
	if not _row.is_visible_in_tree() or _row.disabled:
		return false
	_row.grab_focus()
	return true
