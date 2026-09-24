extends VBoxContainer
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const RULES = preload(ROOT + "logic/special_rules.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const ACTION = preload(ROOT + "logic/special_action.gd")
const SHIELD_SCENE = preload(ROOT + "ui/shield_dialog.tscn")
const SHIELD_SCRIPT = preload(ROOT + "ui/shield_dialog.gd")
const BACKDROP = preload(ROOT + "ui/shield_backdrop.tscn")
var _shield: SHIELD_SCRIPT
var _backdrop: CanvasLayer
const CHOICE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/special_choice.tscn")
const TARGETS = preload(ROOT + "ui/attack_targets.gd")
signal action_created(action: ACTION)
signal navigate_requested(route: String, item: String)
signal workflow_changed(route: String, title: String, can_submit: bool, busy: bool)
var _sdk: SDK
var _actor: SDK.Actor
var _item := ""
var _rule: Dictionary = {}
var _entry: Dictionary = {}
var _action: ACTION
var _source_rook: SDK.RookId
var _update_pending := false
var _targets_pending := false
var _reading_targets := false
var _scroll_options: Array = []
var _first_scroll := ""
var _second_scroll := ""
var _ability := ""

func _ready() -> void:
	resized.connect(_layout)
	for ability in ["Agility", "Presence", "Strength", "Toughness"]:
		var choice := CHOICE.instantiate() as Button
		get_node(^"Options/Ability/Choices").add_child(choice)
		choice.text = ability
		choice.pressed.connect(_choose_ability.bind(ability))
	get_node(^"Columns/Recipient/Content/Change").pressed.connect(_choose_targets)
	get_node(^"Columns/Recipient/Content/Self").pressed.connect(_self_changed)

func configure(actor: SDK.Actor, facade: SDK, item: String) -> void:
	_actor = actor
	_sdk = facade
	_item = item
	_entry = RULES.new().owned(actor.data, item)
	_rule = RULES.new().definition(str(_entry.get("source_item_id", "")))
	if not _sdk.targeting.changed.is_connected(_targets_changed):
		_sdk.targeting.changed.connect(_targets_changed)
	if not _sdk.world_changed.is_connected(_world_changed):
		_sdk.world_changed.connect(_world_changed)
	if _source_rook == null:
		_source_rook = _sdk.rooks.selected()
	_targets_pending = true
	_render()

func _render() -> void:
	var data: Dictionary = _actor.data
	var state := _action.state if _action != null else "ready"
	var editing := state in ["ready", "error"]
	var title := str(_entry.get("name", "Use item"))
	get_node(^"Columns/Item/Content/Name").visible = false
	get_node(^"Columns/Item/Content/Rules").text = str(_entry.get("rules", ""))
	if _rule.get("blade", false):
		get_node(^"Columns/Item/Content/Rules").text += " Check treachery when the table confirms continual disappointment; choose the possible victim before rolling. The source leaves check frequency and victim selection to the table."
	var default_uses: int = _rule.get("uses", -1)
	var uses: int = _entry.get("uses", default_uses)
	if _entry.has("dose_pool"):
		var actor_data: Dictionary = _actor.data
		var items: Array = actor_data.get("inventory", [])
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("source_item_id", "")) == str(_entry.dose_pool):
				uses = item.get("uses", 0)
	var reach: int = _rule.get("range_feet", 0)
	get_node(^"Columns/Item/Content/Uses").text = (str(uses) + " uses remaining · " if _entry.has("uses") or _rule.has("uses") or _entry.has("dose_pool") else "") + ("Self" if reach == 0 else "%d ft" % reach)
	get_node(^"Columns/Recipient/Content/Self").visible = reach > 0 and not _rule.get("book", false)
	get_node(^"Columns/Recipient/Content/Self").disabled = not editing
	get_node(^"Columns/Recipient/Content/Change").visible = reach > 0
	get_node(^"Columns/Recipient/Content/Change").disabled = not editing
	if reach == 0 or get_node(^"Columns/Recipient/Content/Self").button_pressed:
		get_node(^"Columns/Recipient/Content/Copy").text = "%s\n%s / %s HP" % [str(data.get("name", "Character")), str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
	get_node(^"Options").visible = editing
	get_node(^"Options/Ability").visible = _rule.get("ability_choice", false) or _rule.get("book", false)
	get_node(^"Options/NewFight").visible = _rule.get("gob", false)
	get_node(^"Options/Morale").visible = _rule.get("morale", false)
	get_node(^"Columns/Recipient/Content/Change").disabled = not editing and state != "witnesses"
	get_node(^"Columns/Recipient/Content/Change").text = "Choose witnesses" if state == "witnesses" else "Change recipient"
	get_node(^"Columns/Recipient/Content/Self").visible = reach > 0 and not _rule.get("book", false) and state != "witnesses"
	get_node(^"Scrolls").visible = state == "scrolls"
	if state == "scrolls" and _scroll_options.is_empty():
		_scroll_options = SCROLLS.TABLES.get(str(_action.snapshot.get("family", "")), [])
		for index in range(2):
			var list := get_node(^"Scrolls/First" if index == 0 else ^"Scrolls/Second")
			for raw in _scroll_options:
				var scroll: Dictionary = raw
				var row := CHOICE.instantiate() as Button
				list.add_child(row)
				row.text = str(scroll.name)
				row.pressed.connect(_choose_scroll.bind(index, str(scroll.source_item_id)))
		get_node(^"Scrolls/Second").visible = int(_action.snapshot.get("count", 0)) == 2
	if state == "shield":
		if _shield == null:
			var backdrop := BACKDROP.instantiate()
			add_child(backdrop)
			_backdrop = backdrop
			var dialog := SHIELD_SCENE.instantiate()
			add_child(dialog)
			_shield = dialog
			_shield.choice_requested.connect(_choose_shield)
			_shield.cancelled.connect(close_action)
		_backdrop.visible = true
		_shield.present(_action.snapshot)
	elif _shield != null:
		_shield.dismiss()
		_backdrop.visible = false
	var outcome := _action.message if _action != null else ""
	get_node(^"Outcome").text = outcome
	get_node(^"Outcome").visible = not outcome.is_empty()
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"
	workflow_changed.emit("use-item", title, state in ["resolved", "ended", "scrolls", "witnesses"] or (editing and not _rule.is_empty() and _actor.access_level == "Owner"), state in ["pending", "shield"])
	_layout()

func submit() -> void:
	if _action != null and _action.state in ["resolved", "ended"]:
		navigate_requested.emit("character", "")
		return
	if _action != null and _action.state == "scrolls":
		var ids: Array[String] = []
		for index in range(int(_action.snapshot.get("count", 0))):
			ids.append(_first_scroll if index == 0 else _second_scroll)
		await _action.choose_scrolls(ids)
		return
	if _action != null and _action.state == "witnesses":
		await _action.confirm_witnesses()
		return
	if _action != null and _action.pending:
		return
	if _action != null:
		_action.retire()
	_action = ACTION.new(_sdk)
	action_created.emit(_action)
	_action.changed.connect(_world_changed)
	await _action.start({"source": _actor.id.value, "rook": _source_rook.value if _source_rook != null else "", "item": _item, "self": get_node(^"Columns/Recipient/Content/Self").button_pressed and not _rule.get("book", false), "ability": _ability, "new_fight": get_node(^"Options/NewFight").button_pressed, "presence_sign": -1 if get_node(^"Options/Morale/Subtract").button_pressed else 1, "morale": int(get_node(^"Options/Morale/Value").value), "eligible": get_node(^"Options/Eligible").button_pressed})

func primary_text() -> String:
	var state := _action.state if _action != null else "ready"
	if state in ["resolved", "ended"]:
		return "Done"
	if state == "witnesses":
		return "Confirm witnesses"
	if state == "scrolls":
		return "Choose scrolls"
	return "Waiting…" if state in ["pending", "shield"] else "Use item"

func _world_changed() -> void:
	_update_pending = true

func _process(_delta: float) -> void:
	if _update_pending:
		_update_pending = false
		var latest := _sdk.actors.read(_actor.id)
		if latest.ok:
			_actor = latest.actor
			_entry = RULES.new().owned(_actor.data, _item)
		_render()
	if _targets_pending and not _reading_targets and not get_node(^"Columns/Recipient/Content/Self").button_pressed:
		_targets_pending = false
		_reading_targets = true
		var reach: float = _rule.get("range_feet", 0)
		var summary := await TARGETS.new().describe(_sdk, _source_rook, reach)
		_reading_targets = false
		if is_inside_tree():
			get_node(^"Columns/Recipient/Content/Copy").text = summary

func _targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_targets_pending = true

func _self_changed() -> void:
	_targets_pending = true
	_render()

func _choose_targets() -> void:
	get_node(^"Columns/Recipient/Content/Self").button_pressed = false
	var result := _sdk.targeting.choose()
	if not result.ok:
		get_node(^"Outcome").text = result.message
		get_node(^"Outcome").visible = true

func close_action() -> void:
	if _shield != null:
		_shield.dismiss()
		_backdrop.visible = false
	if _action != null:
		_action.cancel()

func _exit_tree() -> void:
	close_action()

func _layout() -> void:
	get_node(^"Columns").vertical = size.x < 600

func _choose_ability(ability: String) -> void:
	_ability = ability
	for choice in get_node(^"Options/Ability/Choices").get_children():
		var button := choice as Button
		button.button_pressed = button.text == ability

func _choose_scroll(index: int, id: String) -> void:
	if index == 0:
		_first_scroll = id
	else:
		_second_scroll = id
	var list := get_node(^"Scrolls/First" if index == 0 else ^"Scrolls/Second")
	for number in range(_scroll_options.size()):
		var scroll: Dictionary = _scroll_options[number]
		(list.get_child(number) as Button).button_pressed = str(scroll.source_item_id) == id

func _choose_shield(choice: String) -> void:
	await _action.choose_shield(choice)
