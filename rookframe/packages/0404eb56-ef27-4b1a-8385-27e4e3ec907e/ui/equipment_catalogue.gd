extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
const EQUIPMENT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/equipment.gd")
const ROW_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.gd")
var _rows: Array[ROW_SCRIPT] = []
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_row.tscn")

const TOKENS := &"RookframeTokens"
## Constant token of the gap between rows, `space_1` to `space_8`. Empty means no gap.
@export var gap: StringName = &"space_2":
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

func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)
	get_node(^"Custom").pressed.connect(_custom)
	get_node(^"Search").value_changed.connect(_filter)
func configure(_data: Dictionary, _miniatures: Array) -> void:
	for item in EQUIPMENT.new().entries():
		var row = ROW.instantiate()
		row.localize(i18n)
		get_node(^"Items").add_child(row)
		row.configure(item, true)
		_rows.append(row)
		row.mutation_requested.connect(_add)
	_filter("")
func _filter(query: String) -> void:
	var count := 0
	for row in _rows:
		var item: Dictionary = row.item
		row.visible = query.to_lower() in str(item.get("name", "")).to_lower() or query.to_lower() in _t(str(item.get("name", ""))).to_lower()
		if row.visible:
			count += 1
	get_node(^"Empty").visible = count == 0

func _back() -> void:
	navigate_requested.emit("inventory", "")

func _custom() -> void:
	navigate_requested.emit("custom", "")

func _add(operation: String, arguments: Array) -> void:
	mutation_requested.emit(operation, arguments)


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Back").text = _t("Back to Inventory")
	get_node(^"Custom").text = _t("Create custom item")
	get_node(^"Empty").text = _t("No matching equipment.")
	get_node(^"Heading").text = _t("CORE EQUIPMENT")
	get_node(^"Search").label_text = _t("Search equipment")
