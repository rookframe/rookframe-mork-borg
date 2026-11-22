extends HBoxContainer
signal favorite_changed(key: String, starred: bool)
const STAR = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_favorite.gd")
const TOKENS := &"RookframeTokens"
## Constant token of the gap between the title and its star. Empty means no gap.
@export var gap: StringName = &"space_3":
	set(value):
		gap = value
		_read_tokens()
var _reading := false
var _key := ""
@onready var _title: Label = get_node(^"Title")
@onready var _star: Button = get_node(^"Favorite")

func _ready() -> void:
	_star.pressed.connect(_changed)

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

func configure(entry: Dictionary, owner: bool, busy: bool) -> void:
	_title.text = str(entry.get("name", "Attack"))
	_key = STAR.configure(_star, entry, owner, busy)

func _changed() -> void:
	favorite_changed.emit(_key, _star.button_pressed)
