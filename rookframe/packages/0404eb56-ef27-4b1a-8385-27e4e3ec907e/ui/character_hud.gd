extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const ENTRY = preload(ROOT + "ui/hud_entry.gd")
const ROW = preload(ROOT + "ui/hud_row.tscn")
const FAVORITES = preload(ROOT + "ui/sheet_favorites.gd")
const ROW_SCRIPT = preload(ROOT + "ui/hud_row.gd")
const SHEET: SDK.ExtensionSurface = preload(ROOT + "ui/character_surface.tres")
const TOKENS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/hud_palette.gd")
const GOLD := Color(0.88627450980392153, 0.7686274509803922, 0.42745098039215684, 1.0)
const CATEGORIES := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery"]
const BUTTONS := ["Abilities", "Attacks", "Powers", "Items", "Features", "Companions", "Recovery", "More"]
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
var _pending_favorites: Dictionary = {}
var _actor: SDK.ActorId
var _category := ""
var _page := 0
var _entries: Dictionary = {}
var _show_all: Dictionary = {}
var _phone := false
var _tablet := false
var _rows: Array[ROW_SCRIPT] = []
var _page_entries: Array[ENTRY] = []
var _panel_anchor: Button
@onready var _bar: Control = get_node("Bar")
@onready var _panel: Control = get_node("Panel")
@onready var _list: GridContainer = get_node("Panel/List")
@onready var _more: GridContainer = get_node("Panel/More")
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
		row.get_node("Favorite").toggled.connect(_favorite_row.bind(index))
		row.get_node("FullName").pressed.connect(_full_name_row.bind(index))
	for category in ["Features", "Companions", "Recovery"]:
		get_node("Panel/More/" + category).pressed.connect(_open_category.bind(category))
		get_node("Panel/More/" + category + "/Title").text = sdk.translations.text(category)
		get_node("Panel/More/" + category + "/Icon").texture = CATEGORY_ICONS.get(category)
		get_node("Panel/More/" + category + "/Icon").modulate = GOLD
	_favorites.sdk = sdk
	favorite_requested.connect(_change_favorite)
	_launcher.bind(sdk)
	_launcher.changed.connect(_action_changed)
	sdk.character_hud.context_changed.connect(_refresh)
	sdk.world_changed.connect(_refresh)
	resized.connect(_layout)
	get_node("Bar/Dice").pressed.connect(_open_dice)
	get_node("Bar/Dice").accessibility_name = sdk.translations.text("Dice")
	get_node("Bar/Identity").pressed.connect(_open_sheet)
	get_node("Panel/Empty/Sheet").pressed.connect(_open_sheet)
	get_node("Panel/Header/Close").pressed.connect(_back_or_close)
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
		get_node("Bar/Categories/" + category + "/Icon").modulate = GOLD
	get_node("Panel/Empty/Title").text = sdk.translations.text("No entries")
	get_node("Panel/Empty/Sheet").text = sdk.translations.text("Character sheet")
	get_node("Panel/Header/ShowAll").text = sdk.translations.text("Show all")
	_style()
	_layout()
	_refresh()

## Presentation does not decide availability, favorites, source identity or game rules.
func set_entries(category: String, entries: Array[ENTRY]) -> void:
	if category not in CATEGORIES or category == "Abilities":
		return
	for entry in entries:
		entry.favorite_editable = not _pending_favorites.has(_favorite_request_key(_actor, entry.id))
	_entries[category] = entries
	if _category == category:
		_render_panel()

func _refresh() -> void:
	var context := sdk.character_hud.context()
	var source: SDK.ActorResult = sdk.actors.read(context.actor) if context.ok and context.actor != null else null
	if source == null or not source.ok or source.actor == null or source.actor.access_level != "Owner" or str(source.actor.data.get("schema", "")) != "mork-borg-character/v1":
		_actor = null
		_close_panel()
		visible = false
		return
	if _actor == null or _actor.value != source.actor.id.value:
		_close_panel()
		_entries = {}
		_show_all = {}
	_actor = source.actor.id
	var data: Dictionary = source.actor.data
	get_node("Bar/Identity").accessibility_name = str(data.get("name", "")) + " · " + sdk.translations.text("Character sheet")
	get_node("Bar/Identity/Name").text = str(data.get("name", sdk.translations.text("Unnamed Actor")))
	get_node("Bar/Identity/Class").text = sdk.translations.text(str(data.get("class_title", "")))
	get_node("Bar/Identity/Hp").text = "%s / %s %s" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 0)), sdk.translations.text("HP")]
	get_node("Bar/Identity/HpTrack").value = clampf(float(data.get("hit_points", 0)) / maxf(1.0, float(data.get("maximum_hit_points", 0))) * 100.0, 0.0, 100.0)
	var portrait: PackedByteArray = data.get("portrait", PackedByteArray())
	var texture: Texture2D = preload("res://rookframe/ui/icons/character/character.svg")
	if not portrait.is_empty():
		var decoded := sdk.portraits.decode(portrait)
		if decoded.ok:
			texture = decoded.texture
	get_node("Bar/Identity/PortraitFrame/Portrait").texture = texture
	var entries: Array[ENTRY] = []
	var abilities: Dictionary = data.get("abilities", {})
	var can_roll: bool = _launcher.can_roll(source.actor)
	for index in range(ABILITIES.size()):
		var entry := ENTRY.new()
		entry.id = ABILITIES[index]
		entry.title = sdk.translations.text(entry.id)
		var modifier := int(abilities.get(entry.id, {}).get("modifier", 0))
		entry.value = ("+" if modifier >= 0 else "") + str(modifier)
		entry.icon = ABILITY_ICONS[index]
		entry.available = can_roll
		entries.append(entry)
	_entries["Abilities"] = entries
	_project_favorites(source.actor)
	visible = true
	if not _category.is_empty() and not get_node("Panel/Detail").visible:
		_render_panel()

func _project_favorites(actor: SDK.Actor) -> void:
	var sources := _favorites.entries(actor)
	for category in ["Attacks", "Powers", "Items", "Features", "Companions"]:
		var entries: Array[ENTRY] = []
		for source in sources:
			if str(source.get("category", "")) != category:
				continue
			var entry := ENTRY.new()
			entry.id = str(source.key)
			entry.title = sdk.translations.text(str(source.get("name", "Favorite")))
			entry.detail = sdk.translations.text(str(source.get("detail", "")))
			entry.value = str(source.get("damage", ""))
			entry.icon = CATEGORY_ICONS.get(category)
			entry.available = source.get("available", false)
			entry.favorite = source.get("starred", false)
			entries.append(entry)
		set_entries(category, entries)

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
	if category in ["Attacks", "Powers", "Items", "Features", "Companions"] and _actor != null:
		var initiating_actor := _actor
		var result := await _favorites.prepare(initiating_actor)
		if not result.ok:
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
	get_node("Panel/Detail").visible = false
	_category = ""
	_panel.visible = false
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(false)
		get_node("Bar/Categories/" + category + "/Title").add_theme_color_override("font_color", TOKENS.COLOR_CONTENT)

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
	get_node("Panel/Header/ShowAll").visible = not fixed
	get_node("Panel/Header/Morning").visible = _category == "Powers"
	get_node("Panel/Header/ShowAll").set_pressed_no_signal(_show_all.get(_category, false))
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.set_pressed_no_signal(button == _panel_anchor)
		get_node("Bar/Categories/" + category + "/Title").add_theme_color_override("font_color", GOLD if button == _panel_anchor else TOKENS.COLOR_CONTENT)
	var entries := _visible_entries()
	var page_size := 4 if not _phone or _category == "Abilities" else 2
	var pages := maxi(1, ceili(float(entries.size()) / page_size))
	_page = clampi(_page, 0, pages-1)
	_list.columns = 2 if _phone and _category == "Abilities" else 1
	_list.visible = not entries.is_empty() and _category != "More"
	_more.visible = _category == "More"
	get_node("Panel/Empty").visible = entries.is_empty() and _category != "More"
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
			row.column_divider = _phone and _category == "Abilities" and index % 2 == 0
			row.queue_redraw()
	_layout_panel()
	_check_names.call_deferred()

func _add_row(row: ROW_SCRIPT, entry: ENTRY, fixed: bool) -> void:
	row.custom_minimum_size = Vector2(0, 44 if _phone and _category == "Abilities" else 48 if _phone else 52 if _tablet else 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var launch: Button = row.get_node("Launch")
	launch.disabled = not entry.available
	var content: HBoxContainer = row.get_node("Launch/Content")
	content.add_theme_constant_override("separation", 8 if _phone else 14)
	var icon: TextureRect = content.get_node("Icon")
	icon.texture = entry.icon
	var icon_size := 18 if _phone and _category == "Abilities" else 20 if _phone else 27
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.modulate = TOKENS.COLOR_CONTENT_MUTED
	var title: Label = content.get_node("Copy/Title")
	title.text = entry.title
	title.add_theme_font_size_override("font_size", 13 if _phone else 16)
	var detail: Label = content.get_node("Copy/Detail")
	detail.text = entry.detail
	detail.visible = not entry.detail.is_empty()
	detail.add_theme_font_size_override("font_size", 11 if _phone else 12)
	detail.add_theme_color_override("font_color", TOKENS.COLOR_CONTENT_MUTED)
	var value: Label = content.get_node("Value")
	value.text = entry.value
	value.visible = not entry.value.is_empty()
	value.add_theme_font_size_override("font_size", 13 if _phone else 16)
	value.add_theme_color_override("font_color", TOKENS.COLOR_ACCENT if entry.available else TOKENS.COLOR_CONTENT_MUTED)
	title.add_theme_color_override("font_color", TOKENS.COLOR_CONTENT if entry.available else TOKENS.COLOR_CONTENT_MUTED)
	row.get_node("Favorite").visible = not fixed
	row.get_node("Favorite").disabled = not entry.favorite_editable
	row.get_node("Favorite").set_pressed_no_signal(entry.favorite)
	row.get_node("Favorite").text = "★" if entry.favorite else "☆"
	row.get_node("Favorite").add_theme_color_override("font_color", GOLD if entry.favorite else TOKENS.COLOR_CONTENT_MUTED)
	if _phone:
		content.offset_left = 2
		content.offset_right = -2

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
	get_node("Panel/Detail").text = title
	get_node("Panel/Detail").visible = true
	_list.visible = false
	_more.visible = false
	get_node("Panel/Footer").visible = false
	get_node("Panel/Header/ShowAll").visible = false
	get_node("Panel/Header/Morning").visible = false
	_layout_panel()

func _check_names() -> void:
	for row in _rows:
		row.get_node("FullName").visible = row.get_node("Launch/Content/Copy/Title").get_line_count() > 2
	_layout_panel()

func _rect(control: Control, x: float, y: float, w: float, h: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(w, h)

func _layout() -> void:
	if not is_node_ready():
		return
	var inset := 172 if _phone else 128 if _tablet else 256
	var height := 48 if _phone else 68 if _tablet else 124
	var bottom := 8 if _phone else 16 if _tablet else 24
	_rect(_bar, inset, size.y-bottom-height, maxf(0, size.x-inset*2), height)
	var padding := 6 if _phone or _tablet else 12
	var dice_width := 76 if _phone else 104 if _tablet else 176
	var dice_height := 76 if _phone else 96 if _tablet else 148
	var gap := 8 if _phone or _tablet else 20
	var dice_y := height-(2 if _phone else padding)-dice_height
	_rect(get_node("Bar/Dice"), padding, dice_y, dice_width, dice_height)
	get_node("Bar/Dice/Frame").texture = load(ROOT + "ui/hud_art/dice-" + ("phone" if _phone else "tablet" if _tablet else "desktop") + ".svg")
	var emblem := Vector2(58, 62) if _phone else Vector2(76, 80) if _tablet else Vector2(100, 104)
	_rect(get_node("Bar/Dice/Emblem"), (dice_width-emblem.x)/2, 5 if _phone or _tablet else 8, emblem.x, emblem.y)
	_rect(get_node("Bar/Dice/Face"), (dice_width-emblem.x)/2, get_node("Bar/Dice/Emblem").position.y+emblem.y*.40, emblem.x, emblem.y*.23)
	get_node("Bar/Dice/Face").add_theme_font_size_override("font_size", int(emblem.x/64*10 + 0.5))
	get_node("Bar/Dice/Face").add_theme_color_override("font_color", Color(1, 0.90196078431372551, 0.6588235294117647, 1.0))
	get_node("Bar/Dice/Title").visible = not _phone and not _tablet
	_rect(get_node("Bar/Dice/Title"), 0, 115, dice_width, 20)
	var identity_width := 140 if _phone else 172 if _tablet else 340
	_rect(get_node("Bar/Identity"), padding+dice_width+gap, 2 if _phone else padding, identity_width, height-(4 if _phone else padding*2))
	var portrait := Vector2(34, 38) if _phone else Vector2(50, 50) if _tablet else Vector2(94, 94)
	_rect(get_node("Bar/Identity/PortraitFrame"), 0, (get_node("Bar/Identity").size.y-portrait.y)/2, portrait.x, portrait.y)
	var text_x := portrait.x + (7 if _phone else 8 if _tablet else 18)
	var text_width := identity_width-text_x-(8 if _phone or _tablet else 20)
	_rect(get_node("Bar/Identity/Name"), text_x, 2 if _phone else 5 if _tablet else 8, text_width, 20 if _phone or _tablet else 32)
	_rect(get_node("Bar/Identity/Class"), text_x, 46, text_width, 20)
	get_node("Bar/Identity/Class").visible = not _phone and not _tablet
	_rect(get_node("Bar/Identity/Hp"), text_x, 21 if _phone else 30 if _tablet else 73, text_width, 18)
	_rect(get_node("Bar/Identity/HpTrack"), text_x, 33 if _tablet else 77, maxf(24, text_width-(68 if _tablet else 85)), 10)
	get_node("Bar/Identity/HpTrack").visible = not _phone
	get_node("Bar/Identity/Hp").horizontal_alignment = 0 if _phone else 2
	_rect(get_node("Bar/Identity/Divider"), identity_width-1, 0, 1, get_node("Bar/Identity").size.y)
	var category_x := padding+dice_width+gap+identity_width+gap
	_rect(get_node("Bar/Categories"), category_x, 2 if _phone else padding, _bar.size.x-category_x-padding, height-(4 if _phone else padding*2))
	var buttons: Array = ["Abilities", "Attacks", "Powers", "Items", "More"] if _phone else CATEGORIES
	var category_gap := 4 if _phone or _tablet else 14
	var button_width: float = (get_node("Bar/Categories").size.x-category_gap*(buttons.size()-1))/buttons.size()
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		button.visible = category in buttons
		if button.visible:
			_rect(button, buttons.find(category)*(button_width+category_gap), 0, button_width, get_node("Bar/Categories").size.y)
			_layout_category(button, button_width, button.size.y)
	get_node("Bar/Identity/Name").add_theme_font_size_override("font_size", 13 if _phone else 16 if _tablet else 25)
	get_node("Bar/Identity/Class").add_theme_font_size_override("font_size", 15)
	get_node("Bar/Identity/Hp").add_theme_font_size_override("font_size", 11 if _phone else 12 if _tablet else 14)
	_layout_panel()

func _layout_category(button: Button, width: float, height: float) -> void:
	var icon_control: TextureRect = button.get_node("Icon")
	var title_control: Label = button.get_node("Title")
	var icon := 20 if _phone else 24 if _tablet else 30
	var gap := 2 if _phone else 5 if _tablet else 10
	var label_height := 16 if _phone or _tablet else 22
	var top: float = (height-icon-gap-label_height)/2
	_rect(icon_control, (width-icon)/2, top, icon, icon)
	_rect(title_control, 0, top+icon+gap, width, label_height)
	title_control.add_theme_font_size_override("font_size", 11 if _phone or _tablet else 15)
	if button.name == "More":
		icon_control.visible = false
		title_control.text = "•••\n" + sdk.translations.text("More")
		_rect(title_control, 0, top, width, icon+gap+label_height)

func _layout_panel() -> void:
	if _panel_anchor == null or not _panel.visible:
		return
	var width := 360 if _phone else 400 if _tablet else 460
	var pad := 8 if _phone else 12
	var top := 4 if _phone else 8
	var header := 44 if _phone else 48
	var body: float = 68 if _more.visible else _list.get_combined_minimum_size().y if _list.visible else 52 if _phone else 64
	if get_node("Panel/Detail").visible:
		body = maxf(44, get_node("Panel/Detail").get_minimum_size().y + 16)
	var height: float = top+header+body+(44 if get_node("Panel/Footer").visible else 0)+(6 if _phone else 12)
	var anchor: float = _panel_anchor.position.x + get_node("Bar/Categories").position.x + _panel_anchor.size.x/2
	var left: float = clampf(anchor-width/2, 0, _bar.size.x-width)
	_rect(_panel, _bar.position.x+left, _bar.position.y-(10 if _phone else 12)-height, width, height)
	get_node("Panel/Frame").cut = 5 if _phone else 10
	get_node("Panel/Frame").pointer = clampf(anchor-left, 12, width-12)
	get_node("Panel/Frame").queue_redraw()
	_rect(get_node("Panel/Header"), pad, top, width-pad*2, header)
	var morning_width := 72 if get_node("Panel/Header/Morning").visible else 0
	var all_width := 88 if morning_width > 0 else 120
	var all_left := width-pad*2-44-morning_width-all_width
	_rect(get_node("Panel/Header/Title"), 0, 0, all_left if get_node("Panel/Header/ShowAll").visible else width-pad*2-44-morning_width, header)
	get_node("Panel/Header/Title").add_theme_font_size_override("font_size", 17 if _phone else 22)
	_rect(get_node("Panel/Header/ShowAll"), all_left, 0, all_width, header)
	_rect(get_node("Panel/Header/Morning"), width-pad*2-44-morning_width, 0, morning_width, header)
	_rect(get_node("Panel/Header/Close"), width-pad*2-44, 0, 44, header)
	_rect(get_node("Panel/Header/Rule"), 0, header-1, width-pad*2, 1)
	_rect(_list, pad, top+header, width-pad*2, body)
	_rect(_more, pad, top+header, width-pad*2, body)
	_rect(get_node("Panel/Empty"), pad+4, top+header, width-pad*2-8, body)
	_rect(get_node("Panel/Detail"), pad+4, top+header+8, width-pad*2-8, body-16)
	_rect(get_node("Panel/Footer"), pad, top+header+body, width-pad*2, 44)
	if _category == "More":
		for category in ["Features", "Companions", "Recovery"]:
			var button: Button = get_node("Panel/More/" + category)
			_layout_category(button, button.size.x, 68)

func _style() -> void:
	get_node("Bar/Identity/Name").add_theme_color_override("font_color", GOLD)
	get_node("Bar/Identity/Class").add_theme_color_override("font_color", TOKENS.COLOR_CONTENT_MUTED)
	get_node("Panel/Header/Title").add_theme_color_override("font_color", GOLD)
	get_node("Panel/Empty/Title").add_theme_color_override("font_color", TOKENS.COLOR_CONTENT_MUTED)
	get_node("Panel/Empty/Sheet").add_theme_color_override("font_color", TOKENS.COLOR_ACCENT)
	get_node("Panel/Empty/Sheet").add_theme_font_size_override("font_size", 13)
	get_node("Panel/Empty/Title").add_theme_font_size_override("font_size", 13 if _phone else 14)
	get_node("Panel/Header/Close").add_theme_font_size_override("font_size", 26)
	get_node("Panel/Header/ShowAll").add_theme_font_size_override("font_size", 12 if _phone else 13)
	get_node("Panel/Header/Morning").add_theme_font_size_override("font_size", 12 if _phone else 13)
	get_node("Panel/Header/Morning").add_theme_color_override("font_color", TOKENS.COLOR_CONTENT_MUTED)
	get_node("Panel/Detail").add_theme_font_size_override("font_size", 13 if _phone else 16)
	get_node("Bar/Dice/Title").add_theme_font_size_override("font_size", 13)
	get_node("Bar/Dice/Title").add_theme_color_override("font_color", Color(0.94117647058823528, 0.85098039215686272, 0.55686274509803924, 1.0))
	var portrait := StyleBoxFlat.new()
	portrait.bg_color = TOKENS.COLOR_SURFACE_SUNKEN
	portrait.border_color = TOKENS.COLOR_EDGE
	portrait.set_border_width_all(1)
	portrait.set_corner_radius_all(3)
	portrait.content_margin_left = 2
	portrait.content_margin_right = 2
	portrait.content_margin_top = 2
	portrait.content_margin_bottom = 2
	get_node("Bar/Identity/PortraitFrame").add_theme_stylebox_override("panel", portrait)
	var track := StyleBoxFlat.new()
	track.bg_color = TOKENS.COLOR_SURFACE_SUNKEN
	track.border_color = TOKENS.COLOR_EDGE
	track.set_border_width_all(1)
	track.set_corner_radius_all(3)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = TOKENS.COLOR_SUCCESS
	fill.set_corner_radius_all(2)
	get_node("Bar/Identity/HpTrack").add_theme_stylebox_override("fill", fill)
	for category in BUTTONS:
		var button: Button = get_node("Bar/Categories/" + category)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0)
		normal.border_color = TOKENS.COLOR_EDGE
		normal.set_border_width_all(0 if _phone else 1)
		normal.set_corner_radius_all(3 if _phone else 5)
		button.add_theme_stylebox_override("normal", normal)
		var active: StyleBoxFlat = normal.duplicate()
		active.bg_color = TOKENS.COLOR_SURFACE_RAISED
		active.border_color = GOLD
		if _phone:
			active.border_width_bottom = 2
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_stylebox_override("hover_pressed", active)
