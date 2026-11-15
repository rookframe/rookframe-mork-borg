extends "res://rookframe/sdk/window.gd"
## Creature Play HUD: the UI Kit HUD bar with the selected Creature's identity,
## four category tiles, a hit point action and one attached panel above the bar.
##
## Every look comes from the World theme: UI Kit components, `Rookframe*`
## variations and `RookframeTokens` spacing.

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const TOKENS := &"RookframeTokens"
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW = preload("res://rookframe/ui/components/data/structured_row.tscn")
const ACTION = preload("res://rookframe/ui/components/actions/button.tscn")
const FAVORITE = preload("res://rookframe/ui/components/forms/favorite_toggle.tscn")
const MODEL = preload(ROOT + "ui/creature_hud_model.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const REQUEST = preload(ROOT + "logic/action_request.gd")
const ROLL = preload(ROOT + "ui/creature_hud_roll.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const SHEET: SDK.ExtensionSurface = preload(ROOT + "ui/creature_surface.tres")
const ATTACK: SDK.ExtensionSurface = preload(ROOT + "ui/tabletop_attack_surface.tres")
const CREATURE_CATEGORIES := ["Attacks", "Special", "Checks", "Scene"]
const LAUNCH_ICONS := {
	"Attacks": preload("res://rookframe/ui/icons/swords.svg"),
	"Special": preload("res://rookframe/ui/icons/sigil.svg"),
	"Checks": preload("res://rookframe/ui/icons/dice.svg"),
	"Scene": preload("res://rookframe/ui/icons/crosshair.svg"),
}
## Rows on one page of the attached panel.
const PAGE_ROWS := 4
const PAGE_ROWS_PHONE := 2
## Width of the attached panel; a layout breakpoint, not a themed size.
const PANEL_WIDTH := 510.0
const PANEL_WIDTH_TABLET := 460.0
## A phone is wide and short, so its panel spends width instead of height.
const PANEL_WIDTH_PHONE := 720.0
const SEARCH_WIDTH_PHONE := 200.0
const SLOT := "Hud/AttachedPanel/AttachedSlot/Panel/"
var _model := MODEL.new()
var _roll: ROLL
var _actor: SDK.ActorId
var _rook: SDK.RookId
var _data: Dictionary = {}
var _category := ""
var _phone := false
var _tablet := false
var _open := false
var _panel_anchor: Button
var _rows: Array[Control] = []
var _page := 0
var _page_rows := PAGE_ROWS
var _show_all := false
var _page_entries: Array[ENTRY] = []
var _hp_pending := false
var _special_pending := false
var _hp_request: Dictionary = {}
var _special_request: Dictionary = {}
var _render_queued := false
@onready var _hud: Control = get_node("Hud")
@onready var _bar: Control = get_node("Hud/Bar")
@onready var _panel: Control = get_node("Hud/AttachedPanel/AttachedSlot/Panel")
@onready var _list: Container = get_node(SLOT + "List")
@onready var _identity: Button = get_node("Hud/Bar/Row/IdentitySlot/Identity")
@onready var _health: Button = get_node("Hud/Bar/Row/TrailingSlot/Health")
@onready var _amount: LineEdit = get_node(SLOT + "Health/Stepper/Amount")
@onready var _search: Control = get_node(SLOT + "Search")
@onready var _health_editor: Control = get_node(SLOT + "Health")
@onready var _stepper: Control = get_node(SLOT + "Health/Stepper")
@onready var _minus: Button = get_node(SLOT + "Health/Stepper/Minus")
@onready var _plus: Button = get_node(SLOT + "Health/Stepper/Plus")
@onready var _actions: Control = get_node(SLOT + "Header/TitleRow/ActionsSlot")

func _init() -> void:
	visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_layout()

func ready() -> void:
	if sdk == null:
		visible = false
		return
	_phone = sdk.presentation_experience().is_phone
	_tablet = sdk.presentation_experience().is_tablet
	_model.sdk = sdk
	_model.load_preferences()
	var roll := ROLL.new()
	roll.sdk = sdk
	add_child(roll)
	_roll = roll
	_roll.changed.connect(_refresh)
	for index in range(PAGE_ROWS):
		var row := ROW.instantiate()
		row.compact_width = 360.0
		_list.add_child(row)
		_rows.append(row)
		var launch: Button = ACTION.instantiate()
		launch.name = "Launch"
		launch.compact = true
		launch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.get_action_slot().add_child(launch)
		launch.pressed.connect(_launch_row.bind(index))
		var favorite: CheckBox = FAVORITE.instantiate()
		favorite.name = "Favorite"
		favorite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.get_action_slot().add_child(favorite)
		favorite.toggled.connect(_favorite_row.bind(index))
	sdk.character_hud.context_changed.connect(_refresh)
	sdk.world_changed.connect(_refresh)
	resized.connect(_resized)
	_hud.resized.connect(_fit_rows)
	var dice: Button = get_node("Hud/Bar/Row/LeadingSlot/Dice")
	dice.pressed.connect(_open_dice)
	_name(dice, sdk.translations.text("Dice"))
	_identity.pressed.connect(_open_sheet)
	_health.pressed.connect(_open_category.bind("Hit points"))
	_health.title = sdk.translations.text("HP")
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Close").pressed.connect(_close_panel)
	var all: CheckBox = get_node(SLOT + "Header/TitleRow/ActionsSlot/ShowAll")
	all.toggled.connect(_toggle_all)
	all.text = sdk.translations.text("Show all")
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Previous").pressed.connect(_change_page.bind(-1))
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Next").pressed.connect(_change_page.bind(1))
	_search.value_changed.connect(_search_changed)
	_search.label_text = sdk.translations.text("Find a creature…")
	_search.placeholder = sdk.translations.text("Find a creature…")
	_amount.text_changed.connect(_amount_changed)
	_amount.accessibility_name = sdk.translations.text("Amount")
	get_node(SLOT + "Health/Stepper/AmountLabel").text = sdk.translations.text("Amount")
	get_node(SLOT + "Health/Stepper/Minus").pressed.connect(_step_amount.bind(-1))
	get_node(SLOT + "Health/Stepper/Plus").pressed.connect(_step_amount.bind(1))
	for operation in ["damage", "heal", "set"]:
		var button: Button = get_node(SLOT + "Health/Actions/" + operation)
		button.pressed.connect(_adjust_hp.bind(operation))
		button.text = sdk.translations.text(button.text)
	for category in CREATURE_CATEGORIES:
		var button: Button = _tile(category)
		button.pressed.connect(_open_category.bind(category))
		button.text = sdk.translations.text(category)
		_name(button, button.text)
	for path in ["Header/TitleRow/ActionsSlot/Close", "Header/TitleRow/ActionsSlot/Previous", "Header/TitleRow/ActionsSlot/Next", "Health/Stepper/Minus", "Health/Stepper/Plus"]:
		var button: Button = get_node(SLOT + path)
		_name(button, sdk.translations.text(button.accessibility_name))
	_layout()
	_refresh()

func _tile(category: String) -> Button:
	return get_node("Hud/Bar/Row/CategorySlot/" + category)

## An icon-only action carries the same words as its tooltip and accessible name.
func _name(button: Control, words: String) -> void:
	button.tooltip_text = words
	button.accessibility_name = words

## The bar keeps one spacing step clear of the canvas edge; the attached panel
## keeps one width so its rows do not reflow between categories.
func _layout() -> void:
	if not is_node_ready():
		return
	var edge := _edge()
	_hud.offset_top = -edge
	_hud.offset_bottom = -edge
	var width := PANEL_WIDTH_PHONE if _phone else PANEL_WIDTH_TABLET if _tablet else PANEL_WIDTH
	_panel.custom_minimum_size = Vector2(minf(width, size.x - edge * 2), 0)
	_page_rows = PAGE_ROWS_PHONE if _phone else PAGE_ROWS
	_place_tools()

## The search field and the amount stepper each have a line of their own under
## the header; a phone has no height for that line, so there they join the
## header's actions and the stepper drops its visible caption.
func _place_tools() -> void:
	_place(_search, _actions if _phone else _panel, 0 if _phone else 1)
	_place(_stepper, _actions if _phone else _health_editor, 0)
	_search.custom_minimum_size.x = SEARCH_WIDTH_PHONE if _phone else 0.0
	_search.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _phone else Control.SIZE_FILL
	_stepper.get_node(^"AmountLabel").visible = not _phone

func _place(tool: Control, home: Node, index: int) -> void:
	if tool.get_parent() != home:
		tool.reparent(home, false)
		home.move_child(tool, index)

func _edge() -> int:
	return get_theme_constant(&"space_2" if _phone else &"space_5", TOKENS)

## Rows grow with wrapped names and with the theme's type scale, so a page
## gives up rows until the attached panel stands inside the canvas.
func _fit_rows() -> void:
	if _open and _page_rows > 1 and _hud.position.y < _edge():
		var first := _page * _page_rows
		_page_rows -= 1
		_page = first / _page_rows
		_render_panel()

func _refresh() -> void:
	var context := sdk.character_hud.context()
	if not context.ok and context.code in ["not_ready", "operation_in_progress"]:
		return
	var source: SDK.ActorResult = sdk.actors.read(context.actor) if context.ok and context.actor != null else null
	if source != null and not source.ok and source.code in ["not_ready", "operation_in_progress"]:
		return
	if source == null or not source.ok or source.actor == null or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		_actor = null
		_rook = null
		_data = {}
		_close_panel()
		visible = false
		return
	var accepted: Dictionary = source.actor.data
	if str(accepted.get("schema", "")) != "mork-borg-adversary/v1":
		_actor = null
		_rook = null
		_data = {}
		_close_panel()
		visible = false
		return
	if _actor == null or _actor.value != source.actor.id.value or (_rook.value if _rook != null else "") != (context.rook.value if context.rook != null else ""):
		_close_panel()
		_hp_request = {}
		_special_request = {}
	_actor = source.actor.id
	_rook = context.rook
	_data = CREATURES.new().stat_block(accepted)
	var name := str(_data.get("name", "Creature"))
	var armor: Dictionary = _data.get("armor", {})
	_identity.title = name
	_identity.detail = str(armor.get("name", "")) + (" −" + str(armor.reduction) if not str(armor.get("reduction", "")).is_empty() else "")
	_identity.portrait = _model.portrait(_data)
	_identity.tooltip_text = name
	_identity.accessibility_name = name + " · " + sdk.translations.text("Creature sheet")
	_health.action_label = "%s / %s" % [str(_data.get("hit_points", "—")), str(_data.get("maximum_hit_points", "—"))]
	_health.accessibility_name = sdk.translations.text("Hit points") + " · " + _model.hp(_data)
	_health.tooltip_text = _model.hp(_data)
	visible = true
	_queue_render()

func _resized() -> void:
	if sdk != null:
		var experience := sdk.presentation_experience()
		_phone = experience.is_phone
		_tablet = experience.is_tablet
	_layout()
	_queue_render()

func _queue_render() -> void:
	if not _render_queued:
		_render_queued = true
		_render_panel.call_deferred()

func _open_category(category: String) -> void:
	if _category == category and _open:
		_close_panel()
		return
	_category = category
	_page = 0
	_page_rows = PAGE_ROWS_PHONE if _phone else PAGE_ROWS
	_panel_anchor = _health if category == "Hit points" else _tile(category)
	_open = true
	_panel.visible = true
	_search.value = ""
	_render_panel()
	_focus_panel.call_deferred()

func _focus_panel() -> void:
	if not _open: return
	if _category == "Hit points":
		_amount.grab_focus()
	elif _category == "Scene":
		_search.focus_editor()

func _close_panel() -> void:
	if _open and _panel_anchor != null and _panel_anchor.is_visible_in_tree():
		_panel_anchor.grab_focus()
	_category = ""
	_open = false
	_panel.visible = false
	_health.set_pressed_no_signal(false)
	for category in CREATURE_CATEGORIES:
		_tile(category).set_pressed_no_signal(false)

func _toggle_all(enabled: bool) -> void:
	_show_all = enabled
	_page = 0
	_render_panel()

func _search_changed(_text: String) -> void:
	_page = 0
	_render_panel()

func _change_page(direction: int) -> void:
	_page += direction
	_render_panel()

func _render_panel() -> void:
	_render_queued = false
	if not _open or _actor == null:
		return
	var hp := _category == "Hit points"
	var scene := _category == "Scene"
	var attacks := _category == "Attacks"
	_health.set_pressed_no_signal(hp)
	for category in CREATURE_CATEGORIES:
		_tile(category).set_pressed_no_signal(category == _category)
	get_node(SLOT + "Header").title = sdk.translations.text(_category)
	var all: CheckBox = get_node(SLOT + "Header/TitleRow/ActionsSlot/ShowAll")
	all.visible = attacks
	all.set_pressed_no_signal(_show_all)
	var current: Label = get_node(SLOT + "Header/TitleRow/ActionsSlot/CurrentHP")
	current.visible = hp
	current.text = _model.hp(_data)
	_search.visible = scene
	_health_editor.visible = hp
	_stepper.visible = hp
	var entries: Array[ENTRY] = []
	if scene:
		entries = _model.roster(_rook, _search.value)
	elif not hp:
		entries = _model.entries(_data, _category, _roll.pending)
	var filtered: Array[ENTRY] = []
	for entry in entries:
		if not attacks or _show_all or entry.favorite:
			filtered.append(entry)
	var pages := maxi(1, ceili(filtered.size() / float(_page_rows)))
	_page = clampi(_page, 0, pages - 1)
	_page_entries = filtered.slice(_page * _page_rows, (_page + 1) * _page_rows)
	_list.visible = not hp and not filtered.is_empty()
	var empty: Label = get_node(SLOT + "Empty")
	empty.visible = not hp and filtered.is_empty()
	var words: String = {"Attacks": "No attacks", "Special": "No special actions", "Scene": "No matching creatures"}.get(_category, "No entries")
	empty.text = sdk.translations.text("No favorites · enable Show all" if attacks and not entries.is_empty() else words)
	for part in ["Previous", "Page", "Next"]:
		get_node(SLOT + "Header/TitleRow/ActionsSlot/" + part).visible = not hp and pages > 1
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Page").text = "%s / %s" % [_page + 1, pages]
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Previous").disabled = _page == 0
	get_node(SLOT + "Header/TitleRow/ActionsSlot/Next").disabled = _page == pages - 1
	for index in range(_rows.size()):
		var row := _rows[index]
		row.visible = not hp and index < _page_entries.size()
		if row.visible:
			_render_entry(row, _page_entries[index], attacks)
	if hp:
		_preview_hp()

func _render_entry(row: Control, entry: ENTRY, favorites: bool) -> void:
	row.title = entry.title
	# A phone row has no room for a value lane beside a wrapped creature name.
	var joined := _phone and _category == "Scene"
	row.detail = entry.detail + (" · " if not entry.detail.is_empty() and not entry.value.is_empty() else "") + entry.value if joined else entry.detail
	row.value_text = "" if joined else entry.value
	row.leading_image = entry.icon
	var launch: Button = row.get_action_slot().get_node("Launch")
	launch.icon = LAUNCH_ICONS.get(_category)
	launch.disabled = not entry.available
	_name(launch, entry.title)
	var favorite: CheckBox = row.get_action_slot().get_node("Favorite")
	favorite.visible = favorites
	favorite.set_pressed_no_signal(entry.favorite)
	_name(favorite, sdk.translations.text("Remove %s from favorites" if entry.favorite else "Add %s to favorites") % entry.title)

func _favorite_row(enabled: bool, index: int) -> void:
	if index >= _page_entries.size() or _actor == null:
		return
	var result := _model.favorite(_data, _page_entries[index].id, enabled)
	if not result.ok:
		_error(result.message)
	_render_panel()

func _launch_row(index: int) -> void:
	if index >= _page_entries.size() or not _page_entries[index].available or _actor == null:
		return
	var actor := _actor
	var category := _category
	var entry := _page_entries[index].id
	_close_panel()
	if category == "Scene":
		var result := sdk.rooks.select(SDK.RookId.new(entry))
		if not result.ok:
			_error(result.message)
	elif category == "Attacks":
		var result := sdk.windows.open_actor_task(ATTACK, actor, {"item": "creature:" + entry, "mode": "attack"})
		if not result.ok:
			_error(result.message)
	elif category == "Checks":
		await _roll.start(actor, entry)
	elif category == "Special":
		await _special(actor, entry)

func _special(actor: SDK.ActorId, entry: String) -> void:
	if _special_pending:
		return
	if _special_request.get("actor", "") != actor.value or _special_request.get("entry", "") != entry:
		_special_request = {"id": sdk.dice.new_request_id(), "actor": actor.value, "entry": entry}
	_special_pending = true
	var result := await REQUEST.new(sdk, self).submit("creature-hud.special", _special_request.duplicate(true))
	var result_data: Dictionary = result.value if typeof(result.value) == TYPE_DICTIONARY else {}
	_special_pending = false
	if result.ok and typeof(result.value) == TYPE_DICTIONARY and result_data.get("ok", false):
		_special_request = {}
	else:
		_error(str(result_data.get("message", "Creature action is unavailable.")) if result.ok and typeof(result.value) == TYPE_DICTIONARY else result.message)

func _amount_changed(_text: String) -> void:
	_hp_request = {}
	_preview_hp()

func _step_amount(direction: int) -> void:
	var parsed := HEALTH.new().integer(_amount.text)
	var value: int = int(parsed.get("value", 0))
	if direction > 0 and value == HEALTH.MAX_VALUE or direction < 0 and value == HEALTH.MIN_VALUE:
		return
	_amount.text = str(value + direction)
	_amount_changed("")

func _hp_result(operation: String) -> Dictionary:
	var text: String = _amount.text
	var amount := HEALTH.new().integer(text) if operation == "set" else HEALTH.new().amount(text)
	return HEALTH.new().adjusted(_data, operation, int(amount.value)) if amount.ok else amount

func _preview_hp() -> void:
	var signed := HEALTH.new().integer(_amount.text)
	var error: Label = get_node(SLOT + "Health/Error")
	error.visible = not signed.ok
	error.text = sdk.translations.text(str(signed.get("message", "")))
	for operation in ["damage", "heal", "set"]:
		var result := _hp_result(operation)
		var button: Button = get_node(SLOT + "Health/Actions/" + operation)
		button.disabled = _hp_pending or not result.ok or result.get("value") == _data.get("hit_points")
		var preview := sdk.translations.text("%s → %s HP") % [str(_data.get("hit_points", 0)), str(result.value)] if result.ok else "—"
		(get_node(SLOT + "Health/Actions/" + operation + "Preview") as Label).text = preview
		button.tooltip_text = sdk.translations.text(str(result.get("message", "")))
		button.accessibility_name = button.text + " · " + preview
	_minus.disabled = _hp_pending
	_plus.disabled = _hp_pending

func _adjust_hp(operation: String) -> void:
	if _actor == null or _hp_pending or not _hp_result(operation).ok:
		return
	var actor := _actor
	var amount: String = _amount.text
	if _hp_request.get("actor", "") != actor.value or _hp_request.get("operation", "") != operation or _hp_request.get("amount", "") != amount:
		_hp_request = {"id": sdk.dice.new_request_id(), "actor": actor.value, "operation": operation, "amount": amount}
	var request := _hp_request.duplicate(true)
	_hp_pending = true
	_preview_hp()
	var result := await ACTIONS.new(sdk, actor).adjust_health(str(request.id), operation, amount, REQUEST.new(sdk, self))
	_hp_pending = false
	if result.ok:
		_hp_request = {}
		if _actor != null and _actor.value == actor.value and _category == "Hit points":
			_close_panel()
	else:
		_error(result.message)
	_refresh()

func _open_dice() -> void:
	_close_panel()
	var result := sdk.character_hud.open_dice_tray()
	if not result.ok:
		_error(result.message)

func _open_sheet() -> void:
	_close_panel()
	if _actor != null:
		var result := sdk.windows.open_actor(SHEET, _actor)
		if not result.ok:
			_error(result.message)

func _error(message: String) -> void:
	var feedback := SDK.FeedbackMessage.new()
	feedback.title = sdk.translations.text("Creature")
	feedback.message = sdk.translations.text(message)
	sdk.feedback.error(feedback)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_panel()
		accept_event()
		return
	var mouse := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var point := Vector2(0, 0)
	if mouse != null and mouse.pressed:
		point = mouse.position
	elif touch != null and touch.pressed:
		point = touch.position
	else:
		return
	if not _hud.get_global_rect().has_point(point):
		_close_panel()
