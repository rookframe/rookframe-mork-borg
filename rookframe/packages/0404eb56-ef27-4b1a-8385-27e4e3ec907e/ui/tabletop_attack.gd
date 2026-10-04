extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## A docked native action; no selection observer can replace its Actor or source.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SOURCES = preload(ROOT + "logic/attack_sources.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const CREATURE_ITEMS = preload(ROOT + "logic/creature_actions.gd")
const ACTION = preload(ROOT + "logic/melee_action.gd")
const COMPANION_ACTION = preload(ROOT + "logic/companion_action.gd")
const DEFENCE_FLOW = preload(ROOT + "ui/creature_defence_flow.gd")
const VIEW = preload(ROOT + "ui/melee_attack.gd")
const SOURCE_ROOKS = preload(ROOT + "logic/source_rooks.gd")
const TARGETS = preload(ROOT + "ui/attack_targets.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const FAVORITES = preload(ROOT + "logic/actor_favorites.gd")
var _actor: SDK.ActorId
var _task: Dictionary = {}
var _item: Dictionary = {}
var _action: ACTION
var _options := {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}
var _weapons: Array[Dictionary] = []
var _rooks: Array[SDK.RookId] = []
var _rook: SDK.RookId
var _refreshing := false
var _refresh_pending := false
var _closed := false
var _prepared := false
var _target_summary := ""
var _started_data: Dictionary = {}
var _started_item: Dictionary = {}
var _defending := false
@onready var _view: VIEW = get_node("Margin/Content/Scroll/Body/Attack")
@onready var _defence: DEFENCE_FLOW = get_node("Margin/Content/Scroll/Body/Defence")
@onready var _start_button: Button = get_node("Margin/Content/Actions/Start")

func ready() -> void:
	if sdk == null:
		return
	var locale := I18N.new()
	locale.bind(sdk)
	_view.localize(locale)
	get_node("Margin/Content/Scroll/Body/Weapon/Title").text = sdk.translations.text("Coward’s jab · choose a light one-handed weapon")
	get_node("Margin/Content/Scroll/Body/Improvised/Object").placeholder_text = sdk.translations.text("Improvised object")
	var mode: OptionButton = get_node("Margin/Content/Scroll/Body/Improvised/Mode")
	mode.clear()
	mode.add_item(sdk.translations.text("Melee · Strength · 5 ft"))
	mode.add_item(sdk.translations.text("Ranged · Presence · 30 ft"))
	_defence.localize(locale)
	_defence.changed.connect(_defence_changed)
	_defence.resolved.connect(_changed)
	_defence.access_lost.connect(_close)
	_view.targets_requested.connect(_choose_targets)
	get_node("Margin/Content/Actions/Close").pressed.connect(_close)
	_start_button.pressed.connect(_start)
	get_node("Margin/Content/Scroll/Body/Weapon/Choice").item_selected.connect(_weapon_selected)
	get_node("Margin/Content/Scroll/Body/Source/Choice").item_selected.connect(_rook_selected)
	get_node("Margin/Content/Scroll/Body/Improvised/Mode").item_selected.connect(_mode_selected)
	closed.connect(_cancel)
	sdk.world_changed.connect(_changed)
	sdk.targeting.changed.connect(_targets_changed)

func opened_task(actor: SDK.ActorId, task: Dictionary) -> void:
	# Retained windows cannot replace an already opened action silently.
	if _actor != null and not _closed:
		return
	_actor = actor
	_task = task.duplicate(true)
	_closed = false
	_prepared = false
	_started_data = {}
	_started_item = {}
	_defending = false
	_target_summary = ""
	get_node("Margin/Content/Scroll/Body/Improvised/Object").text = ""
	get_node("Margin/Content/Scroll/Body/Improvised/Mode").select(0)
	_options = {"difficulty": 0, "modifier": 0, "fumble": "break", "piercing": false}
	_options["mode"] = str(task.get("mode", "attack"))
	_options["entry"] = str(task.get("entry", ""))
	_options["improvised_mode"] = "melee"
	_options["object"] = ""
	_options["tabletop"] = true
	_resolve_rooks()
	_refresh_pending = true

func _process(_delta: float) -> void:
	if _refresh_pending and not _refreshing and not _closed:
		_refresh_pending = false
		_refresh()

func _inventory(actor: SDK.Actor) -> Array:
	return CREATURE_ITEMS.new(sdk, actor.id).inventory(actor.data) if str(actor.data.get("schema", "")) == "mork-borg-adversary/v1" else ITEMS.new(sdk, actor.id).inventory(actor.data)

func _refresh() -> void:
	if _actor == null or _closed:
		return
	_refreshing = true
	var current := sdk.actors.read(_actor)
	if not current.ok or current.actor.access_level != "Owner":
		_close()
		_refreshing = false
		return
	if _prepared and (_action == null or _action.state == "error"):
		var edited: Dictionary = _view.options()
		if not edited.is_empty():
			_capture_options(edited)
	if _action != null:
		await _action.refresh()
		if _closed:
			_refreshing = false
			return
	var items := _inventory(current.actor)
	var data: Dictionary = current.actor.data.duplicate(true)
	data["inventory"] = items
	if str(_task.get("mode", "")) == "jab" and (_action == null or _action.state == "error"):
		_weapons = SOURCES.new().jab_weapons(items)
		var choice: OptionButton = get_node("Margin/Content/Scroll/Body/Weapon/Choice")
		choice.clear()
		choice.add_item(sdk.translations.text("Choose a weapon"))
		for index in range(_weapons.size()):
			var weapon: Dictionary = _weapons[index]
			choice.add_item(str(weapon.name))
			if str(weapon.inventory_id) == str(_task.get("item", "")):
				choice.select(index + 1)
	get_node("Margin/Content/Scroll/Body/Weapon").visible = str(_task.get("mode", "")) == "jab" and (_action == null or _action.state == "error")
	_item = SOURCES.new().intrinsic(data, str(_task.get("item", "")), _options)
	if _item.is_empty():
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("inventory_id", "")) == str(_task.get("item", "")):
				_item = item
	var improvised := str(_task.get("item", "")) == "intrinsic:improvised"
	var state := _action.state if _action != null else "ready"
	var editable := _action == null or state == "error"
	get_node("Margin/Content/Scroll/Body/Improvised").visible = improvised and editable
	get_node("Margin/Content/Scroll/Body/Source").visible = editable and _rooks.size() > 1
	if not editable and not _started_data.is_empty():
		data = _started_data
		_item = _started_item
	var display_item := _item.duplicate(true)
	if not display_item.is_empty():
		display_item["literal_name"] = FAVORITES.new().uses_literal_name(_item, data)
	if str(_task.get("mode", "")) == "jab" and not display_item.is_empty():
		display_item["attack_ability"] = "Agility"
		display_item["damage"] = str(display_item.get("damage", "")) + "+3"
	var message := _action.message if _action != null else ""
	_view.configure(data, display_item, _options, state, message)
	_view.get_node("Outcome").visible = not message.is_empty()
	if not editable:
		_view.get_node("Rules").visible = false
	if _item.get("natural", false):
		var source_name := str(_item.get("name", "Attack"))
		var named_object := str(_item.get("source_item_id", "")) == "improvised" and not str(_options.get("object", "")).strip_edges().is_empty()
		var display_name := source_name if FAVORITES.new().uses_literal_name(_item, data) or named_object else sdk.translations.text(source_name)
		_view.get_node("Context").text = sdk.translations.text("%s · %s") % [str(data.get("name", "Actor")), display_name]
	_view.get_node("SourceRules").text = sdk.translations.text(str(_item.get("rules", "")))
	_view.get_node("SourceRules").visible = not str(_item.get("rules", "")).is_empty()
	_view.get_node("Target/Change").disabled = not editable
	_prepared = true
	if str(_task.get("mode", "")) == "jab":
		_view.get_node("Rules/Jab").set_pressed_no_signal(true)
		_view.get_node("Rules/Jab").disabled = true
	_start_button.visible = _action == null or state == "error"
	_start_button.disabled = _item.is_empty() or not SOURCES.new().usable(_item, str(data.get("schema", "")) == "mork-borg-adversary/v1")
	get_node("Margin/Content/Actions/Close").text = sdk.translations.text("Cancel" if _action == null or _action.pending else "Done")
	_present_defence()
	_present_owners()
	var snapshot := await sdk.targeting.snapshot()
	if not _closed and editable:
		var targeted: bool = snapshot.ok and not snapshot.snapshot.rooks.is_empty()
		_target_summary = await TARGETS.new().describe(sdk, _rook, float(_item.get("range_feet", 0))) if targeted else sdk.translations.text("No target · resolve at the table")
		_view.set_targets(_target_summary)
		_view.get_node("Rules/Hint").text = sdk.translations.text("Blank difficulty uses the Creature’s printed rule. Choose overrides with the table. Distance uses committed Rook centers." if targeted else "Attack and damage are rolled in sequence. Resolve the results at the table.")
	_refreshing = false

func _resolve_rooks() -> void:
	var resolver := SOURCE_ROOKS.new()
	_rooks = resolver.candidates(sdk, _actor)
	var chosen := sdk.rooks.selected()
	_rook = resolver.resolve(_rooks, chosen.value if chosen != null else "")
	var choice: OptionButton = get_node("Margin/Content/Scroll/Body/Source/Choice")
	choice.clear()
	choice.add_item(sdk.translations.text("Choose the source Rook"))
	for index in range(_rooks.size()):
		choice.add_item(sdk.translations.text("Rook %d") % (index + 1))
		if _rook != null and _rook.value == _rooks[index].value:
			choice.select(index + 1)

func _start() -> void:
	if _defending:
		await _defence.roll()
		return
	if _closed or (_action != null and _action.pending):
		return
	var options: Dictionary = _view.options()
	if options.is_empty():
		return
	options["tabletop"] = true
	options["entry"] = str(_task.get("entry", ""))
	options["object"] = get_node("Margin/Content/Scroll/Body/Improvised/Object").text
	options["improvised_mode"] = str(_options.get("improvised_mode", "melee"))
	_options = options
	var input := options.duplicate(true)
	input["source"] = _actor.value
	input["rook"] = _rook.value if _rook != null else ""
	input["item"] = str(_task.get("item", ""))
	if _task.get("companion", false):
		input["character"] = str(_task.get("character", ""))
		input["owner"] = str(_task.get("owner", ""))
	if _action != null:
		await _action.retire()
	if _closed:
		return
	var source := sdk.actors.read(_actor)
	if not source.ok or source.actor.access_level != "Owner":
		return
	_started_data = source.actor.data.duplicate(true)
	_started_data["inventory"] = _inventory(source.actor)
	_started_item = _item.duplicate(true)
	var intrinsic := SOURCES.new().intrinsic(_started_data, str(_task.get("item", "")), options)
	if not intrinsic.is_empty():
		_started_item = intrinsic
	var action: ACTION = COMPANION_ACTION.new(sdk) if _task.get("companion", false) else ACTION.new(sdk)
	add_child(action)
	_action = action
	action.changed.connect(_changed)
	await action.start(input)
	_refresh_pending = true

func _weapon_selected(index: int) -> void:
	if index > 0 and index <= _weapons.size():
		_task["item"] = str(_weapons[index - 1].inventory_id)
		_refresh_pending = true

func _rook_selected(index: int) -> void:
	_rook = _rooks[index - 1] if index > 0 and index <= _rooks.size() else null
	_refresh_pending = true

func _mode_selected(index: int) -> void:
	_options["improvised_mode"] = "ranged" if index == 1 else "melee"
	_refresh_pending = true

func _choose_targets() -> void:
	if _action != null and _action.state != "error":
		return
	var options: Dictionary = _view.options()
	if not options.is_empty():
		_capture_options(options)
	sdk.targeting.choose()

func _targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_refresh_pending = true

func _changed() -> void:
	_refresh_pending = true

func _close() -> void:
	_cancel()
	sdk.windows.close(load(ROOT + "ui/tabletop_attack_surface.tres"))

func _cancel() -> void:
	_closed = true
	_actor = null
	_defending = false
	if _defence != null:
		_defence.close()
	if _action != null:
		_action.retire()
		_action = null

func _exit_tree() -> void:
	_cancel()


func _capture_options(options: Dictionary) -> void:
	for key in ["mode", "eligible", "small_medium", "faithless_human", "ammunition", "difficulty", "modifier", "fumble", "piercing"]:
		if options.has(str(key)):
			_options[str(key)] = options.get(str(key))

func _present_defence() -> void:
	var outcome: Dictionary = _action.snapshot if _action != null else {}
	_defending = _action != null and outcome.has("defender") and str(outcome.get("defender", "")) == sdk.context().participant_id and str(outcome.get("state", "")) != "error"
	_view.visible = not _defending
	_defence.visible = _defending
	if _defending:
		_defence.present(sdk, outcome)
		_start_button.visible = _action.state == "ready"
		_start_button.disabled = false
		_start_button.text = sdk.translations.text("Roll damage" if outcome.get("automatic_hit", false) else "Roll defence")
	elif _action != null and outcome.has("defender") and _action.state in ["ready", "shield"]:
		_view.get_node("Outcome").visible = true
		_view.get_node("Outcome").text = sdk.translations.text("Waiting for the defending Player.")
	else:
		_start_button.text = sdk.translations.text("Roll attack")

func _defence_changed(state: String, can_roll: bool, automatic_hit: bool) -> void:
	if not _defending:
		return
	_start_button.visible = can_roll
	_start_button.text = sdk.translations.text("Roll damage" if automatic_hit else "Roll defence")
	get_node("Margin/Content/Actions/Close").text = sdk.translations.text("Done" if state in ["resolved", "ended"] else "Cancel")

func _present_owners() -> void:
	var owners: VBoxContainer = get_node("Margin/Content/Scroll/Body/Owners")
	for child in owners.get_children():
		owners.remove_child(child)
		child.queue_free()
	var choices: Array = _action.snapshot.get("owners", []) if _action != null else []
	owners.visible = not choices.is_empty()
	for raw in choices:
		var choice: Dictionary = raw
		var button := Button.new()
		button.text = str(choice.get("name", "Player"))
		button.custom_minimum_size = Vector2(0, 44)
		button.theme_type_variation = "RookframeSecondaryButton"
		button.pressed.connect(_owner_selected.bind(str(choice.id)))
		owners.add_child(button)

func _owner_selected(participant: String) -> void:
	_task["owner"] = participant
	await _start()
