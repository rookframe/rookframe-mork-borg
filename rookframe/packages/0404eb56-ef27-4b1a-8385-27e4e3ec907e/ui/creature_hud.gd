extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_hud_layout.gd"

const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW = preload(ROOT + "ui/hud_row.tscn")
const MODEL = preload(ROOT + "ui/creature_hud_model.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const REQUEST = preload(ROOT + "logic/action_request.gd")
const ROLL = preload(ROOT + "ui/creature_hud_roll.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const SHEET: SDK.ExtensionSurface = preload(ROOT + "ui/creature_surface.tres")
const ATTACK: SDK.ExtensionSurface = preload(ROOT + "ui/tabletop_attack_surface.tres")
var _model := MODEL.new()
var _roll: ROLL
var _actor: SDK.ActorId
var _rook: SDK.RookId
var _data: Dictionary = {}
var _page := 0
var _show_all := false
var _page_entries: Array[ENTRY] = []
var _hp_pending := false
var _special_pending := false
var _hp_request: Dictionary = {}
var _special_request: Dictionary = {}
var _render_queued := false

func _init() -> void:
	visible = false

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
	for index in range(4):
		var row = ROW.instantiate()
		_list.add_child(row)
		_rows.append(row)
		row.get_node("Launch").pressed.connect(_launch_row.bind(index))
		row.get_node("Favorite").toggled.connect(_favorite_row.bind(index))
	sdk.character_hud.context_changed.connect(_refresh)
	sdk.world_changed.connect(_refresh)
	resized.connect(_resized)
	get_node("Bar/Dice").pressed.connect(_open_dice)
	get_node("Bar/Dice").accessibility_name = sdk.translations.text("Dice")
	get_node("Bar/Identity").pressed.connect(_open_sheet)
	get_node("Bar/Health").pressed.connect(_open_category.bind("Hit points"))
	get_node("Panel/Header/Close").pressed.connect(_close_panel)
	get_node("Panel/Header/ShowAll").toggled.connect(_toggle_all)
	get_node("Panel/Header/ShowAll").text = sdk.translations.text("Show all")
	get_node("Panel/Footer/Previous").pressed.connect(_change_page.bind(-1))
	get_node("Panel/Footer/Next").pressed.connect(_change_page.bind(1))
	get_node("Panel/Search").text_changed.connect(_search_changed)
	get_node("Panel/Search").placeholder_text = sdk.translations.text("Find a creature…")
	get_node("Panel/Search").accessibility_name = sdk.translations.text("Find a creature…")
	get_node("Panel/Health/Amount").text_changed.connect(_amount_changed)
	get_node("Panel/Health/Amount").accessibility_name = sdk.translations.text("Amount")
	get_node("Panel/Health/AmountLabel").text = sdk.translations.text("Amount")
	get_node("Panel/Health/Minus").pressed.connect(_step_amount.bind(-1))
	get_node("Panel/Health/Plus").pressed.connect(_step_amount.bind(1))
	for operation in ["damage", "heal", "set"]:
		var button: Button = get_node("Panel/Health/" + operation)
		button.pressed.connect(_adjust_hp.bind(operation))
		var label: String = {"damage": "Damage", "heal": "Heal", "set": "Set HP"}.get(operation)
		(button.get_node("Title") as Label).text = sdk.translations.text(label)
	for category in CREATURE_CATEGORIES:
		var button: Button = get_node("Bar/Categories/" + category)
		button.pressed.connect(_open_category.bind(category))
		button.accessibility_name = sdk.translations.text(category)
		(button.get_node("Title") as Label).text = sdk.translations.text(category)
		(button.get_node("Icon") as TextureRect).texture = MODEL.ICONS.get(category)
		(button.get_node("Icon") as TextureRect).modulate = PICTOGRAM
	for path in ["Panel/Header/Close", "Panel/Footer/Previous", "Panel/Footer/Next", "Panel/Health/Minus", "Panel/Health/Plus"]:
		var button: Button = get_node(path)
		button.accessibility_name = sdk.translations.text(button.accessibility_name)
	_style()
	_layout()
	_refresh()

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
	get_node("Bar/Identity/Name").text = name
	get_node("Bar/Identity").tooltip_text = name
	get_node("Bar/Identity").accessibility_name = name + " · " + sdk.translations.text("Creature sheet")
	get_node("Bar/Identity/PortraitFrame/Portrait").texture = _model.portrait(_data)
	var armor: Dictionary = _data.get("armor", {})
	get_node("Bar/Identity/Class").text = str(armor.get("name", "")) + (" −" + str(armor.reduction) if not str(armor.get("reduction", "")).is_empty() else "")
	get_node("Bar/Health/Value").text = _model.hp(_data)
	get_node("Bar/Health").accessibility_name = sdk.translations.text("Hit points") + " · " + _model.hp(_data)
	get_node("Bar/Health").tooltip_text = _model.hp(_data)
	get_node("Bar/Health/Track").value = clampf(float(_data.get("hit_points", 0)) / maxf(1.0, float(_data.get("maximum_hit_points", 0))) * 100.0, 0.0, 100.0)
	visible = true
	_queue_render()

func _resized() -> void:
	_layout()
	_queue_render()

func _queue_render() -> void:
	if not _render_queued:
		_render_queued = true
		_render_panel.call_deferred()

func _open_category(category: String) -> void:
	if _category == category and _panel.visible:
		_close_panel()
		return
	_category = category
	_page = 0
	_panel_anchor = get_node("Bar/Health") if category == "Hit points" else get_node("Bar/Categories/" + category)
	_panel.visible = true
	get_node("Panel/Search").text = ""
	_render_panel()
	_panel.grab_focus()
	if category == "Hit points":
		get_node("Panel/Health/Amount").grab_focus()
	elif category == "Scene":
		get_node("Panel/Search").grab_focus()

func _close_panel() -> void:
	if _panel.visible and _panel_anchor != null and _panel_anchor.is_visible_in_tree():
		_panel_anchor.grab_focus()
	_category = ""
	_panel.visible = false
	get_node("Bar/Health").set_pressed_no_signal(false)
	for category in CREATURE_CATEGORIES:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(false)
		_category_colors(button, false)

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
	if not _panel.visible or _actor == null:
		return
	var hp := _category == "Hit points"
	get_node("Bar/Health").set_pressed_no_signal(hp)
	var scene := _category == "Scene"
	var attacks := _category == "Attacks"
	get_node("Panel/Header/Title").text = sdk.translations.text(_category)
	get_node("Panel/Header/ShowAll").visible = attacks
	get_node("Panel/Header/CurrentHP").visible = hp
	get_node("Panel/Header/CurrentHP").text = _model.hp(_data)
	get_node("Panel/Header/ShowAll").set_pressed_no_signal(_show_all)
	get_node("Panel/Search").visible = scene
	get_node("Panel/Health").visible = hp
	get_node("Panel/Detail").visible = false
	_more.visible = false
	for category in CREATURE_CATEGORIES:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(category == _category)
		_category_colors(button, category == _category)
	var entries: Array[ENTRY] = _model.roster(_rook, get_node("Panel/Search").text) if scene else _model.entries(_data, _category, _roll.pending)
	var filtered: Array[ENTRY] = []
	for entry in entries:
		if not attacks or _show_all or entry.favorite:
			filtered.append(entry)
	var pages: Array = [[]]
	var used := 0.0
	var maximum := 2 if _phone else 4
	# Measure real font wrapping before pagination, reserving the navigation row.
	var available: float = _bar.position.y - (44 if _phone else 52 if _tablet else 64) - (52 if scene else 0) - 44 - 38
	for entry in filtered:
		var height := _entry_height(entry, attacks, scene)
		if not pages[-1].is_empty() and (pages[-1].size() >= maximum or used + height > available):
			pages.append([])
			used = 0.0
		pages[-1].append(entry)
		used += height
	_page = clampi(_page, 0, pages.size()-1)
	_page_entries = []
	var current_page: Array = pages[_page]
	for entry in current_page:
		_page_entries.append(entry)
	_list.visible = not hp and not filtered.is_empty()
	get_node("Panel/Empty").visible = not hp and filtered.is_empty()
	var empty: String = {"Attacks": "No attacks", "Special": "No special actions", "Scene": "No matching creatures"}.get(_category, "No entries")
	get_node("Panel/Empty/Title").text = sdk.translations.text("No favorites · enable Show all" if attacks and not entries.is_empty() else empty)
	get_node("Panel/Footer").visible = not hp and pages.size() > 1
	get_node("Panel/Footer/Page").text = "%s / %s" % [_page+1, pages.size()]
	get_node("Panel/Footer/Previous").disabled = _page == 0
	get_node("Panel/Footer/Next").disabled = _page == pages.size()-1
	for index in range(_rows.size()):
		var row = _rows[index]
		row.visible = not hp and index < _page_entries.size()
		if not row.visible:
			continue
		var entry := _page_entries[index]
		_render_entry(row, entry, not attacks)
		var height := _entry_height(entry, attacks, scene)
		row.custom_minimum_size = Vector2(0, height)
		row.get_node("Launch").custom_minimum_size = Vector2(0, height)
		row.get_node("Launch").tooltip_text = entry.title
		row.get_node("Launch/Content/Copy/Title").max_lines_visible = 3 if scene else 2
		if scene:
			row.get_node("Launch/Content/Icon").modulate = Color(1, 1, 1, 1)
		row.separator = index < _page_entries.size()-1
		row.column_divider = false
		row.queue_redraw()
	if hp:
		_preview_hp()
	_layout_panel()
	_layout_panel.call_deferred()

func _entry_height(entry: ENTRY, attacks: bool, scene: bool) -> float:
	var width := (380 if _phone else 430 if _tablet else 510) - (26 if _phone else 34 if _tablet else 42)
	var title_size := 18 if _phone else 20 if _tablet else 22
	var value_size := 18 if _phone else 17 if _tablet else 21
	var measure_value: Label = get_node("MeasureValue")
	_type(measure_value, value_size, 1.25)
	measure_value.text = entry.value
	var value_width := measure_value.get_minimum_size().x + (8 if not entry.value.is_empty() else 0)
	var text_width: float = width - (16 if _phone else 20 if _tablet else 24) - (24 if _phone else 26 if _tablet else 30) - (20 if _phone else 24 if _tablet else 32) - value_width - (44 if attacks else 0)
	var measure_title: Label = get_node("MeasureTitle")
	_type(measure_title, title_size, 1.25 if _phone else 1.35)
	measure_title.size = Vector2(maxf(40, text_width), 0)
	measure_title.text = entry.title
	var lines := measure_title.get_line_count()
	var height: float = minf(lines, 3 if scene else 2) * (23 if _phone else 27 if _tablet else 30)
	if not entry.detail.is_empty():
		height += 19 if _phone else 22 if _tablet else 24
	return maxf(58 if _phone else 64 if _tablet else 76, height + (12 if _phone else 16 if _tablet else 20)) + 1

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
	_special_pending = false
	if result.ok and typeof(result.value) == TYPE_DICTIONARY and result.value.get("ok", false):
		_special_request = {}
	else:
		_error(str(result.value.get("message", "Creature action is unavailable.")) if result.ok and typeof(result.value) == TYPE_DICTIONARY else result.message)

func _amount_changed(_text: String) -> void:
	_hp_request = {}
	_preview_hp()
	_layout_panel()

func _step_amount(direction: int) -> void:
	var parsed := HEALTH.new().integer(get_node("Panel/Health/Amount").text)
	var value: int = int(parsed.get("value", 0))
	if direction > 0 and value == HEALTH.MAX_VALUE or direction < 0 and value == HEALTH.MIN_VALUE:
		return
	get_node("Panel/Health/Amount").text = str(value + direction)
	_amount_changed("")

func _hp_result(operation: String) -> Dictionary:
	var text: String = get_node("Panel/Health/Amount").text
	var amount := HEALTH.new().integer(text) if operation == "set" else HEALTH.new().amount(text)
	return HEALTH.new().adjusted(_data, operation, int(amount.value)) if amount.ok else amount

func _preview_hp() -> void:
	var signed := HEALTH.new().integer(get_node("Panel/Health/Amount").text)
	var error: Label = get_node("Panel/Health/Error")
	error.visible = not signed.ok
	error.text = sdk.translations.text(str(signed.get("message", "")))
	for operation in ["damage", "heal", "set"]:
		var result := _hp_result(operation)
		var button: Button = get_node("Panel/Health/" + operation)
		button.disabled = _hp_pending or not result.ok or result.get("value") == _data.get("hit_points")
		var preview := sdk.translations.text("%s → %s HP") % [str(_data.get("hit_points", 0)), str(result.value)] if result.ok else "—"
		var preview_label: Label = button.get_node("Preview")
		preview_label.text = preview
		preview_label.add_theme_color_override("font_color", MUTED if button.disabled else CONTENT)
		var title: Label = button.get_node("Title")
		title.add_theme_color_override("font_color", MUTED if button.disabled else CONTENT)
		var icon: TextureRect = button.get_node("Icon")
		icon.modulate = MUTED if button.disabled else PICTOGRAM
		button.tooltip_text = sdk.translations.text(str(result.get("message", "")))
		button.accessibility_name = (button.get_node("Title") as Label).text + " · " + preview
	get_node("Panel/Health/Minus").disabled = _hp_pending
	get_node("Panel/Health/Plus").disabled = _hp_pending

func _adjust_hp(operation: String) -> void:
	if _actor == null or _hp_pending or not _hp_result(operation).ok:
		return
	var actor := _actor
	var amount: String = get_node("Panel/Health/Amount").text
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
	if not is_visible_in_tree() or not _panel.visible:
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
	if not _bar.get_global_rect().has_point(point) and not _panel.get_global_rect().has_point(point):
		_close_panel()

func _category_colors(button: Button, active: bool) -> void:
	var title: Label = button.get_node("Title")
	title.add_theme_color_override("font_color", INK if active else CONTENT)
	var icon: TextureRect = button.get_node("Icon")
	icon.modulate = INK if active else PICTOGRAM
