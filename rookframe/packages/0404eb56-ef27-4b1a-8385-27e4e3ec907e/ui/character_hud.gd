extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/hud_layout.gd"

const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW = preload(ROOT + "ui/hud_row.tscn")
const FAVORITES = preload(ROOT + "ui/sheet_favorites.gd")
const ATTACKS = preload(ROOT + "ui/hud_attacks.gd")
const POWERS = preload(ROOT + "ui/hud_powers.gd")
const ITEMS = preload(ROOT + "ui/hud_items.gd")
const COMPANIONS = preload(ROOT + "ui/hud_companions.gd")
const RECOVERY = preload(ROOT + "ui/hud_recovery.gd")
const SHEET: SDK.ExtensionSurface = preload(ROOT + "ui/character_surface.tres")
const CATEGORY_ICONS := {
	"Abilities": preload(ROOT + "ui/hud_art/abilities.svg"),
	"Attacks": preload(ROOT + "ui/hud_art/attacks.svg"),
	"Powers": preload(ROOT + "ui/hud_art/powers.svg"),
	"Items": preload(ROOT + "ui/hud_art/items.svg"),
	"Features": preload(ROOT + "ui/hud_art/features.svg"),
	"Companions": preload(ROOT + "ui/hud_art/companions.svg"),
	"Recovery": preload(ROOT + "ui/hud_art/recovery.svg"),
}
const ABILITIES := ["Strength", "Agility", "Presence", "Toughness"]
const ABILITY_ICONS := [preload(ROOT + "ui/hud_art/abilities.svg"), preload("res://rookframe/ui/icons/character/agility.svg"), preload(ROOT + "ui/hud_art/ability-presence.svg"), preload("res://rookframe/ui/icons/character/presence.svg")]

## The managed action receives the initiating Actor and stable source key.
signal entry_requested(actor: SDK.ActorId, category: String, entry_id: String)
signal favorite_requested(actor: SDK.ActorId, category: String, entry_id: String, favorite: bool)
signal morning_requested(actor: SDK.ActorId)
var _favorites := FAVORITES.new()
var _attacks := ATTACKS.new()
var _powers := POWERS.new()
var _items := ITEMS.new()
var _companions := COMPANIONS.new()
var _recovery := RECOVERY.new()
var _can_morning := false
var _pending_favorites: Dictionary = {}
var _actor: SDK.ActorId
var _page := 0
var _entries: Dictionary = {}
var _show_all: Dictionary = {}
var _page_entries: Array[ENTRY] = []
@onready var _launcher = get_node("Launcher")

func ready() -> void:
	if sdk == null:
		visible = false
		return
	_phone = sdk.presentation_experience().is_phone
	_tablet = sdk.presentation_experience().is_tablet
	for index in range(4):
		var row = ROW.instantiate()
		_list.add_child(row)
		_rows.append(row)
		row.get_node("Launch").pressed.connect(_launch_row.bind(index))
		row.get_node("Use").pressed.connect(_launch_row.bind(index))
		row.get_node("Favorite").toggled.connect(_favorite_row.bind(index))
		row.get_node("FullName").pressed.connect(_full_name_row.bind(index))
		row.get_node("Launch/Content/Copy/Title").resized.connect(_schedule_name_check)
	for category in ["Features", "Companions", "Recovery"]:
		get_node("Panel/More/" + category).pressed.connect(_open_category.bind(category))
		get_node("Panel/More/" + category + "/Title").text = sdk.translations.text(category)
		get_node("Panel/More/" + category + "/Icon").texture = CATEGORY_ICONS.get(category)
		get_node("Panel/More/" + category + "/Icon").modulate = PICTOGRAM
	_favorites.sdk = sdk
	favorite_requested.connect(_change_favorite)
	_attacks.bind(sdk)
	_powers.bind(sdk)
	_items.bind(sdk)
	_companions.bind(sdk)
	_recovery.bind(sdk)
	entry_requested.connect(_launch_entry)
	morning_requested.connect(_powers.morning)
	_launcher.bind(sdk)
	_launcher.changed.connect(_action_changed)
	sdk.character_hud.context_changed.connect(_refresh)
	sdk.world_changed.connect(_refresh)
	resized.connect(_layout)
	get_node("Bar/Dice").pressed.connect(_open_dice)
	get_node("Bar/Dice").accessibility_name = sdk.translations.text("Dice")
	get_node("Bar/Identity").pressed.connect(_open_sheet)
	get_node("Panel/Empty/Sheet").pressed.connect(_empty_action)
	get_node("Panel/Header/Close").pressed.connect(_close_panel)
	get_node("Panel/Back").pressed.connect(_back_or_close)
	get_node("Panel/Header/ShowAll").toggled.connect(_toggle_all)
	get_node("Panel/Header/Morning").pressed.connect(_morning)
	get_node("Panel/Header/Morning").text = sdk.translations.text("Morning")
	get_node("Panel/Header/Morning").accessibility_name = sdk.translations.text("Morning Power allowance")
	get_node("Panel/Footer/Previous").pressed.connect(_change_page.bind(-1))
	get_node("Panel/Footer/Next").pressed.connect(_change_page.bind(1))
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.pressed.connect(_open_category.bind(category))
		get_node("Bar/Categories/" + category + "/Title").text = sdk.translations.text(category)
		button.accessibility_name = sdk.translations.text(category)
		if category != "More":
			get_node("Bar/Categories/" + category + "/Icon").texture = CATEGORY_ICONS.get(category)
		get_node("Bar/Categories/" + category + "/Icon").modulate = PICTOGRAM
	get_node("Panel/Empty/Title").text = sdk.translations.text("No entries")
	get_node("Panel/Empty/Sheet").text = sdk.translations.text("Character sheet")
	get_node("Panel/Header/ShowAll").text = sdk.translations.text("Show all")
	for path in ["Panel/Header/Close", "Panel/Back", "Panel/Footer/Previous", "Panel/Footer/Next"]:
		var control: Button = get_node(path)
		control.accessibility_name = sdk.translations.text(control.accessibility_name)
	_style()
	_layout()
	_refresh()

## Presentation does not decide availability, favorites, source identity or game rules.
func set_entries(category: String, entries: Array[ENTRY]) -> void:
	if category not in CATEGORIES or category == "Abilities":
		return
	_entries[category] = entries
	if _category == category:
		_render_panel()

func _refresh() -> void:
	var context := sdk.character_hud.context()
	# Incomplete replication has not confirmed a different Actor or access level.
	if not context.ok and context.code in ["not_ready", "operation_in_progress"]:
		if _actor == null:
			visible = false
		return
	var source: SDK.ActorResult = sdk.actors.read(context.actor) if context.ok and context.actor != null else null
	if source != null and not source.ok and source.code in ["not_ready", "operation_in_progress"]:
		if _actor == null:
			visible = false
		return
	if source == null or not source.ok or source.actor == null or source.actor.access_level != "Owner" or typeof(source.actor.data) != TYPE_DICTIONARY:
		_actor = null
		_close_panel()
		visible = false
		return
	var data: Dictionary = source.actor.data
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		_actor = null
		_close_panel()
		visible = false
		return
	if _actor == null or _actor.value != source.actor.id.value:
		_close_panel()
		_entries = {}
		_show_all = {}
	_actor = source.actor.id
	get_node("Bar/Identity").accessibility_name = str(data.get("name", "")) + " · " + sdk.translations.text("Character sheet")
	get_node("Bar/Identity/Name").text = str(data.get("name", sdk.translations.text("Unnamed Actor")))
	get_node("Bar/Identity/Class").text = sdk.translations.text(str(data.get("class_title", "")))
	get_node("Bar/Identity/Hp").text = "%s / %s %s" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 0)), sdk.translations.text("HP")]
	get_node("Bar/Identity/HpTrack").value = clampf(float(data.get("hit_points", 0)) / maxf(1.0, float(data.get("maximum_hit_points", 0))) * 100.0, 0.0, 100.0)
	var portrait: String = data.get("portrait", "") if typeof(data.get("portrait", "")) == TYPE_STRING else ""
	var texture: Texture2D = preload("res://rookframe/ui/icons/character/character.svg")
	if not portrait.is_empty():
		var decoded := sdk.portraits.decode(portrait)
		if decoded.ok:
			texture = decoded.texture
	get_node("Bar/Identity/PortraitFrame/Portrait").texture = texture
	_layout_portrait()
	_layout_health()
	var entries: Array[ENTRY] = []
	var abilities: Dictionary = data.get("abilities", {})
	var can_roll: bool = _launcher.can_roll(source.actor)
	for index in range(ABILITIES.size()):
		var entry := ENTRY.new()
		entry.id = ABILITIES[index]
		entry.title = sdk.translations.text(entry.id)
		var ability: Dictionary = abilities.get(entry.id, {})
		var modifier := int(ability.get("modifier", 0))
		entry.value = ("+" if modifier >= 0 else "") + str(modifier)
		entry.icon = ABILITY_ICONS[index]
		entry.available = can_roll
		entries.append(entry)
	_entries["Abilities"] = entries
	_project_categories(source.actor)
	visible = true
	if not _category.is_empty() and not get_node("Panel/Detail").visible:
		_render_panel()

func _project_categories(actor: SDK.Actor) -> void:
	_entries["Attacks"] = _attacks.entries(actor)
	_entries["Powers"] = _powers.entries(actor)
	_entries["Items"] = _items.entries(actor)
	_entries["Features"] = _items.entries(actor, "Features")
	_entries["Companions"] = _companions.entries(actor)
	_entries["Recovery"] = _recovery.entries(actor)
	_can_morning = _powers.can_morning(actor)

func _launch_entry(actor: SDK.ActorId, category: String, key: String) -> void:
	if category == "Attacks":
		_attacks.launch(actor, {"key": key})
	elif category == "Powers":
		_powers.launch(actor, key)
	elif category in ["Items", "Features"]:
		_items.launch(actor, key)
	elif category == "Companions":
		_companions.launch(actor, key)
	elif category == "Recovery":
		_recovery.launch(actor, key)

func _favorite_request_key(actor: SDK.ActorId, key: String) -> String:
	return actor.value + ":" + key if actor != null else ""

func _change_favorite(actor: SDK.ActorId, _category_name: String, key: String, starred: bool) -> void:
	if actor == null:
		return
	var request_key := _favorite_request_key(actor, key)
	if _pending_favorites.has(request_key):
		return
	var current := sdk.actors.read(actor)
	if not current.ok or current.actor.access_level != "Owner":
		_refresh()
		return
	_pending_favorites[request_key] = true
	_refresh()
	var result := await _favorites.change(current.actor, key, starred)
	_pending_favorites.erase(request_key)
	if not result.ok:
		_error(result.message)
	# Refresh only the currently displayed context. The mutation kept its Actor.
	_refresh()

func _action_changed() -> void:
	if _actor == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_actor)
	var can_roll: bool = source.ok and _launcher.can_roll(source.actor)
	var entries: Array[ENTRY] = _entries.get("Abilities", [])
	for entry in entries:
		entry.available = can_roll
	if _category == "Abilities" and _panel.visible and not get_node("Panel/Detail").visible:
		for index in range(_page_entries.size()):
			_add_row(_rows[index], _page_entries[index], true)

func _open_dice() -> void:
	_close_panel()
	var result := sdk.character_hud.open_dice_tray()
	if not result.ok:
		_error(result.message)

func _open_sheet() -> void:
	_close_panel()
	if _actor == null:
		return
	var result := sdk.windows.open_actor(SHEET, _actor)
	if not result.ok:
		_error(result.message)

func _error(message: String) -> void:
	var feedback := SDK.FeedbackMessage.new()
	feedback.title = sdk.translations.text("Character")
	feedback.message = sdk.translations.text(message)
	sdk.feedback.error(feedback)

func _open_category(category: String) -> void:
	if _category == category and _panel.visible:
		_close_panel()
		return
	_category = category
	_page = 0
	_panel_anchor = get_node("Bar/Categories").get_node("More" if _phone and category in ["Features", "Companions", "Recovery"] else category)
	get_node("Panel/Detail").visible = false
	_panel.visible = true
	_render_panel()
	_panel.grab_focus()
	if category in ["Attacks", "Powers", "Items", "Features", "Companions"] and _actor != null:
		var initiating_actor := _actor
		var result := await _favorites.prepare(initiating_actor)
		if not result.ok and result.code not in ["not_ready", "operation_in_progress"]:
			_error(result.message)
		if _actor != null and _actor.value == initiating_actor.value:
			_refresh()

func _back_or_close() -> void:
	if get_node("Panel/Detail").visible:
		get_node("Panel/Detail").visible = false
		_render_panel()
		return
	_close_panel()

func _close_panel() -> void:
	if _panel.visible and _panel_anchor != null and _panel_anchor.is_visible_in_tree():
		_panel_anchor.grab_focus()
	get_node("Panel/Detail").visible = false
	get_node("Panel/Back").visible = false
	_category = ""
	_panel.visible = false
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(false)
		_category_colors(button, false)

func _morning() -> void:
	var initiating_actor := _actor
	_close_panel()
	if initiating_actor != null:
		morning_requested.emit(initiating_actor)

func _toggle_all(enabled: bool) -> void:
	_show_all[_category] = enabled
	_page = 0
	_render_panel()

func _change_page(direction: int) -> void:
	if get_node("Panel/Detail").visible:
		_detail_page += direction
		_layout_panel()
		return
	_page += direction
	_render_panel()

func _visible_entries() -> Array[ENTRY]:
	var result: Array[ENTRY] = []
	for entry in _entries.get(_category, []):
		if _category in ["Abilities", "Recovery"] or _show_all.get(_category, false) or entry.favorite:
			result.append(entry)
	return result

func _render_panel() -> void:
	var fixed := _category in ["Abilities", "Recovery", "More"]
	get_node("Panel/Header/Title").text = sdk.translations.text(_category)
	get_node("Panel/Header/ShowAll").visible = not fixed and not _entries.get(_category, []).is_empty()
	get_node("Panel/Back").visible = false
	get_node("Panel/Header/Morning").visible = _category == "Powers"
	get_node("Panel/Header/Morning").disabled = not _can_morning
	get_node("Panel/Header/ShowAll").set_pressed_no_signal(_show_all.get(_category, false))
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(button == _panel_anchor)
		_category_colors(button, button == _panel_anchor)
	var entries := _visible_entries()
	var page_size := 4 if not _phone or _category == "Abilities" else 2
	var pages := maxi(1, ceili(float(entries.size()) / page_size))
	_page = clampi(_page, 0, pages-1)
	_list.columns = 2 if _phone and _category == "Abilities" else 1
	_list.visible = not entries.is_empty() and _category != "More"
	_more.visible = _category == "More"
	get_node("Panel/Empty").visible = entries.is_empty() and _category != "More"
	var has_entries: bool = not _entries.get(_category, []).is_empty()
	var empty_titles := {"Attacks":"No attacks", "Powers":"No scrolls", "Items":"No usable items", "Features":"No active features", "Companions":"No companion attacks"}
	get_node("Panel/Empty/Title").text = sdk.translations.text("No favorites" if has_entries else empty_titles.get(_category, "No entries"))
	get_node("Panel/Empty/Sheet").text = sdk.translations.text("Show all" if has_entries else "Character sheet")
	get_node("Panel/Footer").visible = pages > 1
	get_node("Panel/Footer/Page").text = "%s / %s" % [_page+1, pages]
	get_node("Panel/Footer/Previous").disabled = _page == 0
	get_node("Panel/Footer/Next").disabled = _page == pages-1
	_page_entries = []
	for index in range(_page*page_size, mini((_page+1)*page_size, entries.size())):
		_page_entries.append(entries[index])
	for index in range(_rows.size()):
		var row = _rows[index]
		row.visible = index < _page_entries.size()
		if row.visible:
			_add_row(row, _page_entries[index], fixed)
			row.separator = index < _page_entries.size()-1 and not (_phone and _category == "Abilities")
			row.add_theme_constant_override("separation", 0)
			row.column_divider = _phone and _category == "Abilities" and index % 2 == 0
			row.queue_redraw()
	_layout_panel()
	_schedule_name_check()

func _add_row(row: ROW_SCRIPT, entry: ENTRY, fixed: bool) -> void:
	var ability_grid := _phone and _category == "Abilities"
	var height := 50 if ability_grid else 58 if _phone else 64 if _tablet else 76
	row.custom_minimum_size = Vector2(0, height)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var launch: Button = row.get_node("Launch")
	launch.disabled = not entry.available
	launch.accessibility_name = entry.title
	_button_style(launch)
	var content: HBoxContainer = launch.get_node("Content")
	content.add_theme_constant_override("separation", 8 if ability_grid else 10 if _phone else 12 if _tablet else 16)
	content.offset_left = 8 if _phone else 10 if _tablet else 12
	content.offset_right = -content.offset_left
	content.offset_top = 6 if _phone else 8 if _tablet else 10
	content.offset_bottom = -content.offset_top
	var icon: TextureRect = content.get_node("Icon")
	icon.texture = entry.icon
	var icon_size := 20 if ability_grid else 24 if _phone else 26 if _tablet else 30
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.modulate = PICTOGRAM if entry.available else MUTED
	var copy: VBoxContainer = content.get_node("Copy")
	copy.add_theme_constant_override("separation", 2 if _phone else 4)
	var title: Label = copy.get_node("Title")
	title.text = entry.title
	_type(title, 18 if _phone else 20 if _tablet else 22, 1.25 if _phone else 1.35)
	var detail: Label = copy.get_node("Detail")
	detail.text = entry.detail
	detail.visible = not entry.detail.is_empty()
	_type(detail, 14 if _phone else 15 if _tablet else 17, 1.2)
	detail.add_theme_color_override("font_color", MUTED)
	title.max_lines_visible = 2
	row.get_node("FullName").visible = false
	var value: Label = content.get_node("Value")
	value.text = entry.value
	value.visible = not entry.value.is_empty() and not entry.value_is_action
	_type(value, 18 if _phone else 17 if _tablet else 21, 1.25)
	value.add_theme_color_override("font_color", CONTENT if entry.available else MUTED)
	value.custom_minimum_size = Vector2(value.get_minimum_size().x+8, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", CONTENT if entry.available else MUTED)
	var use: Button = row.get_node("Use")
	use.visible = entry.value_is_action
	use.text = entry.value
	use.disabled = not entry.available
	use.accessibility_name = entry.value + " " + entry.title
	_button_style(use, false, 8 if _phone else 12)
	_type(use, 18 if _phone else 17 if _tablet else 21, 1.25)
	var star: Button = row.get_node("Favorite")
	star.visible = not fixed
	star.disabled = _pending_favorites.has(_favorite_request_key(_actor, str(entry.id)))
	star.set_pressed_no_signal(bool(entry.favorite))
	star.text = "★" if entry.favorite else "☆"
	_button_style(star)
	_type(star, 22, 1.25)
	star.accessibility_name = sdk.translations.text("Remove %s from favorites" if entry.favorite else "Add %s to favorites") % entry.title
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		star.add_theme_color_override(state, NEUTRAL if entry.favorite else MUTED)
	var full_name: Button = row.get_node("FullName")
	full_name.accessibility_name = sdk.translations.text("Show full name")
	_button_style(full_name)
	_type(full_name, 18, 1.25)

func _empty_action() -> void:
	if not _entries.get(_category, []).is_empty():
		_toggle_all(true)
	else:
		_open_sheet()

func _launch_row(index: int) -> void:
	if index >= _page_entries.size():
		return
	var actor := _actor
	var category := _category
	var id: String = _page_entries[index].id
	_close_panel()
	if category == "Abilities":
		await _launcher.roll_ability(actor, id)
	else:
		entry_requested.emit(actor, category, id)

func _favorite_row(enabled: bool, index: int) -> void:
	if index < _page_entries.size():
		favorite_requested.emit(_actor, _category, _page_entries[index].id, enabled)

func _full_name_row(index: int) -> void:
	if index < _page_entries.size():
		_full_name(_page_entries[index].title)

func _full_name(title: String) -> void:
	_detail_page = 0
	get_node("Panel/Header/Title").text = sdk.translations.text("Full name")
	get_node("Panel/Back").visible = true
	get_node("Panel/Empty").visible = false
	get_node("Panel/Detail/Text").text = title
	get_node("Panel/Detail").visible = true
	_list.visible = false
	_more.visible = false
	get_node("Panel/Footer").visible = false
	get_node("Panel/Header/ShowAll").visible = false
	get_node("Panel/Header/Morning").visible = false
	_layout_panel()

func _category_colors(button: Button, active: bool) -> void:
	var title: Label = button.get_node("Title")
	title.add_theme_color_override("font_color", INK if active else CONTENT)
	var icon: TextureRect = button.get_node("Icon")
	icon.modulate = INK if active else PICTOGRAM
	if button.name == "More":
		var glyph: Label = button.get_node("Glyph")
		glyph.add_theme_color_override("font_color", INK if active else CONTENT)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_panel()
		accept_event()
		return
	var point := Vector2(0, 0)
	var mouse := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if mouse != null and mouse.pressed:
		point = mouse.position
	elif touch != null and touch.pressed:
		point = touch.position
	else:
		return
	if not _bar.get_global_rect().has_point(point) and not _panel.get_global_rect().has_point(point):
		_close_panel()
